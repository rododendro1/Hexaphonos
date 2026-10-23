import Foundation
import XCTest
@testable import Armonia
@testable import ArmoniaNucleo
@testable import ArmoniaTeoria
@testable import ArmoniaRepresentaciones
@testable import ArmoniaPartitura

final class MIDITests: XCTestCase {
    /// Lo que se lee de un fichero MIDI: divisiones, pistas y, por pista, notas y metaeventos.
    struct Leido {
        var formato = 0
        var divisiones = 0
        var pistas: [Pista] = []
        struct Pista {
            var notas: [(clave: Int, desde: Int, hasta: Int, canal: Int)] = []
            var metas: [(tiempo: Int, tipo: UInt8, datos: [UInt8])] = []
            var programa: Int?
            var texto: (UInt8) -> [String] { { tipo in self.metas.filter { $0.tipo == tipo }.map { String($0.datos.map { Character(Unicode.Scalar($0)) }) } } }
        }
    }

    /// Un lector mínimo, para comprobar lo que se escribe (y que los fragmentos encajan).
    func leer(_ datos: Data, file: StaticString = #filePath, line: UInt = #line) throws -> Leido {
        let b = [UInt8](datos)
        var i = 0
        func entero(_ n: Int) -> Int { defer { i += n }; return b[i..<i + n].reduce(0) { $0 << 8 | Int($1) } }
        func variable() -> Int {
            var valor = 0
            while true { let x = b[i]; i += 1; valor = valor << 7 | Int(x & 0x7F); if x & 0x80 == 0 { return valor } }
        }
        var leido = Leido()
        XCTAssertEqual(Array(b[0..<4]), Array("MThd".utf8), file: file, line: line); i = 4
        XCTAssertEqual(entero(4), 6)
        leido.formato = entero(2)
        let n = entero(2)
        leido.divisiones = entero(2)
        for _ in 0..<n {
            XCTAssertEqual(Array(b[i..<i + 4]), Array("MTrk".utf8), file: file, line: line); i += 4
            let fin = entero(4) + i
            var pista = Leido.Pista()
            var ahora = 0
            var abiertas: [Int: Int] = [:]
            var terminada = false
            while i < fin {
                ahora += variable()
                let estado = b[i]; i += 1
                if estado == 0xFF {
                    let tipo = b[i]; i += 1
                    let largo = variable()
                    pista.metas.append((ahora, tipo, Array(b[i..<i + largo]))); i += largo
                    if tipo == 0x2F { terminada = true }
                } else if estado & 0xF0 == 0xC0 {
                    pista.programa = Int(b[i]); i += 1
                } else if estado & 0xF0 == 0x90 {
                    abiertas[Int(b[i])] = ahora; i += 2
                } else if estado & 0xF0 == 0x80 {
                    let clave = Int(b[i]); i += 2
                    let desde = try XCTUnwrap(abiertas.removeValue(forKey: clave), file: file, line: line)
                    pista.notas.append((clave, desde, ahora, Int(estado & 0x0F)))
                } else {
                    XCTFail("mensaje inesperado \(estado)", file: file, line: line); break
                }
            }
            XCTAssertTrue(terminada && i == fin && abiertas.isEmpty, file: file, line: line)
            leido.pistas.append(pista)
        }
        XCTAssertEqual(i, b.count, file: file, line: line)
        return leido
    }

    func testMelodia() throws {
        let voz = try Voz(leyendo: "Do4:4 Re4:8 Mi4:8~ Mi4:4 -:4 Sol4+Si4:2", compas: "3/4")
        let leido = try leer(voz.midi(tonalidad: Tonalidad(.do), tempo: Tempo(90), titulo: "Prueba"))
        XCTAssertEqual(leido.formato, 1)
        XCTAssertEqual(leido.divisiones, 480)
        XCTAssertEqual(leido.pistas.count, 2)
        let control = leido.pistas[0]
        XCTAssertEqual(control.texto(0x03), ["Prueba"])
        // 90 negras por minuto: 666 667 µs por negra.
        XCTAssertEqual(control.metas.first { $0.tipo == 0x51 }?.datos, [0x0A, 0x2C, 0x2B])
        XCTAssertEqual(control.metas.first { $0.tipo == 0x58 }?.datos, [3, 2, 24, 8])
        XCTAssertEqual(control.metas.first { $0.tipo == 0x59 }?.datos, [0, 0])   // Do mayor
        let notas = leido.pistas[1].notas.sorted { ($0.desde, $0.clave) < ($1.desde, $1.clave) }
        // La ligadura suena como una nota; el silencio deja un hueco; el acorde, dos notas a la vez.
        XCTAssertEqual(notas.map(\.clave), [60, 62, 64, 67, 71])
        XCTAssertEqual(notas.map(\.desde), [0, 480, 720, 1920, 1920])
        XCTAssertEqual(notas.map(\.hasta), [480, 720, 1440, 2880, 2880])
        XCTAssertEqual(leido.pistas[1].texto(0x03), ["Voz"])
        XCTAssertEqual(leido.pistas[1].programa, 0)
    }

    func testTresillosYCompuestos() throws {
        // Tresillos y quintillos: divisiones que los hacen enteros.
        let voz = try Voz(leyendo: "Do4:1/12 Re4:1/12 Mi4:1/12 Fa4:1/20 Sol4:1/20 La4:1/20 Si4:1/20 Do5:1/20 Re5:2")
        let leido = try leer(voz.midi())
        XCTAssertEqual(leido.divisiones % 15, 0)
        let notas = leido.pistas[1].notas.sorted { $0.desde < $1.desde }
        XCTAssertEqual(notas.count, 9)
        XCTAssertEqual(notas[3].desde, leido.divisiones)
        XCTAssertEqual(notas.last?.desde, 2 * leido.divisiones)
        for (una, otra) in zip(notas, notas.dropFirst()) { XCTAssertEqual(una.hasta, otra.desde) }
        // Sin tempo, negra = 120; en 6/8, el pulso es la negra con puntillo (36 relojes).
        let seis = try leer(Voz(leyendo: "Do4:4. Re4:4.", compas: "6/8").midi(tonalidad: Tonalidad(.mi, .menor)))
        XCTAssertEqual(seis.pistas[0].metas.first { $0.tipo == 0x51 }?.datos, [0x07, 0xA1, 0x20])
        XCTAssertEqual(seis.pistas[0].metas.first { $0.tipo == 0x58 }?.datos, [6, 3, 36, 8])
        XCTAssertEqual(seis.pistas[0].metas.first { $0.tipo == 0x59 }?.datos, [1, 1])   // un sostenido, menor
        // Fuera del rango MIDI, se omite.
        let grave = try leer(Voz(leyendo: "La9:4 Do4:4").midi())
        XCTAssertEqual(grave.pistas[1].notas.map(\.clave), [60])
    }

    func testCoral() throws {
        let coral = try ConduccionDeVoces(leyendo: "Do3 Mi4 Sol4 Do5 | Sol2 Re4 Sol4 Si4 | Do3 Mi4 Sol4 Do5")
        let leido = try leer(coral.midi(duracion: .blanca, tempo: Tempo(60), titulo: "Cadencia"))
        XCTAssertEqual(leido.pistas.count, 5)
        XCTAssertEqual(leido.pistas.dropFirst().map { $0.texto(0x03).first }, ["soprano", "contralto", "tenor", "bajo"])
        XCTAssertEqual(leido.pistas[1].notas.map(\.clave), [72, 71, 72])
        // Sol4 se repite en el contralto: tres notas, no una ligada.
        XCTAssertEqual(leido.pistas[2].notas.count, 3)
        XCTAssertEqual(leido.pistas[4].notas.map(\.clave), [48, 43, 48])
        XCTAssertEqual(leido.pistas[4].notas.last?.hasta, 3 * 2 * leido.divisiones)
        XCTAssertEqual(Set(leido.pistas.dropFirst().compactMap(\.programa)), [52])
        // Cada voz, en su canal.
        XCTAssertEqual(leido.pistas.dropFirst().map { $0.notas.first?.canal }, [0, 1, 2, 3])
        let ingles = try leer(coral.midi(notacion: .ingles))
        XCTAssertEqual(ingles.pistas[1].texto(0x03), ["soprano"])
        XCTAssertEqual(ingles.pistas[4].texto(0x03), ["bass"])
    }

    func testProgresion() throws {
        let analisis = try AnalisisArmonico.analizar(leyendo: "Do Lam Re7 Sol7 Do")
        let leido = try leer(analisis.midi(tempo: Tempo(80)))
        XCTAssertEqual(leido.pistas.count, 3)
        XCTAssertEqual(leido.pistas[1].texto(0x06), ["Do · I", "Lam · vi", "Re7 · V7/V", "Sol7 · V7", "Do · I"])
        let primero = leido.pistas[1].notas.filter { $0.desde == 0 }.map(\.clave).sorted()
        XCTAssertEqual(primero, [60, 64, 67])
        XCTAssertEqual(leido.pistas[2].notas.map(\.clave), [48, 45, 50, 43, 48])
        XCTAssertEqual(leido.pistas[1].notas.count, 3 + 3 + 4 + 4 + 3)
        XCTAssertEqual(try leer(analisis.midi(notacion: .ingles)).pistas[1].texto(0x06).first, "C · I")
        // En Latin-1, con las alteraciones en ASCII.
        let prestado = try leer(AnalisisArmonico.analizar(leyendo: "Do Lab Sib Do").midi(titulo: "Préstamo"))
        XCTAssertEqual(prestado.pistas[1].texto(0x06), ["Do · I", "Lab · bVI", "Sib · bVII", "Do · I"])
        XCTAssertEqual(prestado.pistas[0].metas.first { $0.tipo == 0x03 }?.datos, [0x50, 0x72, 0xE9, 0x73, 0x74, 0x61, 0x6D, 0x6F])
        XCTAssertEqual(ArchivoMIDI.texto("Fa♯m · 𝄫 → ☃"), Array("Fa#m ".utf8) + [0xB7] + Array(" bb -> ?".utf8))
    }

    func testCantidadVariable() {
        XCTAssertEqual(ArchivoMIDI.cantidadVariable(0), [0x00])
        XCTAssertEqual(ArchivoMIDI.cantidadVariable(127), [0x7F])
        XCTAssertEqual(ArchivoMIDI.cantidadVariable(128), [0x81, 0x00])
        XCTAssertEqual(ArchivoMIDI.cantidadVariable(0x3FFF), [0xFF, 0x7F])
        XCTAssertEqual(ArchivoMIDI.cantidadVariable(0x200000), [0x81, 0x80, 0x80, 0x00])
    }
}
