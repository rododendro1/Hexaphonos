import XCTest
@testable import Armonia
@testable import ArmoniaNucleo
@testable import ArmoniaTeoria
@testable import ArmoniaRepresentaciones
@testable import ArmoniaPartitura

final class ConduccionDeVocesTests: XCTestCase {
    private func problemas(_ texto: String, file: StaticString = #filePath, line: UInt = #line)
        -> [ProblemaDeConduccion.Tipo] {
        do {
            return try ConduccionDeVoces(leyendo: texto).problemas.map(\.tipo)
        } catch {
            XCTFail("«\(texto)»: \(error)", file: file, line: line)
            return []
        }
    }

    func testCadenciaCorrecta() throws {
        let c = try ConduccionDeVoces(leyendo: "Do3 Mi4 Sol4 Do5 | Fa3 Fa4 La4 Do5 | Sol2 Re4 Sol4 Si4 | Do3 Mi4 Sol4 Do5")
        XCTAssertEqual(c.problemas, [])
        XCTAssertTrue(c.esCorrecta)
        XCTAssertEqual(c.numeroDeVoces, 4)
        XCTAssertEqual(c.voz(3).map(\.nombre), ["Do5", "Do5", "Si4", "Do5"])
    }

    func testParalelas() throws {
        let c = try ConduccionDeVoces(leyendo: "Do3 Sol3 Mi4 Do5 | Re3 La3 Fa4 Re5")
        XCTAssertEqual(c.problemas.map(\.tipo), [.quintasParalelas, .octavasParalelas])
        XCTAssertEqual(c.problemas.map(\.voces), [[0, 1], [0, 3]])
        XCTAssertEqual(c.problemas.map(\.acorde), [0, 0])
        XCTAssertEqual(c.problemas.map(\.description), ["Quintas paralelas entre bajo y tenor (acordes 1 → 2)",
                                                         "Octavas paralelas entre bajo y soprano (acordes 1 → 2)"])
        XCTAssertEqual(c.problemas[0].descripcion(en: .ingles), "Parallel fifths between bass and tenor (chords 1 → 2)")
        // Por movimiento contrario también cuentan; el unísono es una octava.
        XCTAssertEqual(problemas("Do3 Sol3 Mi4 Do5 | Sol2 Re4 Sol4 Si4"), [.quintasParalelas])
        XCTAssertEqual(problemas("Do4 Do4 Sol4 | Re4 Re4 La4"), [.superposicion, .octavasParalelas, .quintasParalelas, .quintasParalelas])
        // Una quinta que se queda quieta no es paralela; una quinta disminuida tampoco cuenta.
        XCTAssertEqual(problemas("Do3 Sol3 Mi4 Do5 | Do3 Sol3 Fa4 La4"), [])
        XCTAssertEqual(problemas("Do4 Sol4 | Si3 Fa4"), [])
    }

    func testDirectas() {
        // Bajo y soprano suben a la vez y el soprano salta a la quinta o la octava.
        XCTAssertEqual(problemas("Mi3 Sol3 Do4 Sol4 | Fa3 La3 Do4 Do5"), [.quintasDirectas])
        XCTAssertEqual(problemas("Mi3 Sol3 Do4 Do5 | Fa3 Do4 La4 Fa5"), [.octavasDirectas])
        // Con el soprano por grado conjunto, no.
        XCTAssertEqual(problemas("La2 Mi4 La4 Si4 | Do3 Mi4 Sol4 Do5"), [])
    }

    func testCrucesYSuperposicion() {
        XCTAssertEqual(problemas("Do3 Sol4 Mi4 Do5"), [.cruceDeVoces])
        XCTAssertEqual(problemas("Do3 Mi3 Sol3 Do4 | Fa3 Fa3 La3 Do4"), [.superposicion])
        XCTAssertEqual(problemas("Do3 Mi3 Sol3 Do4 | Fa2 La3 Do4 Fa4").first, .superposicion)
    }

    func testSeparacionYTesitura() throws {
        XCTAssertEqual(problemas("Do3 Do4 Mi4 Sol5"), [.separacionExcesiva])
        // Entre bajo y tenor sí puede haber más de una octava.
        XCTAssertEqual(problemas("Do2 Mi3 Sol3 Do4"), [.fueraDeTesitura])
        let c = try ConduccionDeVoces(leyendo: "Do2 Mi3 Sol3 Do4")
        XCTAssertEqual(c.problemas[0].voces, [0])
        XCTAssertEqual(c.problemas[0].description, "Fuera de tesitura en bajo (acorde 1)")
        // Con otro número de voces no hay tesituras.
        XCTAssertEqual(problemas("Do2 Sol5 Do6"), [])
    }

    func testSaltos() throws {
        XCTAssertEqual(problemas("Fa3 Do4 La4 Fa5 | Sol#3 Si3 Mi4 Si4"), [.saltoNoMelodico])
        XCTAssertEqual(problemas("Do4 Do5 | Fa#4 Do5"), [.saltoNoMelodico])
        XCTAssertEqual(problemas("Do3 Do4 | Do3 Re5"), [.saltoNoMelodico])
        // Una octava justa, o un semitono cromático, sí son melódicos.
        XCTAssertEqual(problemas("Do3 Do4 | Do3 Do5"), [])
        XCTAssertEqual(problemas("Do3 Do4 | Do3 Do#4"), [])
        let c = try ConduccionDeVoces(leyendo: "Fa3 Do4 La4 Fa5 | Sol#3 Si3 Mi4 Si4")
        XCTAssertEqual(c.problemas[0].descripcion(en: .ingles), "Unmelodic leap in the bass (chords 1 → 2)")
    }

    func testConstruccion() throws {
        let acordes: [[Altura]] = [["Do3", "Mi4", "Sol4", "Do5"], ["Sol2", "Re4", "Sol4", "Si4"]]
        let porVoces: [[Altura]] = [["Do3", "Sol2"], ["Mi4", "Re4"], ["Sol4", "Sol4"], ["Do5", "Si4"]]
        XCTAssertEqual(ConduccionDeVoces(acordes), ConduccionDeVoces(voces: porVoces))
        XCTAssertEqual(try ConduccionDeVoces(leyendo: "C3 E4 G4 C5, G2 D4 G4 B4"), ConduccionDeVoces(acordes))
        XCTAssertNil(ConduccionDeVoces([]))
        XCTAssertNil(ConduccionDeVoces([["Do4"]]))
        XCTAssertNil(ConduccionDeVoces([["Do4", "Mi4"], ["Do4"]]))
        XCTAssertNil(ConduccionDeVoces(voces: [["Do4", "Re4"], ["Mi4"]]))
    }

    func testErrores() {
        XCTAssertThrowsError(try ConduccionDeVoces(leyendo: "Do3 Mi4 | Sol2 H4")) { error in
            let error = error as? ErrorDeLectura
            XCTAssertEqual(error?.posicion, 15)
            XCTAssertEqual(error?.texto, "Do3 Mi4 | Sol2 H4")
        }
        XCTAssertThrowsError(try ConduccionDeVoces(leyendo: "Do3 Mi4 | Sol2")) { error in
            guard case .vocesDistintas? = (error as? ErrorDeLectura)?.motivo else { return XCTFail("\(error)") }
        }
        XCTAssertThrowsError(try ConduccionDeVoces(leyendo: " | ")) { error in
            guard case .textoVacio? = (error as? ErrorDeLectura)?.motivo else { return XCTFail("\(error)") }
        }
    }
}
