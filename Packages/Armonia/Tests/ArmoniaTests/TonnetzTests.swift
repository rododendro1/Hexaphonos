import XCTest
@testable import Armonia
@testable import ArmoniaNucleo
@testable import ArmoniaTeoria
@testable import ArmoniaRepresentaciones
@testable import ArmoniaPartitura

final class TonnetzTests: XCTestCase {
    private func punto(_ a: Int, _ b: Int) -> PuntoDeLaRed { PuntoDeLaRed(quintas: a, terceras: b) }

    func testPuntos() {
        XCTAssertEqual(punto(0, 1).nota, .mi)
        XCTAssertEqual(punto(4, 0).nota, .mi)            // el mismo nombre, otro punto
        XCTAssertEqual(punto(2, 1).nota, Nota(.fa, .sostenido))
        XCTAssertEqual(punto(1, -1).nota, Nota(.mi, .bemol))
        XCTAssertEqual(punto(0, 1).claseDeAltura, 4)
        XCTAssertEqual(punto(3, 0).claseDeAltura, 9)
        XCTAssertEqual(punto(4, -1).claseDeAltura, 0)     // un ciclo del toro de doce notas
        XCTAssertEqual(Set(punto(0, 0).vecinos.map(\.nota)),
                       [.sol, .fa, .mi, Nota(.la, .bemol), Nota(.mi, .bemol), .la])
        XCTAssertEqual(punto(0, 0).distancia(hasta: punto(1, -1)), 1)   // tercera menor
        XCTAssertEqual(punto(0, 0).distancia(hasta: punto(1, 1)), 2)
        XCTAssertEqual(punto(0, 0).distancia(hasta: punto(3, -2)), 3)
        XCTAssertEqual(punto(0, 0).distancia(hasta: punto(-2, -1)), 3)
    }

    func testAcordes() {
        let mayor = Tonnetz(Acorde("Do"))
        XCTAssertEqual(mayor.puntos, [punto(0, 0), punto(0, 1), punto(1, 0)])
        XCTAssertEqual(mayor.triadas.map(\.acorde), [Acorde("Do")])
        XCTAssertTrue(mayor.triadas[0].mayor)
        XCTAssertEqual(mayor.aristas.map(\.eje).sorted { "\($0)" < "\($1)" },
                       [.quintaJusta, .terceraMayor, .terceraMenor])
        let menor = Tonnetz(Acorde("Lam"))
        XCTAssertEqual(menor.triadas.map(\.acorde), [Acorde("Lam")])
        XCTAssertFalse(menor.triadas[0].mayor)
        // Una séptima mayor son dos triángulos: Do y Mim.
        XCTAssertEqual(Tonnetz(Acorde("Domaj7")).triadas.map(\.acorde), [Acorde("Do"), Acorde("Mim")])
        XCTAssertEqual(Tonnetz(Acorde("Sol7")).triadas.map(\.acorde), [Acorde("Sol")])
        XCTAssertTrue(Tonnetz(Acorde("Sol7")).esConexo)
        // La ortografía se conserva: un acorde de Sol♭ y otro de Fa♯ no comparten puntos.
        XCTAssertEqual(Tonnetz(Acorde("Solb")).triadas.map(\.acorde), [Acorde("Solb")])
        XCTAssertTrue(Set(Tonnetz(Acorde("Solb")).puntos).isDisjoint(with: Tonnetz(Acorde("Fa#")).puntos))
    }

    func testEscalas() {
        let diatonica = Tonnetz(Escala(.do))
        XCTAssertTrue(diatonica.esConexo)
        XCTAssertEqual(diatonica.notas, Escala(.do).notas)
        // Las seis tríadas de la escala menos la disminuida.
        XCTAssertEqual(Set(diatonica.triadas.map(\.acorde)), ["Do", "Rem", "Mim", "Fa", "Lam"])
        let todas = Set(diatonica.triadas.map(\.acorde)).union(Tonnetz([.sol, .si, .re]).triadas.map(\.acorde))
        XCTAssertEqual(todas.count, 6)
        // Tonos enteros: sin quintas ni terceras menores, solo dos líneas de terceras mayores.
        let tonos = Tonnetz(Escala(.do, .tonosEnteros))
        XCTAssertFalse(tonos.esConexo)
        XCTAssertTrue(tonos.triadas.isEmpty)
        XCTAssertEqual(Set(tonos.aristas.map(\.eje)), [.terceraMayor])
        // La aumentada encadena tríadas mayores y menores alternas.
        XCTAssertEqual(Tonnetz(Escala(.do, .aumentada)).triadas.count, 4)
        // Con las notas repetidas, cada una una vez.
        XCTAssertEqual(Tonnetz([.do, .mi, .do, .sol]).puntos.count, 3)
        XCTAssertTrue(Tonnetz([]).puntos.isEmpty)
    }

    /// La colocación es la más compacta: nunca peor que la voraz, y mejor en muchas escalas.
    func testColocacionOptima() {
        func suma(_ p: [PuntoDeLaRed]) -> Int {
            p.indices.reduce(0) { s, i in s + p.indices.filter { $0 > i }.reduce(0) { $0 + p[i].distancia(hasta: p[$1]) } }
        }
        let candidatos: (Int, ClosedRange<Int>) -> [PuntoDeLaRed] = { pasos, filas in
            filas.map { PuntoDeLaRed(quintas: pasos - 4 * $0, terceras: $0) }
        }
        var mejoras = 0
        for tipo in TipoDeEscala.todos {
            let tonnetz = Tonnetz(Escala(.do, tipo))
            let voraz = Tonnetz.colocarVoraz(tonnetz.notas.map(\.pasosDeQuinta), candidatos: candidatos)
            let optima = (Tonnetz.grupos(tonnetz.puntos), suma(tonnetz.puntos))
            XCTAssertLessThanOrEqual(optima.0, Tonnetz.grupos(voraz), tipo.nombre)
            if optima.0 == Tonnetz.grupos(voraz) { XCTAssertLessThanOrEqual(optima.1, suma(voraz), tipo.nombre) }
            if optima < (Tonnetz.grupos(voraz), suma(voraz)) { mejoras += 1 }
            XCTAssertEqual(tonnetz.notas, Escala(.do, tipo).notas.reduce(into: [Nota]()) { if !$0.contains($1) { $0.append($1) } })
        }
        XCTAssertGreaterThanOrEqual(mejoras, 20)
        // La egipcia (Do Re Fa Sol Si♭) es una franja de quintas con dos terceras: suma 15, no 17.
        XCTAssertEqual(suma(Tonnetz(Escala(.do, .egipcia)).puntos), 15)
        // La menor melódica, compacta y conexa.
        let melodica = Tonnetz(Escala(.do, .menorMelodica))
        XCTAssertTrue(melodica.esConexo)
        XCTAssertEqual(suma(melodica.puntos), 36)
    }

    func testClasesDeAltura() {
        let triada = Tonnetz(ConjuntoDeClases([0, 4, 7]))
        XCTAssertFalse(triada.tieneOrtografia)
        XCTAssertEqual(triada.puntos.map(\.claseDeAltura), [0, 4, 7])
        XCTAssertEqual(triada.triadas.count, 1)
        // Sin ortografía, el acorde de séptima disminuida es una línea de terceras menores.
        let disminuido = Tonnetz(ConjuntoDeClases([0, 3, 6, 9]))
        XCTAssertTrue(disminuido.esConexo)
        XCTAssertEqual(Set(disminuido.aristas.map(\.eje)), [.terceraMenor])
        // Toda tríada mayor o menor, transportada, sigue siendo un triángulo.
        for n in 0..<12 {
            XCTAssertEqual(Tonnetz(ConjuntoDeClases([0, 4, 7]).transponer(n)).triadas.count, 1, "\(n)")
            XCTAssertEqual(Tonnetz(ConjuntoDeClases([0, 3, 7]).transponer(n)).triadas.count, 1, "\(n)")
        }
        XCTAssertEqual("\(triada)", "0 (0, 0) · 4 (0, 1) · 7 (1, 0)")
        XCTAssertEqual("\(Tonnetz(Acorde("Do")))", "Do (0, 0) · Mi (0, 1) · Sol (1, 0)")
    }

    /// Cualquier conjunto de notas se coloca conexo si sus notas, sin ortografía, lo permiten:
    /// toda tríada consonante al azar sale como un triángulo.
    func testTriadasAlAzar() {
        var azar = GeneradorConSemilla(semilla: 2026)
        for _ in 0..<200 {
            let fundamental = Nota(pasosDeQuinta: Int.random(in: -10...10, using: &azar))
            let acorde = Acorde(fundamental, Bool.random(using: &azar) ? .mayor : .menor)
            let tonnetz = Tonnetz(acorde)
            XCTAssertEqual(tonnetz.triadas.map(\.acorde), [acorde], acorde.cifrado)
            XCTAssertEqual(tonnetz.notas, acorde.notas)
        }
    }

    func testSVG() throws {
        for tonnetz in [Tonnetz(Escala(.re, .dorico)), Tonnetz(ConjuntoDeClases([0, 4, 7, 11])), Tonnetz([])] {
            let svg = tonnetz.svg()
            let raiz = try XCTUnwrap(ElementoXML.leer(svg))
            XCTAssertEqual(raiz.nombre, "svg")
            XCTAssertFalse(raiz.todos("circle").isEmpty)
        }
        let raiz = try XCTUnwrap(ElementoXML.leer(Tonnetz(Acorde("Do")).svg(margen: 1)))
        // Las tres notas marcadas, con sus nombres, y un triángulo.
        let marcadas = raiz.todos("text").filter { $0.atributos["font-weight"] == "bold" }.map(\.texto)
        XCTAssertEqual(Set(marcadas), ["Do", "Mi", "Sol"])
        XCTAssertEqual(raiz.todos("polygon").count, 1)
        XCTAssertEqual(raiz.todos("line").filter { $0.atributos["stroke-width"] == "3" }.count, 3)
        // En inglés, y con clases de altura, todas las repeticiones de cada clase.
        let ingles = try XCTUnwrap(ElementoXML.leer(Tonnetz(Acorde("Fa#")).svg(notacion: .ingles)))
        XCTAssertTrue(ingles.todos("text").contains { $0.texto == "F#" })
        let clases = try XCTUnwrap(ElementoXML.leer(Tonnetz(ConjuntoDeClases([0, 4, 7])).svg(margen: 3)))
        XCTAssertGreaterThan(clases.todos("text").filter { $0.atributos["font-weight"] == "bold" }.count, 3)
    }

    func testTransformaciones() {
        XCTAssertEqual(Acorde("Do").transformar(.p), Acorde("Dom"))
        XCTAssertEqual(Acorde("Do").transformar(.l), Acorde("Mim"))
        XCTAssertEqual(Acorde("Do").transformar(.r), Acorde("Lam"))
        XCTAssertEqual(Acorde("Lam").transformar(.l), Acorde("Fa"))
        XCTAssertEqual(Acorde("Lam").transformar(.r), Acorde("Do"))
        // La ortografía se conserva.
        XCTAssertEqual(Acorde("Mib").transformar(.r), Acorde("Dom"))
        XCTAssertEqual(Acorde("Do#m").transformar(.l), Acorde("La"))
        // Las compuestas.
        XCTAssertEqual(Acorde("Do").transformar(TransformacionNeorriemanniana.n), Acorde("Fam"))
        XCTAssertEqual(Acorde("Do").transformar(TransformacionNeorriemanniana.s), Acorde("Do#m"))
        XCTAssertEqual(Acorde("Do").transformar(TransformacionNeorriemanniana.h), Acorde("Sol#m"))
        XCTAssertEqual(Acorde("Do").transformar(leyendo: "P L R"), Acorde("Fam"))
        XCTAssertEqual(Acorde("Do").transformar(leyendo: "n"), Acorde("Fam"))
        XCTAssertNil(Acorde("Do").transformar(leyendo: "PX"))
        XCTAssertNil(Acorde("Do").transformar(leyendo: ""))
        // Solo tríadas mayores y menores; la inversión se ignora.
        XCTAssertNil(Acorde("Sol7").transformar(.p))
        XCTAssertNil(Acorde("Sidim").transformar(.r))
        XCTAssertEqual(Acorde("Do/Mi").transformar(.r), Acorde("Lam"))
        XCTAssertEqual(TransformacionNeorriemanniana.entre("Do", "Lam"), .r)
        XCTAssertNil(TransformacionNeorriemanniana.entre("Do", "Re"))
        XCTAssertEqual(TransformacionNeorriemanniana.l.nombre, "cambio de sensible")
        // Son involuciones, y cada una comparte un lado con la tríada: dos notas en común.
        var azar = GeneradorConSemilla(semilla: 7)
        for _ in 0..<100 {
            let acorde = Acorde(Nota(pasosDeQuinta: Int.random(in: -12...12, using: &azar)), Bool.random(using: &azar) ? .mayor : .menor)
            for t in TransformacionNeorriemanniana.allCases {
                let otro = acorde.transformar(t)!
                XCTAssertEqual(otro.transformar(t), acorde, "\(acorde) \(t)")
                XCTAssertEqual(Set(acorde.notas).intersection(otro.notas).count, 2, "\(acorde) \(t)")
                XCTAssertNotEqual(otro.tipo, acorde.tipo)
            }
        }
        // En el Tonnetz, cada transformación da un triángulo vecino.
        let triada = Tonnetz.Triada(Acorde("Do"))!
        for vecina in triada.vecinas {
            XCTAssertEqual(Set(triada.vertices).intersection(vecina.vertices).count, 2)
        }
    }

    func testCamino() {
        XCTAssertEqual(Tonnetz.camino(desde: "Do", hasta: "Do"), [])
        XCTAssertEqual(Tonnetz.camino(desde: "Do", hasta: "Lam"), [.r])
        XCTAssertEqual(Tonnetz.camino(desde: "Do", hasta: "Lab"), [.p, .l])
        XCTAssertEqual(Tonnetz.camino(desde: "Do", hasta: "Mibm"), [.p, .r, .p])
        XCTAssertEqual(Tonnetz.camino(desde: "Do", hasta: "Fa#"), [.r, .p, .r, .p])
        XCTAssertEqual(Tonnetz.camino(desde: "Do", hasta: "Fa"), [.r, .l])
        XCTAssertNil(Tonnetz.camino(desde: "Do", hasta: "Sol7"))
        // Con ortografía, La♭ y Sol♯ son destinos distintos; sin ella, el mismo.
        XCTAssertEqual(Tonnetz.camino(desde: "Do", hasta: "Lab")?.count, 2)
        XCTAssertGreaterThan(Tonnetz.camino(desde: "Do", hasta: "Sol#")!.count, 2)
        XCTAssertEqual(Tonnetz.camino(desde: "Do", hasta: "Sol#", enarmonico: true), [.p, .l])
        // Todo camino lleva a su destino, y ninguno entre las 24 tríadas pasa de 5 pasos sin ortografía.
        for n in 0..<12 {
            for mayor in [true, false] {
                let destino = Acorde(Nota(pasosDeQuinta: n - 5), mayor ? .mayor : .menor)
                let camino = Tonnetz.camino(desde: "Do", hasta: destino)!
                XCTAssertEqual(Acorde("Do").transformar(camino), destino)
                XCTAssertLessThanOrEqual(Tonnetz.camino(desde: "Do", hasta: destino, enarmonico: true)!.count, 5)
            }
        }
    }

    func testRecorrido() throws {
        // La progresión I–vi–IV: tres triángulos vecinos.
        let recorrido = try XCTUnwrap(Tonnetz(recorrido: ["Do", "Lam", "Fa"]))
        XCTAssertEqual(recorrido.recorrido.map(\.acorde), [Acorde("Do"), Acorde("Lam"), Acorde("Fa")])
        XCTAssertEqual(recorrido.notas, [.do, .mi, .sol, .la, .fa])
        for (uno, otro) in zip(recorrido.recorrido, recorrido.recorrido.dropFirst()) {
            XCTAssertEqual(Set(uno.vertices).intersection(otro.vertices).count, 2)
        }
        // La bomba de comas: Do–Lam–Rem–Sol–Do vuelve a un Do desplazado una coma sintónica.
        let bomba = try XCTUnwrap(Tonnetz(recorrido: ["Do", "Lam", "Rem", "Sol", "Do"]))
        XCTAssertNotEqual(bomba.recorrido.first, bomba.recorrido.last)
        XCTAssertEqual(bomba.recorrido.first?.acorde, bomba.recorrido.last?.acorde)
        XCTAssertNil(Tonnetz(recorrido: ["Do", "Sol7"]))
        XCTAssertTrue(Tonnetz(recorrido: [])!.puntos.isEmpty)
        // El camino más corto, como recorrido.
        let camino = try XCTUnwrap(Tonnetz(caminoDesde: "Do", hasta: "Mibm"))
        XCTAssertEqual(camino.recorrido.map(\.acorde), [Acorde("Do"), Acorde("Dom"), Acorde("Mib"), Acorde("Mibm")])
        XCTAssertNil(Tonnetz(caminoDesde: "Do", hasta: "Sol7"))
        // El dibujo: flechas y el pie.
        let raiz = try XCTUnwrap(ElementoXML.leer(recorrido.svg()))
        XCTAssertEqual(raiz.todos("line").filter { $0.atributos["marker-end"] != nil }.count, 2)
        XCTAssertTrue(raiz.todos("text").contains { $0.texto == "Do –R→ Lam –L→ Fa" })
        let ingles = try XCTUnwrap(ElementoXML.leer(camino.svg(notacion: .ingles)))
        XCTAssertTrue(ingles.todos("text").contains { $0.texto == "C –P→ Cm –R→ " + Acorde("Mib").cifrado(en: .ingles) + " –P→ " + Acorde("Mibm").cifrado(en: .ingles) })
        XCTAssertNil(try XCTUnwrap(ElementoXML.leer(Tonnetz(Acorde("Do")).svg())).todos("line").first { $0.atributos["marker-end"] != nil })
        // Ida y vuelta entre los mismos triángulos: flechas curvas que no se montan.
        let vaiven = try XCTUnwrap(ElementoXML.leer(Tonnetz(recorrido: ["Do", "Dom", "Do", "Dom"])!.svg()))
        let curvas = vaiven.todos("path").filter { $0.atributos["marker-end"] != nil }
        let rectas = vaiven.todos("line").filter { $0.atributos["marker-end"] != nil }
        XCTAssertEqual(curvas.count + rectas.count, 3)
        XCTAssertEqual(rectas.count, 1)
        XCTAssertEqual(Set(curvas.compactMap { $0.atributos["d"] }).count, 2)
        // Ida y vuelta, una vez cada una: dos curvas, sin recta en medio.
        let idaYVuelta = try XCTUnwrap(ElementoXML.leer(Tonnetz(recorrido: ["Do", "Lam", "Do"])!.svg()))
        XCTAssertEqual(idaYVuelta.todos("path").filter { $0.atributos["marker-end"] != nil }.count, 2)
        // Un recorrido sin vueltas, solo rectas.
        XCTAssertTrue(raiz.todos("path").filter { $0.atributos["marker-end"] != nil }.isEmpty)
    }

    func testTituloYLeyenda() throws {
        func leyenda(_ raiz: ElementoXML) -> [String] {
            raiz.todos("g").filter { $0.atributos["class"] == "leyenda" }.flatMap { $0.todos("text").map(\.texto) }
        }
        // El título: el acorde, la escala, las notas, el conjunto o el recorrido.
        for (tonnetz, titulo) in [(Tonnetz(Acorde("Domaj7")), "Domaj7"), (Tonnetz(Escala(.re, .dorico)), "Re dórico"),
                                  (Tonnetz([.do, .mi, .sol]), "Do · Mi · Sol"), (Tonnetz(ConjuntoDeClases([0, 4, 7])), "Conjunto [0, 4, 7]"),
                                  (Tonnetz(recorrido: ["Do", "Lam"])!, "Do –R→ Lam")] {
            let raiz = try XCTUnwrap(ElementoXML.leer(tonnetz.svg()))
            XCTAssertEqual(raiz.todos("title").first?.texto, titulo)
            XCTAssertTrue(raiz.todos("text").contains { $0.texto == titulo && $0.atributos["font-weight"] == "600" }, titulo)
        }
        XCTAssertEqual(try XCTUnwrap(ElementoXML.leer(Tonnetz(Acorde("Do")).svg(notacion: .ingles))).todos("title").first?.texto, "C")
        XCTAssertEqual(try XCTUnwrap(ElementoXML.leer(Tonnetz(Acorde("Do")).svg(titulo: "Tónica"))).todos("title").first?.texto, "Tónica")
        XCTAssertTrue(try XCTUnwrap(ElementoXML.leer(Tonnetz(Acorde("Do")).svg(titulo: ""))).todos("title").isEmpty)
        // La leyenda, solo con lo que aparece.
        XCTAssertEqual(leyenda(try XCTUnwrap(ElementoXML.leer(Tonnetz(Acorde("Domaj7")).svg()))),
                       ["nota", "quinta o tercera entre notas", "tríada mayor", "tríada menor"])
        XCTAssertEqual(leyenda(try XCTUnwrap(ElementoXML.leer(Tonnetz(Escala(.do, .tonosEnteros)).svg()))),
                       ["nota", "quinta o tercera entre notas"])
        XCTAssertEqual(leyenda(try XCTUnwrap(ElementoXML.leer(Tonnetz(recorrido: ["Do", "Lam"])!.svg()))).last,
                       "paso del recorrido (P, L, R)")
        XCTAssertEqual(leyenda(try XCTUnwrap(ElementoXML.leer(Tonnetz(ConjuntoDeClases([0])).svg()))), ["clase de altura (todas sus copias)"])
        XCTAssertEqual(leyenda(try XCTUnwrap(ElementoXML.leer(Tonnetz(Acorde("Do")).svg(notacion: .ingles)))),
                       ["note", "fifth or third between notes", "major triad"])
        XCTAssertTrue(leyenda(try XCTUnwrap(ElementoXML.leer(Tonnetz(Acorde("Do")).svg(leyenda: false)))).isEmpty)
        XCTAssertTrue(leyenda(try XCTUnwrap(ElementoXML.leer(Tonnetz([]).svg()))).isEmpty)
    }

    func testCiclos() {
        func cifrados(_ acorde: Acorde, _ ciclo: CicloNeorriemanniano) -> [String] {
            acorde.ciclo(ciclo)?.map(\.cifrado) ?? []
        }
        // Con la ortografía más sencilla: Mi y no Fa♭, Fa♯m y no Sol♭m (con Si♭♭).
        XCTAssertEqual(cifrados("Do", .hexatonico), ["Do", "Dom", "La♭", "La♭m", "Mi", "Mim", "Do"])
        XCTAssertEqual(cifrados("Do", .octatonico), ["Do", "Dom", "Mi♭", "Mi♭m", "Sol♭", "Fa♯m", "La", "Lam", "Do"])
        XCTAssertEqual(cifrados("Mim", .hexatonico), ["Mim", "Mi", "Sol♯m", "Sol♯", "Dom", "Do", "Mim"])
        let lr = cifrados("Do", .lr)
        XCTAssertEqual(lr.count, 25)
        XCTAssertEqual(Array(lr.prefix(5)), ["Do", "Mim", "Sol", "Sim", "Re"])
        XCTAssertEqual(Array(lr[10...16]), ["Si", "Re♯m", "Fa♯", "La♯m", "Do♯", "Fam", "La♭"])
        XCTAssertEqual(lr.last, "Do")
        // Las 24 tríadas, una vez cada una; y en cada ciclo, de una a otra por P, L o R.
        for ciclo in CicloNeorriemanniano.allCases {
            for n in -6...6 {
                for mayor in [true, false] {
                    let inicio = Acorde(Nota(pasosDeQuinta: n), mayor ? .mayor : .menor)
                    let acordes = inicio.ciclo(ciclo)!
                    XCTAssertEqual(acordes.count, ciclo.longitud + 1)
                    XCTAssertEqual(acordes.last, inicio)
                    let distintas = Set(acordes.dropLast().map { [$0.fundamental.claseDeAltura, $0.tipo == .mayor ? 1 : 0] })
                    XCTAssertEqual(distintas.count, ciclo.longitud)
                    for (i, (uno, otro)) in zip(acordes, acordes.dropFirst()).enumerated() {
                        let transformado = uno.transformar(ciclo.transformaciones[i % 2])!
                        XCTAssertEqual(Set(transformado.notas.map(\.claseDeAltura)), Set(otro.notas.map(\.claseDeAltura)))
                        // Sin dobles alteraciones (salvo en la de partida, que se respeta: Sol♭m).
                        if otro != inicio {
                            XCTAssertTrue(otro.notas.allSatisfy { abs($0.alteracion.semitonos) <= 1 }, "\(otro)")
                        }
                    }
                }
            }
        }
        XCTAssertNil(Acorde("Sol7").ciclo(.hexatonico))
        XCTAssertEqual(CicloNeorriemanniano(leyendo: "Hexatónico"), .hexatonico)
        XCTAssertEqual(CicloNeorriemanniano(leyendo: "octatonic cycle"), .octatonico)
        XCTAssertEqual(CicloNeorriemanniano(leyendo: "ciclo LR"), .lr)
        XCTAssertNil(CicloNeorriemanniano(leyendo: "pentatónico"))
    }

    func testDibujoDeCiclos() throws {
        let tonnetz = try XCTUnwrap(Tonnetz(ciclo: .hexatonico, desde: "Do"))
        // La banda, recta: siete triángulos y nueve puntos, el último Do otra vez.
        XCTAssertEqual(tonnetz.recorrido.count, 7)
        XCTAssertEqual(tonnetz.puntos.count, 9)
        XCTAssertEqual(tonnetz.recorrido.last?.fundamental, PuntoDeLaRed(quintas: 0, terceras: -3))
        XCTAssertEqual(tonnetz.notas.map(\.description), ["Do", "Mi", "Sol", "Mi♭", "La♭", "Do♭", "Mi", "Sol", "Do"])
        let svg = tonnetz.svg()
        XCTAssertTrue(svg.contains("Do –P→ Dom –L→ La♭ –P→ La♭m –L→ Mi –P→ Mim –L→ Do"))
        XCTAssertFalse(svg.contains("Fa♭"))
        XCTAssertFalse(svg.contains("𝄫") || svg.contains("♭♭") || svg.contains("Re♭♭"))
        XCTAssertTrue(tonnetz.svg(notacion: .ingles).contains("C –P→ Cm –L→ Ab"))
        XCTAssertEqual(Tonnetz(ciclo: .lr, desde: "Lam")?.recorrido.count, 25)
        XCTAssertNil(Tonnetz(ciclo: .octatonico, desde: "Do7"))
    }
}
