import XCTest
@testable import Armonia
@testable import ArmoniaNucleo
@testable import ArmoniaTeoria

final class CadenciasYModulacionesTests: XCTestCase {
    private func cadencias(_ texto: String, en tonalidad: Tonalidad? = nil) throws -> [Cadencia.Tipo] {
        try AnalisisArmonico.analizar(leyendo: texto, en: tonalidad).cadencias.map(\.tipo)
    }

    private func tonalidades(_ texto: String) throws -> [Tonalidad] {
        try RecorridoTonal(leyendo: texto).tramos.map(\.tonalidad)
    }

    // MARK: Cadencias

    func testCadencias() throws {
        XCTAssertEqual(try cadencias("Do Fa Sol7 Do"), [.autentica])
        XCTAssertEqual(try cadencias("Do Fa Do"), [.plagal])
        XCTAssertEqual(try cadencias("Do Fa Sol Lam", en: Tonalidad(.do)), [.rota])
        XCTAssertEqual(try cadencias("Do Lam Fa Sol", en: Tonalidad(.do)), [.semicadencia])
        XCTAssertEqual(try cadencias("Lam Rem Mi7 Lam"), [.autentica])
        XCTAssertEqual(try cadencias("Lam Rem/Fa Mi", en: Tonalidad(.la, .menor)), [.semicadencia])
        XCTAssertEqual(try cadencias("Lam Mi7 Fa", en: Tonalidad(.la, .menor)), [.rota])
        // Rota con el ♭VI prestado en mayor.
        XCTAssertEqual(try cadencias("Do Sol7 Lab", en: Tonalidad(.do)), [.rota])
        // El I64 cadencial no cierra: la cadencia es la de después.
        XCTAssertEqual(try cadencias("Do Fa Do/Sol Sol7 Do", en: Tonalidad(.do)), [.autentica])
        // Una semicadencia solo al final.
        XCTAssertEqual(try cadencias("Do Sol Lam Fa Sol Do", en: Tonalidad(.do)), [.rota, .autentica])
        // Con la sensible.
        XCTAssertEqual(try cadencias("Do Sim°/Re Do/Mi", en: Tonalidad(.do)), [.autentica])
        XCTAssertEqual(try cadencias("Do Lam Rem Mim"), [])
    }

    func testCadenciaPerfectaEImperfecta() throws {
        let perfecta = try AnalisisArmonico.analizar(leyendo: "Do Fa Sol7 Do").cadencias[0]
        XCTAssertTrue(perfecta.esPerfecta)
        XCTAssertEqual(perfecta.acorde, 2)
        XCTAssertEqual(perfecta.acordes.map(\.cifrado), ["V7", "I"])
        XCTAssertEqual(perfecta.description, "Cadencia auténtica V7–I (acordes 3 → 4)")
        XCTAssertEqual(perfecta.descripcion(en: .ingles), "Authentic cadence V7–I (chords 3 → 4)")
        let imperfecta = try AnalisisArmonico.analizar(leyendo: "Do Fa Sol7/Si Do", en: Tonalidad(.do)).cadencias[0]
        XCTAssertFalse(imperfecta.esPerfecta)
        XCTAssertEqual(Cadencia.Tipo.semicadencia.nombre(en: .ingles), "half cadence")
        XCTAssertEqual(Cadencia.Tipo.rota.nombre, "cadencia rota")
    }

    // MARK: Modulaciones

    func testModulacionALaDominante() throws {
        let recorrido = try RecorridoTonal(leyendo: "Do Fa Sol7 Do Lam Re7 Sol")
        XCTAssertEqual(recorrido.tramos.map(\.tonalidad), [Tonalidad(.do), Tonalidad(.sol)])
        XCTAssertEqual(recorrido.tramos.map(\.indices), [0..<4, 4..<7])
        XCTAssertEqual(recorrido.cifrados, ["I", "IV", "V7", "I", "ii", "V7", "I"])
        let modulacion = try XCTUnwrap(recorrido.modulaciones.first)
        XCTAssertEqual(modulacion.acorde, 4)
        let pivote = try XCTUnwrap(modulacion.pivote)
        XCTAssertEqual(pivote.indice, 4)
        XCTAssertEqual(pivote.description, "Lam = vi en Do mayor = ii en Sol mayor")
        XCTAssertEqual(pivote.descripcion(en: .ingles), "Am = vi in C major = ii in G major")
        XCTAssertEqual(modulacion.description,
                       "De Do mayor a Sol mayor en el acorde 5 (pivote: Lam = vi en Do mayor = ii en Sol mayor)")
        XCTAssertEqual(recorrido.description, "I–IV–V7–I en Do mayor → ii–V7–I en Sol mayor")
        XCTAssertEqual(recorrido.cadencias.map(\.tipo), [.autentica, .autentica])
        XCTAssertEqual(recorrido.cadencias.map(\.tonalidad), [Tonalidad(.do), Tonalidad(.sol)])
        XCTAssertEqual(recorrido.cadencias.map(\.acorde), [2, 5])
    }

    func testModulacionALaRelativa() throws {
        let recorrido = try RecorridoTonal(leyendo: "Do Sol Do Fa Rem Mi7 Lam")
        XCTAssertEqual(recorrido.tramos.map(\.tonalidad), [Tonalidad(.do), Tonalidad(.la, .menor)])
        XCTAssertEqual(recorrido.modulaciones.first?.pivote?.description, "Rem = ii en Do mayor = iv en La menor")
        XCTAssertEqual(recorrido.cifrados.suffix(3), ["iv", "V7", "i"])
    }

    func testDeMenorASuRelativa() throws {
        XCTAssertEqual(try tonalidades("Lam Rem Mi7 Lam Do Fa Sol7 Do"), [Tonalidad(.la, .menor), Tonalidad(.do)])
    }

    func testIdaYVuelta() throws {
        let recorrido = try RecorridoTonal(leyendo: "Do Fa Sol7 Do Lam Re7 Sol Mim Sim Do Re7 Sol Sol7 Do Fa Sol7 Do")
        XCTAssertEqual(recorrido.tramos.map(\.tonalidad), [Tonalidad(.do), Tonalidad(.sol), Tonalidad(.do)])
        XCTAssertEqual(recorrido.modulaciones.count, 2)
    }

    func testTonicalizacionNoEsModulacion() throws {
        // Las dominantes secundarias que resuelven no cambian la tonalidad.
        XCTAssertEqual(try tonalidades("Do Lam Re7 Sol7 Do"), [Tonalidad(.do)])
        XCTAssertEqual(try tonalidades("Do La7 Rem Sol7 Do"), [Tonalidad(.do)])
        XCTAssertEqual(try tonalidades("Do Mi7 Lam Re7 Sol7 Do"), [Tonalidad(.do)])
        XCTAssertEqual(try tonalidades("Do Fa Sol Do"), [Tonalidad(.do)])
        let unico = try RecorridoTonal(leyendo: "Do Lam Re7 Sol7 Do")
        XCTAssertEqual(unico.modulaciones, [])
        XCTAssertEqual(unico.tramos[0].analisis, try AnalisisArmonico.analizar(leyendo: "Do Lam Re7 Sol7 Do"))
    }

    func testRecorridoCorto() throws {
        XCTAssertNil(RecorridoTonal([]))
        XCTAssertEqual(try tonalidades("Sol7 Do"), [Tonalidad(.do)])
    }
}
