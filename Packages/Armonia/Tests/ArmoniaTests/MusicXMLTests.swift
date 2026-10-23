import XCTest
#if canImport(FoundationXML)
import FoundationXML
#endif
import Foundation
@testable import Armonia
@testable import ArmoniaNucleo
@testable import ArmoniaTeoria
@testable import ArmoniaRepresentaciones
@testable import ArmoniaPartitura

/// Un elemento XML leído con `XMLParser`, para comprobar lo que se exporta.
final class ElementoXML {
    let nombre: String
    let atributos: [String: String]
    var hijos: [ElementoXML] = []
    var texto = ""

    init(nombre: String, atributos: [String: String]) {
        self.nombre = nombre
        self.atributos = atributos
    }

    subscript(_ nombre: String) -> ElementoXML? { hijos.first { $0.nombre == nombre } }
    func todos(_ nombre: String) -> [ElementoXML] { hijos.filter { $0.nombre == nombre } }
    /// Todos los descendientes con ese nombre, en orden.
    func buscar(_ nombre: String) -> [ElementoXML] {
        hijos.flatMap { ($0.nombre == nombre ? [$0] : []) + $0.buscar(nombre) }
    }
    var entero: Int? { Int(texto.trimmingCharacters(in: .whitespacesAndNewlines)) }

    /// `nil` si el texto no es XML bien formado.
    static func leer(_ texto: String) -> ElementoXML? {
        final class Lector: NSObject, XMLParserDelegate {
            var pila: [ElementoXML] = [ElementoXML(nombre: "#documento", atributos: [:])]
            func parser(_ parser: XMLParser, didStartElement nombre: String, namespaceURI: String?,
                        qualifiedName: String?, attributes: [String: String] = [:]) {
                let elemento = ElementoXML(nombre: nombre, atributos: attributes)
                pila.last!.hijos.append(elemento)
                pila.append(elemento)
            }
            func parser(_ parser: XMLParser, didEndElement nombre: String, namespaceURI: String?,
                        qualifiedName: String?) {
                pila.removeLast()
            }
            func parser(_ parser: XMLParser, foundCharacters texto: String) { pila.last!.texto += texto }
        }
        let parser = XMLParser(data: Data(texto.utf8))
        let lector = Lector()
        parser.delegate = lector
        guard parser.parse() else { return nil }
        return lector.pila.first?.hijos.first
    }
}

final class MusicXMLTests: XCTestCase {
    private func leer(_ xml: String, file: StaticString = #filePath, line: UInt = #line) -> ElementoXML {
        guard let raiz = ElementoXML.leer(xml) else {
            XCTFail("XML mal formado", file: file, line: line)
            return ElementoXML(nombre: "", atributos: [:])
        }
        XCTAssertEqual(raiz.nombre, "score-partwise", file: file, line: line)
        XCTAssertEqual(raiz.atributos["version"], "4.0", file: file, line: line)
        return raiz
    }

    /// La altura escrita en un `<note>`, o `nil` si es un silencio.
    private func altura(_ nota: ElementoXML) -> Altura? {
        guard let pitch = nota["pitch"], let paso = pitch["step"]?.texto, let octava = pitch["octave"]?.entero,
              let indice = ["C", "D", "E", "F", "G", "A", "B"].firstIndex(of: paso) else { return nil }
        let alteracion = pitch["alter"]?.entero ?? 0
        return Altura(Nota(NotaNatural(rawValue: indice)!, Alteracion(alteracion)), octava: octava)
    }

    /// Lo que dura cada compás de una voz, en divisiones (sin contar las notas de acorde).
    private func duraciones(_ raiz: ElementoXML, voz: String = "1") -> [Int] {
        raiz.buscar("measure").map { compas in
            compas.todos("note").filter { $0["chord"] == nil && $0["voice"]?.texto == voz }
                .compactMap { $0["duration"]?.entero }.reduce(0, +)
        }
    }

    func testMelodia() throws {
        let voz = try Voz(leyendo: "Do4:4 Re4:8 Mi4:8 Fa4:2. Sol4:4 -:2.", compas: "3/4")
        let raiz = leer(voz.musicXML(tonalidad: Tonalidad(.do), titulo: "Escala"))
        XCTAssertEqual(raiz["work"]?["work-title"]?.texto, "Escala")
        let compases = raiz.buscar("measure")
        XCTAssertEqual(compases.map { $0.atributos["number"] }, ["1", "2", "3"])
        let atributos = try XCTUnwrap(compases[0]["attributes"])
        XCTAssertEqual(atributos["divisions"]?.entero, 2)
        XCTAssertEqual(atributos["key"]?["fifths"]?.entero, 0)
        XCTAssertEqual(atributos["key"]?["mode"]?.texto, "major")
        XCTAssertEqual(atributos["time"]?["beats"]?.texto, "3")
        XCTAssertEqual(atributos["time"]?["beat-type"]?.texto, "4")
        XCTAssertEqual(atributos["clef"]?["sign"]?.texto, "G")
        XCTAssertEqual(duraciones(raiz), [6, 6, 6])
        let notas = raiz.buscar("note")
        XCTAssertEqual(notas.compactMap(altura), ["Do4", "Re4", "Mi4", "Fa4", "Fa4", "Sol4"])
        XCTAssertEqual(notas.map { $0["type"]?.texto }, ["quarter", "eighth", "eighth", "quarter", "half", "quarter", nil])
        // El silencio que llena el compás es un silencio de compás.
        XCTAssertEqual(notas.last?["rest"]?.atributos["measure"], "yes")
        XCTAssertEqual(compases.last?["barline"]?["bar-style"]?.texto, "light-heavy")
    }

    func testLigadurasYBarras() throws {
        // La blanca del 2.º tiempo se escribe negra ligada a negra; las corcheas van unidas.
        let raiz = leer(try Voz(leyendo: "Do4:4 Re4:2 Mi4:8 Fa4:8").musicXML())
        let notas = raiz.buscar("note")
        XCTAssertEqual(notas.map { $0.todos("tie").map { $0.atributos["type"]! } }, [[], ["start"], ["stop"], [], []])
        XCTAssertEqual(notas.map { $0.buscar("tied").map { $0.atributos["type"]! } }, [[], ["start"], ["stop"], [], []])
        XCTAssertEqual(notas.map { $0["beam"]?.texto }, [nil, nil, nil, "begin", "end"])
        // Una nota que cruza la barra se liga entre compases.
        let cruzada = leer(try Voz(leyendo: "Do4:2 Re4:2 Mi4:2", compas: "3/4").musicXML())
        let tipos = cruzada.buscar("tie").map { $0.atributos["type"]! }
        XCTAssertEqual(tipos, ["start", "stop"])
        XCTAssertEqual(duraciones(cruzada), [3, 3])
    }

    func testOrtografiaIdaYVuelta() throws {
        let alturas: [Altura] = ["Do#4", "Mibb3", "Si#3", "Dob5", "Fax2", "Lab6", "Sol4"]
        let voz = Voz(alturas.map { Evento($0, .negra) }, compas: Compas(7, 4))
        let raiz = leer(voz.musicXML(tonalidad: Tonalidad(.do)))
        XCTAssertEqual(raiz.buscar("note").compactMap(altura), alturas)
        XCTAssertEqual(raiz.buscar("alter").compactMap(\.entero), [1, -2, 1, -1, 2, -1])
    }

    func testAcordesYSilencios() throws {
        let raiz = leer(try Voz(leyendo: "Do4+Mi4+Sol4:2 -:4 Re4+Fa4:4").musicXML(tonalidad: Tonalidad(.do)))
        let notas = raiz.buscar("note")
        XCTAssertEqual(notas.count, 6)
        XCTAssertEqual(notas.map { $0["chord"] != nil }, [false, true, true, false, false, true])
        XCTAssertNotNil(notas[3]["rest"])
        XCTAssertNil(notas[3]["rest"]?.atributos["measure"])
        XCTAssertEqual(duraciones(raiz), [4])
    }

    func testPuntillosYTresillos() throws {
        let raiz = leer(try Voz(leyendo: "Do4:8. Re4:16 Mi4:1/12 Fa4:1/12 Sol4:1/12 La4:1/6 Si4:1/12", compas: "3/4")
            .musicXML())
        XCTAssertEqual(raiz.buscar("divisions").first?.entero, 12)
        let notas = raiz.buscar("note")
        XCTAssertEqual(notas.map { $0.todos("dot").count }, [1, 0, 0, 0, 0, 0, 0])
        XCTAssertEqual(notas.map { $0["type"]?.texto },
                       ["eighth", "16th", "eighth", "eighth", "eighth", "quarter", "eighth"])
        XCTAssertEqual(notas.map { $0["time-modification"]?["actual-notes"]?.entero }, [nil, nil, 3, 3, 3, 3, 3])
        XCTAssertEqual(notas.map { $0["time-modification"]?["normal-notes"]?.entero }, [nil, nil, 2, 2, 2, 2, 2])
        // Dos grupos: tres corcheas, y negra–corchea.
        XCTAssertEqual(notas.map { $0.buscar("tuplet").map { $0.atributos["type"]! } },
                       [[], [], ["start"], [], ["stop"], ["start"], ["stop"]])
        XCTAssertEqual(duraciones(raiz), [36])
        // Quintillo de semicorcheas.
        let quintillo = leer(Voz(Array(repeating: Evento("Do4", Duracion.semicorchea.grupoIrregular(5, en: 4)), count: 5),
                                 compas: Compas(1, 4)).musicXML())
        XCTAssertEqual(quintillo.buscar("type").first?.texto, "16th")
        XCTAssertEqual(quintillo.buscar("actual-notes").first?.entero, 5)
        XCTAssertEqual(quintillo.buscar("normal-notes").first?.entero, 4)
    }

    func testAnacrusa() throws {
        let raiz = leer(try Voz(leyendo: "Sol4:4 Do5:2 Re5:4 Mi5:2", compas: "3/4", anacrusa: .negra).musicXML())
        let compases = raiz.buscar("measure")
        XCTAssertEqual(compases.map { $0.atributos["number"] }, ["0", "1", "2"])
        XCTAssertEqual(compases.map { $0.atributos["implicit"] }, ["yes", nil, nil])
        XCTAssertEqual(duraciones(raiz), [1, 3, 2])
    }

    func testArmaduraYClave() throws {
        let voz = try Voz(leyendo: "Re4:4 Mi4:4 Fa#4:4 Sol4:4 La4:4 Si4:4 Do#5:4 Re5:4")
        let raiz = leer(voz.musicXML())
        XCTAssertEqual(raiz.buscar("fifths").first?.entero, 2)   // estimada: Re mayor
        XCTAssertEqual(leer(voz.musicXML(tonalidad: Tonalidad(.si, .menor))).buscar("mode").first?.texto, "minor")
        XCTAssertEqual(leer(voz.musicXML(tonalidad: Tonalidad(Nota(.mi, .bemol)))).buscar("fifths").first?.entero, -3)

        let grave = try Voz(leyendo: "Do2:4 Sol2:4 Mi3:2")
        XCTAssertEqual(leer(grave.musicXML()).buscar("sign").first?.texto, "F")
        let esperado: [Clave: (String, Int, Int?)] = [
            .sol: ("G", 2, nil), .solOctavaBaja: ("G", 2, -1), .solOctavaAlta: ("G", 2, 1), .fa: ("F", 4, nil),
            .faEnTercera: ("F", 3, nil), .doEnPrimera: ("C", 1, nil), .doEnSegunda: ("C", 2, nil),
            .doEnTercera: ("C", 3, nil), .doEnCuarta: ("C", 4, nil),
        ]
        for clave in Clave.allCases {
            let elemento = try XCTUnwrap(leer(voz.musicXML(clave: clave)).buscar("clef").first)
            let (signo, linea, cambio) = try XCTUnwrap(esperado[clave])
            XCTAssertEqual(elemento["sign"]?.texto, signo, "\(clave)")
            XCTAssertEqual(elemento["line"]?.entero, linea, "\(clave)")
            XCTAssertEqual(elemento["clef-octave-change"]?.entero, cambio, "\(clave)")
        }
    }

    func testCompasesYTempo() throws {
        let voz = try Voz(leyendo: "Do4:4. Re4:4.", compas: "6/8")
        let raiz = leer(voz.musicXML(tempo: Tempo(60, unidad: Duracion(.negra, puntillos: 1))))
        XCTAssertEqual(raiz.buscar("beats").first?.texto, "6")
        XCTAssertNil(raiz.buscar("time").first?.atributos["symbol"])
        XCTAssertEqual(raiz.buscar("beat-unit").first?.texto, "quarter")
        XCTAssertEqual(raiz.buscar("beat-unit-dot").count, 1)
        XCTAssertEqual(raiz.buscar("per-minute").first?.texto, "60")
        XCTAssertEqual(raiz.buscar("sound").first?.atributos["tempo"], "90")
        XCTAssertEqual(leer(try Voz(leyendo: "Do4:1").musicXML()).buscar("time").first?.atributos["symbol"], "common")
        XCTAssertEqual(leer(try Voz(leyendo: "Do4:1", compas: "2/2").musicXML()).buscar("time").first?.atributos["symbol"], "cut")
        XCTAssertEqual(leer(try Voz(leyendo: "Do4:8 Re4:8 Mi4:8 Fa4:8 Sol4:4.", compas: "3+2+2/8").musicXML())
            .buscar("beats").first?.texto, "3+2+2")
    }

    func testTextoEscapado() throws {
        let raiz = leer(try Voz(leyendo: "Do4:1").musicXML(titulo: "Do & Re <\"1\">", parte: "Flauta & voz"))
        XCTAssertEqual(raiz["work"]?["work-title"]?.texto, "Do & Re <\"1\">")
        XCTAssertEqual(raiz.buscar("part-name").first?.texto, "Flauta & voz")
    }

    func testCoral() throws {
        let coral = try ConduccionDeVoces(leyendo: "Do3 Mi4 Sol4 Do5 | Fa3 Fa4 La4 Do5 | Sol2 Re4 Sol4 Si4 | Do3 Mi4 Sol4 Do5")
        let raiz = leer(coral.musicXML(duracion: .blanca, titulo: "Cadencia"))
        XCTAssertEqual(raiz.buscar("staves").first?.entero, 2)
        XCTAssertEqual(raiz.buscar("clef").map { $0["sign"]?.texto }, ["G", "F"])
        XCTAssertEqual(raiz.buscar("clef").map { $0.atributos["number"] }, ["1", "2"])
        XCTAssertEqual(raiz.buscar("fifths").first?.entero, 0)
        XCTAssertEqual(raiz.buscar("measure").count, 2)
        // Soprano y contralto arriba; tenor y bajo abajo; las plicas, según la voz.
        let notas = raiz.buscar("note")
        for (voz, indice, pentagrama, plica) in [("1", 3, "1", "up"), ("2", 2, "1", "down"),
                                                  ("3", 1, "2", "up"), ("4", 0, "2", "down")] {
            let deLaVoz = notas.filter { $0["voice"]?.texto == voz }
            XCTAssertEqual(deLaVoz.compactMap(altura), coral.voz(indice), "voz \(voz)")
            XCTAssertEqual(Set(deLaVoz.map { $0["staff"]?.texto }), [pentagrama], "voz \(voz)")
            XCTAssertEqual(Set(deLaVoz.map { $0["stem"]?.texto }), [plica], "voz \(voz)")
            XCTAssertEqual(duraciones(raiz, voz: voz), [4, 4], "voz \(voz)")
        }
        // Tres retrocesos por compás, de un compás entero cada uno.
        XCTAssertEqual(raiz.buscar("backup").map { $0["duration"]?.entero }, Array(repeating: 4, count: 6))
    }

    func testCoralAcabaEnLaBarra() throws {
        // Cinco negras en 4/4: el último acorde, solo en el segundo compás, se alarga a redonda.
        let coral = try ConduccionDeVoces(leyendo: "Do3 Mi4 Sol4 Do5, La2 Mi4 La4 Do5, Re3 Fa4 La4 Re5, Sol2 Re4 Sol4 Si4, Do3 Mi4 Sol4 Do5")
        let raiz = leer(coral.musicXML())
        XCTAssertEqual(duraciones(raiz, voz: "1"), [4, 4])
        XCTAssertEqual(raiz.buscar("measure").last?.todos("note").map { $0["type"]?.texto }, Array(repeating: "whole", count: 4))
        let seis = leer(try ConduccionDeVoces(leyendo: "Do3 Do5, Sol2 Si4, Do3 Do5, Do3 Do5, Sol2 Si4, Do3 Do5")
            .musicXML(compas: "4/4"))
        XCTAssertEqual(seis.buscar("measure").last?.todos("note").map { $0["type"]?.texto },
                       ["quarter", "quarter", "half", "quarter", "quarter", "half"])
        // En 6/8, de corchea en corchea: el último se completa con figuras ligadas si hace falta.
        let seisPorOcho = leer(try ConduccionDeVoces(leyendo: "Do3 Do5, Sol2 Si4, Do3 Do5, Do3 Do5")
            .musicXML(duracion: .corchea, compas: "6/8"))
        XCTAssertEqual(duraciones(seisPorOcho, voz: "1"), [6])
        XCTAssertEqual(leer(coral.musicXML(compas: "5/4")).buscar("measure").count, 1)
    }

    func testCoralDeDosVoces() throws {
        let raiz = leer(try ConduccionDeVoces(leyendo: "Do3 Do5, Si2 Re5, Do3 Mi5").musicXML(compas: "3/4"))
        let notas = raiz.buscar("note")
        XCTAssertEqual(notas.filter { $0["staff"]?.texto == "1" }.compactMap(altura), ["Do5", "Re5", "Mi5"])
        XCTAssertEqual(notas.filter { $0["staff"]?.texto == "2" }.compactMap(altura), ["Do3", "Si2", "Do3"])
        XCTAssertTrue(raiz.buscar("stem").isEmpty)   // una voz por pentagrama: plicas libres
    }

    /// Voces al azar (con semilla fija): cada compás completo dura lo que el compás, las alturas
    /// vuelven intactas y las ligaduras se abren y se cierran por parejas.
    func testVocesAlAzar() throws {
        var azar = GeneradorConSemilla(semilla: 2026)
        let figuras: [Duracion] = [.redonda, .blanca, .negra, .corchea, .semicorchea, Duracion(3, 8), Duracion(3, 16),
                                      Duracion(5, 8), Duracion(1, 12), Duracion(1, 6), Duracion(1, 20)]
        let compases: [Compas] = ["4/4", "3/4", "2/4", "6/8", "9/8", "5/8", "7/8", "2/2", "3/8", "12/8"]
        for _ in 0..<200 {
            let compas = compases.randomElement(using: &azar)!
            var eventos: [Evento] = []
            for _ in 0..<Int.random(in: 1...16, using: &azar) {
                let duracion = figuras.randomElement(using: &azar)!
                let cuantas = Int.random(in: 0...3, using: &azar)
                let alturas = (0..<cuantas).map { _ in
                    // MusicXML admite las octavas de 0 a 9.
                    Altura(Nota(pasosDeQuinta: Int.random(in: -12...12, using: &azar)), octava: Int.random(in: 0...9, using: &azar))
                }
                eventos.append(Evento(alturas: alturas, duracion: duracion, ligada: Bool.random(using: &azar)))
            }
            let anacrusa = Bool.random(using: &azar) ? Duracion(1, compas.denominador) : .cero
            let voz = Voz(eventos, compas: compas, anacrusa: anacrusa)
            let raiz = leer(voz.musicXML(), line: #line)
            let contexto = voz.eventos.map(\.description).joined(separator: " ") + " en \(compas)"
            let divisiones = try XCTUnwrap(raiz.buscar("divisions").first?.entero)
            let porCompas = (compas.duracion * 4 * divisiones).numerador
            let medidas = duraciones(raiz)
            for (i, medida) in medidas.enumerated().dropLast() {
                XCTAssertEqual(medida, i == 0 && anacrusa > .cero ? (anacrusa * 4 * divisiones).numerador : porCompas, contexto)
            }
            XCTAssertEqual(medidas.reduce(0, +), (voz.duracion * 4 * divisiones).numerador, contexto)
            XCTAssertEqual(raiz.buscar("pitch").count, voz.grafia.joined().map(\.alturas.count).reduce(0, +), contexto)
            let sonando = raiz.buscar("note").compactMap(altura)
            XCTAssertEqual(sonando, voz.grafia.joined().flatMap(\.alturas), contexto)
            XCTAssertNil(raiz.buscar("type").first { $0.texto.isEmpty }, contexto)
        }
    }

    func testProgresion() throws {
        let analisis = try AnalisisArmonico.analizar(leyendo: "Do Lam Re7 Sol7/Si Do")
        let raiz = leer(analisis.musicXML(titulo: "Progresión"))
        XCTAssertEqual(raiz.buscar("staves").first?.entero, 2)
        XCTAssertEqual(raiz.buscar("words").first?.texto, "Do mayor:")
        let armonias = raiz.buscar("harmony")
        XCTAssertEqual(armonias.map { $0["root"]?["root-step"]?.texto }, ["C", "A", "D", "G", "C"])
        XCTAssertEqual(armonias.map { $0["kind"]?.texto }, ["major", "minor", "dominant", "dominant", "major"])
        XCTAssertEqual(armonias.map { $0["kind"]?.atributos["text"] }, ["", "m", "7", "7", ""])
        XCTAssertEqual(armonias[3]["bass"]?["bass-step"]?.texto, "B")
        XCTAssertEqual(Set(armonias.map { $0["staff"]?.texto }), ["1"])
        let notas = raiz.buscar("note")
        // Arriba, los acordes en posición cerrada; abajo, el bajo con el análisis.
        let arriba = notas.filter { $0["staff"]?.texto == "1" }
        XCTAssertEqual(arriba.prefix(3).compactMap(altura), ["Do4", "Mi4", "Sol4"])
        let bajo = notas.filter { $0["staff"]?.texto == "2" }
        XCTAssertEqual(bajo.compactMap(altura), ["Do3", "La2", "Re3", "Si2", "Do3"])
        XCTAssertEqual(bajo.map { $0.todos("lyric").map { $0["text"]!.texto } },
                       [["I", "T"], ["vi", "T"], ["V7/V", "D"], ["V65", "D"], ["I", "T"]])
        XCTAssertEqual(duraciones(raiz, voz: "1"), [4, 4, 4])   // el último, redonda
        // Sin cifrados ni análisis, en inglés.
        let simple = leer(analisis.musicXML(cifrados: false, analisis: false))
        XCTAssertTrue(simple.buscar("harmony").isEmpty)
        XCTAssertTrue(simple.buscar("lyric").isEmpty)
        XCTAssertTrue(simple.buscar("words").isEmpty)
        XCTAssertEqual(leer(analisis.musicXML(notacion: .ingles)).buscar("words").first?.texto, "C major:")
        let menor = leer(try AnalisisArmonico.analizar(leyendo: "Lam Sib/Re Mi7 Lam").musicXML())
        XCTAssertEqual(menor.buscar("mode").first?.texto, "minor")
        XCTAssertEqual(menor.buscar("harmony")[1]["root"]?["root-alter"]?.entero, -1)
        XCTAssertEqual(menor.buscar("harmony")[1]["bass"]?["bass-step"]?.texto, "D")
    }

    /// Cada tipo de acorde se escribe con una especie de MusicXML y unos grados que, juntos, dan
    /// exactamente sus intervalos.
    func testEspeciesYGrados() throws {
        let mayor = [0, 2, 4, 5, 7, 9, 11]
        for tipo in TipoDeAcorde.todos {
            let acorde = Acorde(.do, tipo)
            let armonia = try XCTUnwrap(ElementoXML.leer(EscritorMusicXML.armonia(acorde, .espanol, pentagrama: nil)))
            let especie = try XCTUnwrap(armonia["kind"]?.texto)
            XCTAssertNotEqual(especie, "other", "\(tipo)")
            var intervalos = Set(try XCTUnwrap(EscritorMusicXML.especies.first { $0.nombre == especie }).intervalos.map { "\($0.0),\($0.1)" })
            for grado in armonia.todos("degree") {
                let numero = try XCTUnwrap(grado["degree-value"]?.entero)
                let semitonos = mayor[(numero - 1) % 7] + (grado["degree-alter"]?.entero ?? 0)
                let clave = "\((numero - 1) % 7 + 1),\(semitonos)"
                if grado["degree-type"]?.texto == "add" { intervalos.insert(clave) } else { intervalos.remove(clave) }
            }
            let esperados = Set(tipo.intervalos.filter { $0.numero != 1 }.map { "\($0.numeroSimple),\(modulo($0.semitonos, 12))" })
            XCTAssertEqual(intervalos, esperados, "\(tipo)")
            XCTAssertEqual(armonia["kind"]?.atributos["text"], tipo.cifrado, "\(tipo)")
        }
        let novenaMenor = try XCTUnwrap(ElementoXML.leer(EscritorMusicXML.armonia("Sol7(b9)", .ingles, pentagrama: nil)))
        XCTAssertEqual(novenaMenor["kind"]?.texto, "dominant")
        XCTAssertEqual(novenaMenor["degree"]?["degree-value"]?.entero, 9)
        XCTAssertEqual(novenaMenor["degree"]?["degree-alter"]?.entero, -1)
        XCTAssertEqual(novenaMenor["degree"]?["degree-type"]?.texto, "add")
        XCTAssertEqual(novenaMenor["kind"]?.atributos["text"], "7(b9)")
        // Las sextas aumentadas tienen especie propia, sin grados.
        for (cifrado, especie) in [("Lab(#6,omit5)", "Italian"), ("Lab(#6,#11,omit5)", "French"), ("Lab(#6)", "German")] {
            let armonia = try XCTUnwrap(ElementoXML.leer(EscritorMusicXML.armonia(Acorde(texto: cifrado)!, .espanol, pentagrama: nil)))
            XCTAssertEqual(armonia["kind"]?.texto, especie)
            XCTAssertTrue(armonia.todos("degree").isEmpty, cifrado)
        }
    }

    func testCoralConAnalisis() throws {
        let coral = try ConduccionDeVoces(leyendo: "Do3 Mi4 Sol4 Do5 | Fa3 Fa4 La4 Do5 | Sol2 Re4 Sol4 Si4 | Do3 Reb4 Re4 Mib4 | Do3 Mi4 Sol4 Do5")
        XCTAssertTrue(leer(coral.musicXML()).buscar("harmony").isEmpty)
        let raiz = leer(coral.musicXML(cifrados: true, analisis: true))
        // Do Re♭ Re Mi♭ no es un acorde conocido: se queda sin cifrar.
        let armonias = raiz.buscar("harmony")
        XCTAssertEqual(armonias.map { $0["root"]?["root-step"]?.texto }, ["C", "F", "G", "C"])
        let notas = raiz.buscar("note")
        let soprano = notas.filter { $0["voice"]?.texto == "1" }
        XCTAssertEqual(soprano.compactMap(altura), coral.voz(3))
        let bajo = notas.filter { $0["voice"]?.texto == "4" }
        XCTAssertEqual(bajo.map { $0.todos("lyric").first?["text"]?.texto }, ["I", "IV", "V", nil, "I"])
        XCTAssertEqual(raiz.buscar("words").first?.texto, "Do mayor:")
        // Los cifrados van antes de la nota del soprano de cada acorde (el 4.º, sin cifrar).
        let primerCompas = try XCTUnwrap(raiz.buscar("measure").first)
        let orden = primerCompas.hijos.map(\.nombre).filter { $0 == "harmony" || $0 == "note" || $0 == "backup" }
        XCTAssertEqual(Array(orden.prefix(8)), ["harmony", "note", "harmony", "note", "harmony", "note", "note", "backup"])
        XCTAssertEqual(leer(coral.musicXML(tonalidad: Tonalidad(.sol), analisis: true)).buscar("lyric").first?["text"]?.texto, "IV")
    }

    func testDivisiones() {
        XCTAssertEqual(Exportacion.divisiones([.negra, .blanca]), 1)
        XCTAssertEqual(Exportacion.divisiones([.corchea, Duracion(.negra, puntillos: 1)]), 2)
        XCTAssertEqual(Exportacion.divisiones([Duracion(1, 12), .semicorchea]), 12)
        XCTAssertEqual(Exportacion.divisiones([Duracion(1, 20), Duracion(1, 12)]), 15)
        XCTAssertEqual(Exportacion.divisiones([.cuadrada, .cero]), 1)
    }
}
