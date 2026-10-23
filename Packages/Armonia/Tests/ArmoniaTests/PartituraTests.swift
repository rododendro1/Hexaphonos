import XCTest
@testable import Armonia
@testable import ArmoniaNucleo
@testable import ArmoniaTeoria
@testable import ArmoniaRepresentaciones
@testable import ArmoniaPartitura

final class MelodiaTests: XCTestCase {
    let arpegio: Melodia = ["Do4", "Mi4", "Sol4"]

    func testPropiedades() {
        XCTAssertEqual(arpegio.count, 3)
        XCTAssertEqual(arpegio[1], Altura("Mi4"))
        XCTAssertEqual(arpegio.intervalos, [.terceraMayor, .terceraMenor])
        XCTAssertEqual(Melodia(["Do4", "Re4", "Re4", "Si3"]).contorno, [1, 0, -1])
        XCTAssertEqual(arpegio.ambito, .quintaJusta)
        XCTAssertEqual(arpegio.alturaMasGrave, Altura("Do4"))
        XCTAssertEqual(arpegio.midi, [60, 64, 67])
        XCTAssertEqual(arpegio.conjuntoDeClases.numeroDeForte, "3-11")
        XCTAssertNil(Melodia([]).ambito)
    }

    func testTransformaciones() {
        XCTAssertEqual(arpegio.transponer(.segundaMayor).description, "Re4 Fa♯4 La4")
        XCTAssertEqual(arpegio.invertir().description, "Do4 La♭3 Fa3")
        XCTAssertEqual(arpegio.invertir(alrededorDe: "Mi4").description, "Sol♯4 Mi4 Do♯4")
        XCTAssertEqual(arpegio.retrogradar().description, "Sol4 Mi4 Do4")
        XCTAssertEqual(arpegio.retrogradarInversion().description, "Fa3 La♭3 Do4")
        XCTAssertEqual(arpegio.invertir().invertir(), arpegio)
    }

    func testTransposicionTonal() {
        let doMayor = Escala(.do)
        XCTAssertEqual(arpegio.transponer(grados: 1, en: doMayor)?.description, "Re4 Fa4 La4")
        XCTAssertEqual(arpegio.transponer(grados: -1, en: doMayor)?.description, "Si3 Re4 Fa4")
        XCTAssertEqual(arpegio.transponer(grados: 7, en: doMayor)?.description, "Do5 Mi5 Sol5")
        XCTAssertEqual(Melodia(["Do4", "Do#4", "Re4"]).transponer(grados: 2, en: doMayor)?.description,
                       "Mi4 Mi♯4 Fa4")
        let armonica = Escala(.la, .menorArmonica)
        XCTAssertEqual(Melodia(["La4", "Do5", "Mi5"]).transponer(grados: 1, en: armonica)?.description, "Si4 Re5 Fa5")
        XCTAssertEqual(Melodia(["Mi5", "Fa5", "Mi5"]).transponer(grados: -1, en: armonica)?.description, "Re5 Mi5 Re5")
        // Una nota ajena a la escala conserva su alteración relativa: Sol♮ es el 7.º grado
        // rebajado de La menor armónica, y cuatro grados más arriba se convierte en el 4.º rebajado.
        XCTAssertEqual(Melodia(["Sol4"]).transponer(grados: 4, en: armonica)?.description, "Re♭5")
        XCTAssertNil(arpegio.transponer(grados: 1, en: Escala(.do, .pentatonicaMayor)))
    }

    func testDesdeMidiYCodable() throws {
        let melodia = Melodia(midi: [69, 71, 72, 74, 76, 77, 80, 81])
        XCTAssertEqual(melodia.description, "La4 Si4 Do5 Re5 Mi5 Fa5 Sol♯5 La5")
        XCTAssertEqual(Melodia(midi: [70], escala: Escala(.fa)).description, "Si♭4")
        XCTAssertEqual(melodia.candidatosDeTonalidad.first?.valor, Tonalidad(.la, .menor))

        let datos = try JSONEncoder().encode(arpegio)
        XCTAssertEqual(String(decoding: datos, as: UTF8.self), "[\"Do4\",\"Mi4\",\"Sol4\"]")
        XCTAssertEqual(try JSONDecoder().decode(Melodia.self, from: datos), arpegio)
    }
}

final class RitmoTests: XCTestCase {
    func testFiguras() {
        XCTAssertEqual(Figura.negra.duracion, Duracion(1, 4))
        XCTAssertEqual(Figura.cuadrada.duracion, Duracion(2))
        XCTAssertEqual(Figura.garrapatea.duracion, Duracion(1, 128))
        XCTAssertEqual(Figura.semicorchea.nombre, "semicorchea")
        XCTAssertEqual(Figura.corchea.nombre(en: .ingles), "eighth note")
    }

    func testDuraciones() {
        XCTAssertEqual(Duracion(2, 8), .negra)
        XCTAssertEqual(Duracion(.negra, puntillos: 1), Duracion(3, 8))
        XCTAssertEqual(Duracion(.negra, puntillos: 2), Duracion(7, 16))
        XCTAssertEqual(Duracion.corchea.grupoIrregular(3, en: 2), Duracion(1, 12))
        XCTAssertEqual(Duracion.semicorchea.grupoIrregular(5, en: 4), Duracion(1, 20))
        XCTAssertEqual(Duracion.blanca + .corchea, Duracion(5, 8))
        XCTAssertEqual(Duracion.blanca - .corchea, Duracion(3, 8))
        XCTAssertEqual(Duracion.negra * 3, Duracion(3, 4))
        XCTAssertEqual(Duracion.blanca / .negra, Duracion(2))
        XCTAssertEqual([Duracion.negra, .corchea, .corchea].sumar(), .blanca)
        XCTAssertLessThan(Duracion.negra, .blanca)
        XCTAssertEqual(Duracion.negra.enRedondas, 0.25)
    }

    func testEscrituraDeDuraciones() {
        XCTAssertEqual(Duracion(3, 8).figuraYPuntillos?.figura, .negra)
        XCTAssertEqual(Duracion(3, 8).figuraYPuntillos?.puntillos, 1)
        XCTAssertNil(Duracion(5, 8).figuraYPuntillos)
        XCTAssertEqual(Duracion(5, 8).descomposicion, [.blanca, .corchea])
        XCTAssertEqual(Duracion(11, 16).descomposicion, [.blanca, .corchea, .semicorchea])
        XCTAssertEqual(Duracion(7, 8).descomposicion, [Duracion(7, 8)])
        XCTAssertNil(Duracion(1, 12).descomposicion)
        XCTAssertEqual(Duracion(3, 8).nombre, "negra con puntillo")
        XCTAssertEqual(Duracion(7, 8).nombre, "blanca con doble puntillo")
        XCTAssertEqual(Duracion(5, 8).nombre, "5/8 de redonda")
        XCTAssertEqual(Duracion(3, 8).nombre(en: .ingles), "dotted quarter note")
        XCTAssertEqual(Duracion.corchea.ticks(porNegra: 480), 240)
        XCTAssertEqual(Duracion(1, 12).ticks(porNegra: 480), 160)
        XCTAssertNil(Duracion(1, 7).ticks(porNegra: 480))
    }

    func testLecturaDeDuraciones() {
        let casos: [(String, Duracion)] = [("1", .redonda), ("4", .negra), ("16", .semicorchea), ("8.", Duracion(3, 16)),
                                           ("2..", Duracion(7, 8)), ("1/12", Duracion(1, 12)), ("5/8", Duracion(5, 8)),
                                           ("2/1", .cuadrada), ("128", .garrapatea)]
        for (texto, duracion) in casos {
            XCTAssertEqual(Duracion(texto: texto), duracion, texto)
            XCTAssertEqual(duracion.texto, texto, texto)
        }
        for malo in ["3", "0", "4.x", "1/0", "", "256", "-4"] {
            XCTAssertNil(Duracion(texto: malo), malo)
        }
        XCTAssertThrowsError(try Duracion(leyendo: "3")) { error in
            XCTAssertEqual((error as? ErrorDeLectura)?.motivo, .duracionNoValida("3"))
        }
    }

    func testCompases() {
        let seisOcho: Compas = "6/8"
        XCTAssertEqual(seisOcho.tipo, .compuesto)
        XCTAssertEqual(seisOcho.pulsos, 2)
        XCTAssertEqual(seisOcho.pulso, Duracion(.negra, puntillos: 1))
        XCTAssertEqual(Compas("12/8").pulsos, 4)
        XCTAssertEqual(Compas("3/4").tipo, .simple)
        XCTAssertEqual(Compas("3/4").duracion, Duracion(.blanca, puntillos: 1))
        XCTAssertEqual(Compas("7/8").tipo, .amalgama)
        XCTAssertEqual(Compas("7/8").pulsos, 3)   // 2+2+3
        XCTAssertEqual(Compas("C"), .compasillo)
        XCTAssertEqual(Compas("¢"), .partido)
        XCTAssertEqual(Compas.compasillo.duracion, .redonda)
        XCTAssertNil(Compas(texto: "4/3"))
        XCTAssertNil(Compas(texto: "0/4"))
        XCTAssertEqual(seisOcho.texto, "6/8")
    }

    func testTempo() {
        XCTAssertEqual(Tempo(120).segundos(de: .blanca), 1, accuracy: 1e-12)
        XCTAssertEqual(Tempo(60, unidad: Duracion(.negra, puntillos: 1)).negrasPorMinuto, 90, accuracy: 1e-12)
        XCTAssertEqual(Tempo(100).indicacion, "Andante")
        XCTAssertEqual(Tempo(130).indicacion, "Allegro")
        XCTAssertEqual(Tempo(30).indicacion, "Grave")
        XCTAssertEqual(Tempo(220).indicacion, "Prestissimo")
        XCTAssertEqual(Tempo(120).description, "♩ = 120")
    }

    func testEventos() {
        let e: Evento = "Do4:4."
        XCTAssertEqual(e.alturas, [Altura("Do4")])
        XCTAssertEqual(e.duracion, Duracion(3, 8))
        XCTAssertEqual(Evento("Do4+Mi4+Sol4:2").alturas.count, 3)
        XCTAssertEqual(Evento("-:8"), .silencio(.corchea))
        XCTAssertEqual(Evento("silencio:8"), .silencio(.corchea))
        XCTAssertTrue(Evento("Re4:2~").ligada)
        XCTAssertFalse(Evento.silencio(.negra).ligada)
        for texto in ["Do4:4.", "Do4+Mi4+Sol4:2", "-:8", "Re4:2~", "Fa♯3:1/12"] {
            XCTAssertEqual(Evento(texto: texto)?.texto, texto, texto)
        }
        XCTAssertThrowsError(try Evento(leyendo: "Do4:3")) { error in
            XCTAssertEqual((error as? ErrorDeLectura)?.motivo, .duracionNoValida("3"))
            XCTAssertEqual((error as? ErrorDeLectura)?.posicion, 4)
        }
        XCTAssertNil(Evento(texto: "Do4"))
        XCTAssertEqual(Evento("Do4:4").transponer(.quintaJusta), Evento("Sol4:4"))
    }

    func testVoces() throws {
        let voz = try Voz(leyendo: "Do4:4 Re4:8 Mi4:8 Fa4:2. Sol4:4", compas: "3/4")
        XCTAssertEqual(voz.duracion, Duracion(3, 2))
        XCTAssertEqual(voz.ritmo.map(\.texto), ["4", "8", "8", "2.", "4"])
        XCTAssertEqual(voz.melodia.alturas.map(\.description), ["Do4", "Re4", "Mi4", "Fa4", "Sol4"])
        XCTAssertEqual(voz.segundos(tempo: Tempo(90)), 4, accuracy: 1e-12)
        XCTAssertTrue(voz.terminaEnBarra)
        let compases = voz.compases
        XCTAssertEqual(compases.map { $0.map(\.texto) }, [["Do4:4", "Re4:8", "Mi4:8", "Fa4:4~"], ["Fa4:2", "Sol4:4"]])
        // Repartir en compases no cambia la melodía: la nota ligada cuenta una vez.
        XCTAssertEqual(Voz(compases.flatMap { $0 }, compas: voz.compas).melodia, voz.melodia)
        XCTAssertEqual(voz.description, "3/4 Do4:4 Re4:8 Mi4:8 Fa4:2. Sol4:4")
    }

    func testAnacrusaYSilencios() throws {
        let himno = try Voz(leyendo: "Sol3:4 Do4:2. Re4:4", compas: "3/4", anacrusa: .negra)
        XCTAssertEqual(himno.compases.map { $0.map(\.texto) }, [["Sol3:4"], ["Do4:2."], ["Re4:4"]])
        XCTAssertFalse(himno.terminaEnBarra)
        let silencio = try Voz(leyendo: "-:1", compas: "3/4")
        XCTAssertEqual(silencio.compases.map { $0.map(\.texto) }, [["-:2."], ["-:4"]])
        XCTAssertThrowsError(try Voz(leyendo: "Do4:4 Re4:3")) { error in
            XCTAssertEqual((error as? ErrorDeLectura)?.posicion, 10)
        }
    }

    func testTransformacionesYMelodia() throws {
        let voz = try Voz(leyendo: "Do4:2~ Do4:4 Re4:4")
        XCTAssertEqual(voz.retrogradar().texto(), "Re4:4 Do4:4~ Do4:2")
        XCTAssertEqual(voz.aumentar(2).ritmo, [.redonda, .blanca, .blanca])
        XCTAssertEqual(voz.disminuir(2).ritmo, [.negra, .corchea, .corchea])
        XCTAssertEqual(voz.transponer(.segundaMayor).melodia.alturas.first, Altura("Re4"))
        XCTAssertEqual(voz.melodia.alturas.count, 2)
        let unida = Voz(melodia: ["Do4", "Mi4", "Sol4"], ritmo: [.negra, .negra, .blanca], compas: "3/4")
        XCTAssertEqual(unida?.texto(.ingles), "C4:4 E4:4 G4:2")
        XCTAssertNil(Voz(melodia: ["Do4", "Mi4"], ritmo: [.negra]))
        // Se codifica en JSON y vuelve igual.
        let datos = try JSONEncoder().encode(voz)
        XCTAssertEqual(try JSONDecoder().decode(Voz.self, from: datos), voz)
    }

    /// Al imprimir, una duración da su nombre; `texto` da la forma corta que se lee.
    func testDescripcionDeDuracion() {
        let d = Duracion(.negra, puntillos: 1)
        XCTAssertEqual("\(d)", "negra con puntillo")
        XCTAssertEqual(d.texto, "4.")
        XCTAssertEqual(Duracion(texto: d.texto), d)
        XCTAssertEqual("\(Duracion.blanca + .corchea)", "5/8 de redonda")
        XCTAssertEqual((Duracion.blanca + .corchea).texto, "5/8")
        XCTAssertEqual(Duracion.corchea.nombre(en: .ingles), "eighth note")
        XCTAssertEqual("\(Duracion.cero)", "cero")
    }
}

final class MetricaTests: XCTestCase {
    func testAgrupaciones() {
        XCTAssertEqual(Compas.compasillo.agrupacion, [1, 1, 1, 1])
        XCTAssertEqual(Compas("6/8").agrupacion, [3, 3])
        XCTAssertEqual(Compas("12/8").agrupacion, [3, 3, 3, 3])
        XCTAssertEqual(Compas("5/8").agrupacion, [2, 3])
        XCTAssertEqual(Compas("7/8").agrupacion, [2, 2, 3])
        let siete = Compas("3+2+2/8")
        XCTAssertEqual(siete.agrupacion, [3, 2, 2])
        XCTAssertEqual(siete.numerador, 7)
        XCTAssertEqual(siete.texto, "3+2+2/8")
        XCTAssertEqual(Compas("7/8").texto, "7/8")
        XCTAssertNotEqual(siete, Compas("7/8"))
        XCTAssertEqual(Compas("2+2+3/8"), Compas("7/8"))
        XCTAssertEqual(siete.duracionesDePulso, [Duracion(.negra, puntillos: 1), .negra, .negra])
        XCTAssertEqual(Compas("7/8").pulso, .corchea)
        XCTAssertEqual(Compas("6/8").iniciosDePulso, [.cero, Duracion(3, 8)])
        XCTAssertNil(Compas(texto: "2+0/8"))
        XCTAssertNil(Compas(texto: "+/8"))
    }

    func testAcentos() {
        let cuatro = Compas.compasillo
        XCTAssertEqual((0..<4).map { cuatro.acento(pulso: $0) }, [.fuerte, .debil, .semifuerte, .debil])
        XCTAssertEqual((0..<3).map { Compas("3/4").acento(pulso: $0) }, [.fuerte, .debil, .debil])
        XCTAssertEqual((0..<2).map { Compas("6/8").acento(pulso: $0) }, [.fuerte, .debil])
        XCTAssertEqual((0..<4).map { Compas("12/8").acento(pulso: $0) }, [.fuerte, .debil, .semifuerte, .debil])
        XCTAssertEqual((0..<3).map { Compas("7/8").acento(pulso: $0) }, [.fuerte, .debil, .semifuerte])
        XCTAssertEqual(cuatro.acento(en: .blanca), .semifuerte)
        XCTAssertNil(cuatro.acento(en: .corchea))
        XCTAssertGreaterThan(Compas.Acento.fuerte, .semifuerte)
    }

    func testEscrituraEnCompasillo() throws {
        func escrito(_ texto: String, _ compas: Compas = .compasillo) throws -> [[String]] {
            try Voz(leyendo: texto, compas: compas).grafia.map { $0.map(\.texto) }
        }
        // La blanca del 2.º tiempo no oculta la mitad del compás.
        XCTAssertEqual(try escrito("Do4:4 Re4:2 Mi4:4"), [["Do4:4", "Re4:4~", "Re4:4", "Mi4:4"]])
        // En el 1.er tiempo sí puede durar hasta la mitad o más.
        XCTAssertEqual(try escrito("Do4:2 Re4:2"), [["Do4:2", "Re4:2"]])
        XCTAssertEqual(try escrito("Do4:2. Re4:4"), [["Do4:2.", "Re4:4"]])
        XCTAssertEqual(try escrito("Do4:1"), [["Do4:1"]])
        // La negra con puntillo del 1.er o del 3.er tiempo se escribe entera.
        XCTAssertEqual(try escrito("Do4:4. Re4:8 Mi4:4. Fa4:8"), [["Do4:4.", "Re4:8", "Mi4:4.", "Fa4:8"]])
        XCTAssertEqual(try escrito("Do4:4.. Re4:16 Mi4:2"), [["Do4:4..", "Re4:16", "Mi4:2"]])
        XCTAssertEqual(try escrito("Do4:4. Re4:8", Compas(3, 4)), [["Do4:4.", "Re4:8"]])
        XCTAssertEqual(try escrito("Do4:4 Re4:4. Mi4:8", Compas(3, 4)), [["Do4:4", "Re4:4.", "Mi4:8"]])
        XCTAssertEqual(try escrito("Do4:2. Re4:4", .partido), [["Do4:2.", "Re4:4"]])
        // La corchea con puntillo a contratiempo no: empieza fuera del pulso.
        XCTAssertEqual(try escrito("Do4:8 Re4:4. Mi4:2"), [["Do4:8", "Re4:8~", "Re4:4", "Mi4:2"]])
        // Negra con puntillo en el 2.º tiempo de 4/4: se ve el 3.º.
        XCTAssertEqual(try escrito("Do4:4 Re4:4. Mi4:8 Fa4:4"), [["Do4:4", "Re4:4~", "Re4:8", "Mi4:8", "Fa4:4"]])
        // Una síncopa de corchea: la negra a contratiempo se parte en el pulso.
        XCTAssertEqual(try escrito("Do4:8 Re4:4 Mi4:8 Fa4:2"), [["Do4:8", "Re4:8~", "Re4:8", "Mi4:8", "Fa4:2"]])
        // 5/8 de redonda se escribe con figuras ligadas; la negra a contratiempo se parte en el 4.º tiempo.
        XCTAssertEqual(try escrito("Do4:5/8 Re4:4 Mi4:8"), [["Do4:2~", "Do4:8", "Re4:8~", "Re4:8", "Mi4:8"]])
        // Los silencios se dividen sin ligaduras.
        XCTAssertEqual(try escrito("Do4:4 -:2 Re4:4"), [["Do4:4", "-:4", "-:4", "Re4:4"]])
        // Una nota que cruza la barra se liga al compás siguiente y se escribe según la métrica
        // (la blanca con puntillo del 2.º tiempo no oculta la mitad).
        XCTAssertEqual(try escrito("Do4:2. Re4:2 Mi4:2."), [["Do4:2.", "Re4:4~"], ["Re4:4", "Mi4:4~", "Mi4:2"]])
    }

    func testEscrituraEnSeisPorOcho() throws {
        func escrito(_ texto: String) throws -> [[String]] {
            try Voz(leyendo: texto, compas: "6/8").grafia.map { $0.map(\.texto) }
        }
        XCTAssertEqual(try escrito("Do4:4. Re4:4."), [["Do4:4.", "Re4:4."]])
        XCTAssertEqual(try escrito("Do4:8 Re4:4 Mi4:4."), [["Do4:8", "Re4:4", "Mi4:4."]])
        // La negra que empieza en la 3.ª corchea cruza el pulso: se parte.
        XCTAssertEqual(try escrito("Do4:4 Re4:4 Mi4:4"), [["Do4:4", "Re4:8~", "Re4:8", "Mi4:4"]])
        XCTAssertEqual(try escrito("Do4:2."), [["Do4:2."]])
        // En 6/8 la negra con puntillo no cruza el grupo de tres corcheas.
        XCTAssertEqual(try escrito("Do4:8 Re4:4. Mi4:4"), [["Do4:8", "Re4:4~", "Re4:8", "Mi4:4"]])
    }

    func testEscrituraEnAmalgama() throws {
        func escrito(_ texto: String, _ compas: Compas) throws -> [[String]] {
            try Voz(leyendo: texto, compas: compas).grafia.map { $0.map(\.texto) }
        }
        // Una figura puede abarcar grupos iguales (la blanca de 2+2), pero no el paso a uno distinto.
        XCTAssertEqual(try escrito("Do4:2 Mi4:4.", "7/8"), [["Do4:2", "Mi4:4."]])
        XCTAssertEqual(try escrito("Do4:2..", "7/8"), [["Do4:2~", "Do4:4."]])
        XCTAssertEqual(try escrito("Do4:2..", "3+2+2/8"), [["Do4:4.~", "Do4:2"]])
        XCTAssertEqual(try escrito("Do4:2. Re4:8", "7/8"), [["Do4:2~", "Do4:4", "Re4:8"]])
        XCTAssertEqual(try escrito("Do4:2. Re4:4", "3+3+2/8"), [["Do4:2.", "Re4:4"]])
        // Las notas que cruzan el comienzo de un grupo se parten en él.
        XCTAssertEqual(try escrito("Do4:4. Re4:4 Mi4:4", "7/8"), [["Do4:4~", "Do4:8", "Re4:8~", "Re4:8", "Mi4:4"]])
        XCTAssertEqual(try escrito("Do4:2 Re4:4.", "3+2+2/8"), [["Do4:4.~", "Do4:8", "Re4:8~", "Re4:4"]])
        XCTAssertEqual(try escrito("Do4:4. Re4:4", "5/8"), [["Do4:4~", "Do4:8", "Re4:4"]])
        XCTAssertEqual(try escrito("Do4:5/8", "5/8"), [["Do4:4~", "Do4:4."]])
        // El silencio de todo el compás queda entero.
        XCTAssertEqual(try escrito("-:7/8 Do4:2..", "7/8"), [["-:2.."], ["Do4:2~", "Do4:4."]])
        XCTAssertEqual(try escrito("-:5/8", "5/8"), [["-:5/8"]])
        // Las barras siguen los grupos: 2+2+3.
        let voz = try Voz(leyendo: "Do4:8 Re4:8 Mi4:8 Fa4:8 Sol4:8 La4:8 Si4:8", compas: "7/8")
        XCTAssertEqual(voz.barrasDeAgrupacion, [[[0, 1], [2, 3], [4, 5, 6]]])
    }

    func testBarrasYAcentosDeLaVoz() throws {
        let voz = try Voz(leyendo: "Do4:8 Re4:8 Mi4:8 Fa4:8 Sol4:8 La4:8", compas: "6/8")
        XCTAssertEqual(voz.barrasDeAgrupacion, [[[0, 1, 2], [3, 4, 5]]])
        XCTAssertEqual(voz.acentos, [[.fuerte, nil, nil, .debil, nil, nil]])
        let cuatro = try Voz(leyendo: "Do4:8 Re4:8 Mi4:4 Fa4:16 Sol4:16 La4:8 -:8 Si4:8")
        XCTAssertEqual(cuatro.barrasDeAgrupacion, [[[0, 1], [3, 4, 5]]])
        XCTAssertEqual(cuatro.acentos.first?.first, .fuerte)
        // Con anacrusa, la primera nota cae en el último pulso del compás.
        let himno = try Voz(leyendo: "Sol3:4 Do4:2. Re4:4", compas: "3/4", anacrusa: .negra)
        XCTAssertEqual(himno.acentos, [[.debil], [.fuerte], [.fuerte]])
    }
}

final class PentagramaTests: XCTestCase {
    func testClaveDeSol() {
        let casos: [(Altura, Int, String)] = [
            ("Mi4", 0, "1.ª línea"), ("Fa4", 1, "1.er espacio"), ("Sol4", 2, "2.ª línea"),
            ("Do5", 5, "3.er espacio"), ("Fa5", 8, "5.ª línea"), ("Sol5", 9, "encima de la 5.ª línea"),
            ("La5", 10, "1.ª línea adicional superior"), ("Si5", 11, "encima de la 1.ª línea adicional superior"),
            ("Re4", -1, "debajo de la 1.ª línea"), ("Do4", -2, "1.ª línea adicional inferior"),
            ("Si3", -3, "debajo de la 1.ª línea adicional inferior"), ("La3", -4, "2.ª línea adicional inferior"),
        ]
        for (nota, lugar, descripcion) in casos {
            let posicion = Clave.sol.posicion(de: nota)
            XCTAssertEqual(posicion.lugar, lugar, nota.description)
            XCTAssertEqual(posicion.descripcion, descripcion, nota.description)
        }
        XCTAssertEqual(Clave.sol.posicion(de: "Do4").lineasAdicionales, -1)
        XCTAssertEqual(Clave.sol.posicion(de: "La3").lineasAdicionales, -2)
        XCTAssertEqual(Clave.sol.posicion(de: "Do6").lineasAdicionales, 2)
        XCTAssertEqual(Clave.sol.posicion(de: "Fa#4").description, "1.er espacio (♯)")
        XCTAssertEqual(Clave.sol.posicion(de: "Fa#4").lugar, Clave.sol.posicion(de: "Fa4").lugar)
    }

    func testOtrasClaves() {
        XCTAssertEqual(Clave.fa.posicion(de: "Sol2").lugar, 0)
        XCTAssertEqual(Clave.fa.posicion(de: "La3").lugar, 8)
        XCTAssertEqual(Clave.fa.posicion(de: "Do4").lineasAdicionales, 1)
        XCTAssertEqual(Clave.doEnPrimera.posicion(de: "Do4").lugar, 0)
        XCTAssertEqual(Clave.doEnSegunda.posicion(de: "Do4").lugar, 2)
        XCTAssertEqual(Clave.doEnTercera.posicion(de: "Do4").lugar, 4)
        XCTAssertEqual(Clave.doEnCuarta.posicion(de: "Do4").lugar, 6)
        XCTAssertEqual(Clave.faEnTercera.posicion(de: "Fa3").lugar, 4)
        XCTAssertEqual(Clave.solOctavaBaja.posicion(de: "Mi3").lugar, 0)
        XCTAssertEqual(Clave.sol.alturaCentral, Altura("Si4"))
        XCTAssertEqual(Clave.fa.alturaCentral, Altura("Re3"))
        XCTAssertEqual(Clave.doEnTercera.alturaCentral, Altura("Do4"))
        XCTAssertEqual(Clave.fa.altura(lugar: 8), Altura("La3"))
        XCTAssertEqual(Clave.sol.altura(lugar: 4, alteracion: -1), Altura("Sib4"))
        XCTAssertEqual(Clave.doEnTercera.nombre(en: .ingles), "alto clef")
    }

    func testIdaYVueltaDePosiciones() {
        for clave in Clave.allCases {
            for lugar in -12...20 {
                for alteracion in -2...2 {
                    let nota = clave.altura(lugar: lugar, alteracion: Alteracion(alteracion))
                    XCTAssertEqual(clave.posicion(de: nota), PosicionEnPentagrama(lugar: lugar, alteracion: Alteracion(alteracion)),
                                   "\(clave) \(lugar)")
                }
            }
        }
    }

    func testClaveMasAdecuada() {
        XCTAssertEqual(Clave.masAdecuada(para: ["Do2", "Mi2", "Sol2"]), .fa)
        XCTAssertEqual(Clave.masAdecuada(para: ["Do5", "Mi5", "Sol5"]), .sol)
        XCTAssertEqual(Clave.masAdecuada(para: ["Do4", "Re4", "Mi4"], entre: [.sol, .fa, .doEnTercera]), .doEnTercera)
    }
}

final class InstrumentosTests: XCTestCase {
    func testTransposicion() {
        XCTAssertEqual(Instrumento.clarineteEnSib.sonido(de: Altura("Do5")), Altura("Sib4"))
        XCTAssertEqual(Instrumento.clarineteEnSib.escritura(de: Altura("Sib4")), Altura("Do5"))
        XCTAssertEqual(Instrumento.clarineteEnLa.sonido(de: Altura("Do5")), Altura("La4"))
        XCTAssertEqual(Instrumento.clarineteEnMib.sonido(de: Altura("Do5")), Altura("Mib5"))
        XCTAssertEqual(Instrumento.trompaEnFa.sonido(de: Altura("Do5")), Altura("Fa4"))
        XCTAssertEqual(Instrumento.saxofonAlto.sonido(de: Altura("Do5")), Altura("Mib4"))
        XCTAssertEqual(Instrumento.saxofonTenor.sonido(de: Altura("Do5")), Altura("Sib3"))
        XCTAssertEqual(Instrumento.saxofonBaritono.sonido(de: Altura("Do5")), Altura("Mib3"))
        XCTAssertEqual(Instrumento.contrabajo.sonido(de: Altura("Do3")), Altura("Do2"))
        XCTAssertEqual(Instrumento.guitarra.sonido(de: Altura("Mi4")), Altura("Mi3"))
        XCTAssertEqual(Instrumento.flautin.sonido(de: Altura("Do5")), Altura("Do6"))
        XCTAssertEqual(Instrumento.glockenspiel.sonido(de: Altura("Do5")), Altura("Do7"))
        XCTAssertFalse(Instrumento.piano.esTranspositor)
        XCTAssertTrue(Instrumento.trompetaEnSib.esTranspositor)
        XCTAssertEqual(Instrumento.todos.count, 30)
        XCTAssertEqual(Instrumento.viola.clave, .doEnTercera)
    }

    func testTonalidadesYAcordesEscritos() {
        XCTAssertEqual(Instrumento.clarineteEnSib.escritura(de: Escala("Mib mayor")), Escala(.fa))
        XCTAssertEqual(Instrumento.saxofonAlto.escritura(de: Acorde("Do7")).cifrado, "La7")
        XCTAssertEqual(Instrumento.saxofonAlto.escritura(de: Escala("Si mayor")).nombre, "La♭ mayor")
        XCTAssertEqual(Instrumento.saxofonAlto.escritura(de: Escala("Si mayor"), simplificar: false).nombre,
                       "Sol♯ mayor")
        XCTAssertEqual(Instrumento.trompaEnFa.escritura(de: Nota.fa), .do)

        let melodia: Melodia = ["Do4", "Mi4", "Sol4"]
        let escrita = Instrumento.trompetaEnSib.escritura(de: melodia)
        XCTAssertEqual(escrita.description, "Re4 Fa♯4 La4")
        XCTAssertEqual(Instrumento.trompetaEnSib.sonido(de: escrita), melodia)
        for instrumento in Instrumento.todos {
            for nota in ["Do4", "Fa#3", "Sib5"] as [Altura] {
                XCTAssertEqual(instrumento.sonido(de: instrumento.escritura(de: nota)), nota, instrumento.nombre)
            }
        }
    }
}
