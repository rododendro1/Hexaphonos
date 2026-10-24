import XCTest
import Armonia
@testable import ArmoniaCLI

final class ArgumentosTests: XCTestCase {
    func testMarcas() {
        var argumentos = Argumentos(["Sol7", "--diagrama", "Do", "--diagram"])
        XCTAssertTrue(argumentos.quitarMarca("--diagrama", "--diagram"))
        XCTAssertEqual(argumentos.restantes, ["Sol7", "Do"])
        XCTAssertFalse(argumentos.quitarMarca("--completo"))
    }

    func testOpciones() {
        var argumentos = Argumentos(["Sol7", "--instrument", "ukelele", "--limite"])
        XCTAssertEqual(argumentos.quitarOpcion("--instrumento", "--instrument"), .valor("ukelele"))
        XCTAssertEqual(argumentos.quitarOpcion("--limite", "--limit"), .sinValor(nombre: "limite"))
        XCTAssertEqual(argumentos.quitarOpcion("--dedos"), .ausente)
        XCTAssertEqual(argumentos.restantes, ["Sol7"])
        // Otra opción no es un valor.
        var seguidas = Argumentos(["--language", "--textos", "es"])
        XCTAssertEqual(seguidas.quitarOpcion("--idioma", "--language"), .sinValor(nombre: "language"))
        XCTAssertEqual(seguidas.opcionDesconocida, "--textos")
    }

    func testNumeros() {
        var argumentos = Argumentos(["Sol7", "--voces", "2"])
        XCTAssertEqual(argumentos.quitarNumero("--voces", "--voices", en: 1...2, porDefecto: 1), 2)
        XCTAssertEqual(argumentos.quitarNumero("--voces", "--voices", en: 1...2, porDefecto: 1), 1)
        XCTAssertEqual(argumentos.restantes, ["Sol7"])
        var fuera = Argumentos(["--voces", "3"])
        XCTAssertNil(fuera.quitarNumero("--voces", en: 1...2, porDefecto: 1))
        var sinNumero = Argumentos(["--voces"])
        XCTAssertNil(sinNumero.quitarNumero("--voces", en: 1...2, porDefecto: 1))
    }

    func testLaTonalidadSeLlevaElResto() throws {
        var argumentos = Argumentos(["Do", "Fa", "Sol7", "--en", "La", "menor"])
        XCTAssertEqual(try argumentos.quitarTonalidad(), .some(Tonalidad(.la, .menor)))
        XCTAssertEqual(argumentos.unidos, "Do Fa Sol7")
        var sinTonalidad = Argumentos(["Do"])
        XCTAssertEqual(try sinTonalidad.quitarTonalidad(), .some(nil))
        var alFinal = Argumentos(["Do", "--in"])
        XCTAssertNil(try alFinal.quitarTonalidad())
    }
}
