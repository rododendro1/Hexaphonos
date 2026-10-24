import XCTest
@testable import Armonia
@testable import ArmoniaNucleo
@testable import ArmoniaTeoria
@testable import ArmoniaRepresentaciones
@testable import ArmoniaPartitura

final class TablaArmonicaTests: XCTestCase {
    private func punto(_ a: Int, _ b: Int) -> PuntoDelTonnetz { PuntoDelTonnetz(quintas: a, terceras: b) }

    func testNotas() {
        let tabla = TablaArmonica(Acorde("Do"))
        XCTAssertEqual(tabla.colocacion, .notas)
        XCTAssertEqual(tabla.puntos, Tonnetz(Acorde("Do")).puntos)
        XCTAssertEqual(tabla.triadas.map(\.acorde), [Acorde("Do")])
        XCTAssertEqual("\(tabla)", "Do (0, 0) · Mi (0, 1) · Sol (1, 0)")
        XCTAssertTrue(TablaArmonica(Escala(.re, .dorico)).esConexo)
        XCTAssertEqual(TablaArmonica(ConjuntoDeClases([0, 3, 7])).colocacion, .clasesDeAltura)
        // La forma es la misma en todas las tonalidades: transportar es desplazar los hexágonos.
        let forma = { (tabla: TablaArmonica) -> [PuntoDelTonnetz] in
            tabla.puntos.map { self.punto($0.quintas - tabla.puntos[0].quintas, $0.terceras - tabla.puntos[0].terceras) }
        }
        for tonica in [Nota.re, Nota(.mi, .bemol), Nota(.fa, .sostenido), .si] {
            XCTAssertEqual(forma(TablaArmonica(Acorde(tonica, Acorde("Domaj7").tipo))), forma(TablaArmonica(Acorde("Domaj7"))), "\(tonica)")
        }
    }

    func testAlturas() {
        XCTAssertEqual(TablaArmonica.midi(de: punto(0, 0)), 60)
        XCTAssertEqual(TablaArmonica.midi(de: punto(1, 0)), 67)    // una quinta arriba
        XCTAssertEqual(TablaArmonica.midi(de: punto(0, 1)), 64)    // una tercera mayor arriba
        XCTAssertEqual(TablaArmonica.midi(de: punto(1, -1)), 63)   // una tercera menor arriba
        let abierta = TablaArmonica([Altura("Do3"), Altura("Sol3"), Altura("Mi4"), Altura("Si4")])
        XCTAssertEqual(abierta.colocacion, .alturas)
        XCTAssertEqual(abierta.puntos.map(TablaArmonica.midi), [48, 55, 64, 71])
        // Do4, Mi4 y Sol4 son una tríada; Do3, Mi4 y Sol4 no: en la tabla suenan las alturas.
        XCTAssertEqual(TablaArmonica([Altura("Do4"), Altura("Mi4"), Altura("Sol4")]).triadas.count, 1)
        XCTAssertEqual(TablaArmonica([Altura("Do3"), Altura("Mi4"), Altura("Sol4")]).triadas.count, 0)
        // Las enarmónicas comparten hexágono.
        XCTAssertEqual(TablaArmonica([Altura("Fa#4"), Altura("Solb4")]).puntos.count, 1)
        XCTAssertEqual("\(TablaArmonica([Altura("Do4"), Altura("Sol4")]))", "Do4 (0, 0) · Sol4 (1, 0)")
        // Cualquier altura se puede colocar.
        for midi in 21...108 {
            XCTAssertEqual(TablaArmonica([Altura(midi: midi)]).puntos.map(TablaArmonica.midi), [midi])
        }
    }

    func testSVG() throws {
        for tabla in [TablaArmonica(Escala(.re, .dorico)), TablaArmonica(ConjuntoDeClases([0, 4, 7])),
                      TablaArmonica([Altura("Do3"), Altura("Sol3"), Altura("Mi4")]), TablaArmonica([Nota]())] {
            let raiz = try XCTUnwrap(ElementoXML.leer(tabla.svg()))
            XCTAssertEqual(raiz.nombre, "svg")
            XCTAssertFalse(raiz.todos("polygon").isEmpty)
        }
        let raiz = try XCTUnwrap(ElementoXML.leer(TablaArmonica(Acorde("Domaj7")).svg(margen: 1)))
        let marcadas = raiz.todos("text").filter { $0.atributos["font-weight"] == "bold" }.map(\.texto)
        XCTAssertEqual(Set(marcadas), ["Do", "Mi", "Sol", "Si"])
        // Dos tríadas, Do y Mim: dos puntos, naranja y azul.
        XCTAssertEqual(raiz.todos("circle").map { $0.atributos["fill"] }, ["#f6b26b", "#8fb8e8"])
        // El contorno: cuatro hexágonos en rombo tienen 24 lados, menos 2 × 5 compartidos.
        XCTAssertEqual(raiz.todos("line").filter { $0.atributos["stroke-width"] == "3" }.count, 14)
        // Con alturas, los nombres llevan octava.
        let alturas = try XCTUnwrap(ElementoXML.leer(TablaArmonica([Altura("Do4"), Altura("Mib4")]).svg()))
        XCTAssertTrue(alturas.todos("text").contains { $0.texto == "Mi♭4" && $0.atributos["font-weight"] == "bold" })
        let ingles = try XCTUnwrap(ElementoXML.leer(TablaArmonica(Acorde("Re")).svg(notacion: .ingles)))
        XCTAssertTrue(ingles.todos("text").contains { $0.texto == "F#" })
    }

    func testTituloYLeyenda() throws {
        func leyenda(_ raiz: ElementoXML) -> [String] {
            raiz.todos("g").filter { $0.atributos["class"] == "leyenda" }.flatMap { $0.todos("text").map(\.texto) }
        }
        let acorde = try XCTUnwrap(ElementoXML.leer(TablaArmonica(Acorde("Domaj7")).svg()))
        XCTAssertEqual(acorde.todos("title").first?.texto, "Domaj7")
        XCTAssertEqual(leyenda(acorde), ["nota", "fundamental", "contorno de la forma", "tríada mayor", "tríada menor"])
        let escala = try XCTUnwrap(ElementoXML.leer(TablaArmonica(Escala(.re, .dorico)).svg()))
        XCTAssertEqual(escala.todos("title").first?.texto, "Re dórico")
        XCTAssertEqual(leyenda(escala)[1], "tónica")
        let alturas = try XCTUnwrap(ElementoXML.leer(TablaArmonica([Altura("Do3"), Altura("Sol3")]).svg(notacion: .ingles)))
        XCTAssertEqual(alturas.todos("title").first?.texto, "C3 · G3")
        XCTAssertEqual(leyenda(alturas), ["pitch (every key)", "first note", "outline of the shape"])
        XCTAssertTrue(leyenda(try XCTUnwrap(ElementoXML.leer(TablaArmonica(Acorde("Do")).svg(leyenda: false)))).isEmpty)
        // En catalán, gallego y euskera, el título y la leyenda también.
        let euskera = try XCTUnwrap(ElementoXML.leer(TablaArmonica(Escala(.re, .dorico)).svg(notacion: .euskera)))
        XCTAssertEqual(euskera.todos("title").first?.texto, "re doriarra")
        XCTAssertEqual(leyenda(euskera)[1], "tonika")
        let catalan = try XCTUnwrap(ElementoXML.leer(TablaArmonica(Acorde("Domaj7")).svg(notacion: .catalan)))
        XCTAssertEqual(leyenda(catalan), ["nota", "fonamental", "contorn de la forma", "tríada major", "tríada menor"])
        let ciclo = try XCTUnwrap(ElementoXML.leer(XCTUnwrap(TablaArmonica(ciclo: .hexatonico, desde: "Do")).svg(notacion: .gallego)))
        XCTAssertTrue(leyenda(ciclo).contains("fundamental do primeiro acorde"))
    }

    func testRecorrido() throws {
        let tabla = try XCTUnwrap(TablaArmonica(recorrido: ["Do", "Lam", "Fa"]))
        XCTAssertEqual(tabla.recorrido.map(\.acorde), [Acorde("Do"), Acorde("Lam"), Acorde("Fa")])
        XCTAssertEqual(tabla.puntos, Tonnetz(recorrido: ["Do", "Lam", "Fa"])!.puntos)
        XCTAssertNil(TablaArmonica(recorrido: ["Do", "Sol7"]))
        let camino = try XCTUnwrap(TablaArmonica(caminoDesde: "Do", hasta: "Mibm"))
        XCTAssertEqual(camino.recorrido.map(\.acorde), [Acorde("Do"), Acorde("Dom"), Acorde("Mib"), Acorde("Mibm")])
        XCTAssertNil(TablaArmonica(caminoDesde: "Do", hasta: "Sol7"))
        // El dibujo: dos flechas, del vértice de Do al de Lam y de este al de Fa, y el título.
        let raiz = try XCTUnwrap(ElementoXML.leer(tabla.svg()))
        XCTAssertEqual(raiz.todos("line").filter { $0.atributos["marker-end"] != nil }.count, 2)
        XCTAssertEqual(raiz.todos("title").first?.texto, "Do –R→ Lam –L→ Fa")
        let leyenda = raiz.todos("g").filter { $0.atributos["class"] == "leyenda" }.flatMap { $0.todos("text").map(\.texto) }
        XCTAssertEqual(leyenda.last, "paso del recorrido (P, L, R)")
        XCTAssertTrue(leyenda.contains("fundamental del primer acorde"))
        // Las flechas empiezan en el vértice común de los tres hexágonos de la tríada: a la
        // distancia del radio de cada uno de sus centros.
        let primera = try XCTUnwrap(raiz.todos("line").first { $0.atributos["marker-end"] != nil })
        let paso = 72.0, coseno = 0.8660254037844386
        let vertices = Tonnetz.Triada(Acorde("Do"))!.vertices
        let cx = vertices.map { Double($0.terceras) * coseno * paso }.reduce(0, +) / 3
        let cy = vertices.map { -(Double($0.quintas) + Double($0.terceras) / 2) * paso }.reduce(0, +) / 3
        for v in vertices {
            let d = ((Double(v.terceras) * coseno * paso - cx) * (Double(v.terceras) * coseno * paso - cx)
                     + (-(Double(v.quintas) + Double(v.terceras) / 2) * paso - cy) * (-(Double(v.quintas) + Double(v.terceras) / 2) * paso - cy)).squareRoot()
            XCTAssertEqual(d, paso / (2 * coseno), accuracy: 0.001)
        }
        let x1 = try XCTUnwrap(Double(primera.atributos["x1"] ?? "")), y1 = try XCTUnwrap(Double(primera.atributos["y1"] ?? ""))
        XCTAssertLessThan(((x1 - cx) * (x1 - cx) + (y1 - cy) * (y1 - cy)).squareRoot(), paso * 0.15)
    }
    func testCiclo() throws {
        let tabla = try XCTUnwrap(TablaArmonica(ciclo: .hexatonico, desde: "Do"))
        let tonnetz = try XCTUnwrap(Tonnetz(ciclo: .hexatonico, desde: "Do"))
        XCTAssertEqual(tabla.puntos, tonnetz.puntos)
        XCTAssertEqual(tabla.recorrido.count, 7)
        XCTAssertEqual(tabla.description, tonnetz.description)
        let raiz = try XCTUnwrap(ElementoXML.leer(tabla.svg()))
        XCTAssertEqual(raiz.todos("title").first?.texto, "Do –P→ Dom –L→ La♭ –P→ La♭m –L→ Mi –P→ Mim –L→ Do")
        XCTAssertEqual(raiz.todos("line").filter { $0.atributos["marker-end"] != nil }.count, 6)
        // Los hexágonos se llaman como en las tríadas del ciclo: Do♭ en La♭m, nunca Fa♭.
        let textos = raiz.todos("text").map(\.texto)
        XCTAssertTrue(textos.contains("Do♭"))
        XCTAssertFalse(textos.contains("Fa♭") || textos.contains { $0.contains("♭♭") })
        XCTAssertEqual(TablaArmonica(ciclo: .octatonico, desde: "Do")?.recorrido.count, 9)
        XCTAssertNil(TablaArmonica(ciclo: .lr, desde: "Do7"))
    }
}
