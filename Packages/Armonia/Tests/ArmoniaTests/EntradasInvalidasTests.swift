import XCTest
@testable import Armonia
@testable import ArmoniaNucleo
@testable import ArmoniaTeoria
@testable import ArmoniaRepresentaciones
@testable import ArmoniaPartitura
@testable import ArmoniaTrastes

/// Lo que se hace con números que pueden venir de fuera: las variantes `init?(comprobando:)` devuelven `nil` en vez
/// de detener el programa, y donde un valor fuera de rango tiene una lectura clara, se toma esa.
final class EntradasInvalidasTests: XCTestCase {
    // MARK: Duración

    func testUnaDuracionConDenominadorCeroEsNil() {
        XCTAssertNil(Duracion(comprobando: 3, 0))
        XCTAssertNil(Duracion(comprobando: 0, 0))
    }

    func testUnaDuracionValidaEsLaMismaQueLaDelInicializadorNormal() {
        XCTAssertEqual(Duracion(comprobando: 3, 8), Duracion(3, 8))
        XCTAssertEqual(Duracion(comprobando: 6, 16), Duracion(3, 8))
        XCTAssertEqual(Duracion(comprobando: 0, 5), Duracion.cero)
    }

    func testLosPuntillosFueraDeRangoSonNil() {
        XCTAssertNil(Duracion(comprobando: .negra, puntillos: -1))
        XCTAssertNil(Duracion(comprobando: .negra, puntillos: 31))
        XCTAssertEqual(Duracion(comprobando: .negra, puntillos: 0), Duracion.negra)
        XCTAssertEqual(Duracion(comprobando: .negra, puntillos: 1), Duracion(3, 8))
        XCTAssertEqual(Duracion(comprobando: .negra, puntillos: 2), Duracion(7, 16))
        XCTAssertNotNil(Duracion(comprobando: .negra, puntillos: 30))
    }

    // MARK: Compás

    func testUnCompasInvalidoEsNil() {
        XCTAssertNil(Compas(comprobando: 0, 4))
        XCTAssertNil(Compas(comprobando: -3, 4))
        XCTAssertNil(Compas(comprobando: 3, 0))
        XCTAssertNil(Compas(comprobando: 3, 3))      // el denominador no es una potencia de 2
        XCTAssertNil(Compas(comprobando: 3, 128))    // más de 64
    }

    func testUnCompasValidoEsElMismoQueElDelInicializadorNormal() {
        XCTAssertEqual(Compas(comprobando: 3, 4), Compas(3, 4))
        XCTAssertEqual(Compas(comprobando: 6, 8), Compas(6, 8))
        XCTAssertEqual(Compas(comprobando: 7, 8), Compas(7, 8))
    }

    func testLaAgrupacionTieneQueSumarElNumerador() {
        XCTAssertEqual(Compas(comprobando: 6, 8, agrupacion: [3, 3]), Compas(6, 8, agrupacion: [3, 3]))
        XCTAssertEqual(Compas(comprobando: 7, 8, agrupacion: [2, 2, 3]), Compas(7, 8))
        XCTAssertNil(Compas(comprobando: 6, 8, agrupacion: [2, 2]))
        XCTAssertNil(Compas(comprobando: 6, 8, agrupacion: [0, 6]))
        XCTAssertNil(Compas(comprobando: 6, 8, agrupacion: [-3, 9]))
    }

    // MARK: Tempo

    func testUnTempoNoPositivoEsNil() {
        XCTAssertNil(Tempo(comprobando: 0))
        XCTAssertNil(Tempo(comprobando: -60))
        XCTAssertNil(Tempo(comprobando: .nan))
        XCTAssertNil(Tempo(comprobando: 100, unidad: .cero))
    }

    func testUnTempoValidoEsElMismoQueElDelInicializadorNormal() {
        XCTAssertEqual(Tempo(comprobando: 120), Tempo(120))
        XCTAssertEqual(Tempo(comprobando: 60, unidad: Duracion(.negra, puntillos: 1)),
                       Tempo(60, unidad: Duracion(.negra, puntillos: 1)))
    }

    // MARK: Base de Hewlett

    func testLaAlteracionMaximaNegativaSeTomaComoCero() {
        XCTAssertEqual(BaseDeHewlett(alteracionMaxima: -3).alteracionMaxima, 0)
        XCTAssertEqual(BaseDeHewlett(alteracionMaxima: 0).alteracionMaxima, 0)
        XCTAssertEqual(BaseDeHewlett(alteracionMaxima: 2), BaseDeHewlett.base40)
        XCTAssertEqual(BaseDeHewlett(base: 54)?.alteracionMaxima, 3)
    }
}
