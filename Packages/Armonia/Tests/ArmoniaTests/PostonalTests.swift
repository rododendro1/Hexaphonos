import XCTest
@testable import Armonia
@testable import ArmoniaNucleo
@testable import ArmoniaTeoria
@testable import ArmoniaRepresentaciones
@testable import ArmoniaPartitura

final class ConjuntoDeClasesTests: XCTestCase {
    func testFormasYNombres() {
        let mayor: ConjuntoDeClases = [0, 4, 7]
        XCTAssertEqual(mayor.formaPrima, [0, 3, 7])
        XCTAssertEqual(mayor.numeroDeForte, "3-11")
        XCTAssertEqual(mayor.vectorIntervalico, [0, 0, 1, 1, 1, 0])
        XCTAssertEqual(mayor.nombreComun, "tríada mayor o menor")
        XCTAssertEqual(ConjuntoDeClases([7, 0, 4]).formaNormal, [0, 4, 7])
        XCTAssertEqual(ConjuntoDeClases([11, 2, 7]).formaNormal, [7, 11, 2])
        XCTAssertEqual(ConjuntoDeClases([12, 16, 19, 4]), mayor)

        let quinto: ConjuntoDeClases = [0, 1, 3, 7, 8]
        XCTAssertEqual(quinto.formaPrima, [0, 1, 3, 7, 8])
        XCTAssertEqual(quinto.formaPrimaRahn, [0, 1, 5, 6, 8])
        XCTAssertEqual(quinto.numeroDeForte, "5-20")
        XCTAssertNil(ConjuntoDeClases([Int]()).numeroDeForte)
    }

    func testOperaciones() {
        let mayor: ConjuntoDeClases = [0, 4, 7]
        XCTAssertEqual(mayor.transponer(2), [2, 6, 9])
        XCTAssertEqual(mayor.invertir(), [0, 5, 8])
        XCTAssertTrue(mayor.esDeLaMismaClase(que: mayor.invertir(3)))
        XCTAssertEqual(Escala(.do).conjuntoDeClases.complemento.numeroDeForte, "5-35")
        XCTAssertTrue(ConjuntoDeClases([0, 4]).esSubconjunto(de: mayor))
        XCTAssertEqual(mayor.unir(con: [2]), [0, 2, 4, 7])
        XCTAssertEqual(mayor.intersecar(con: [4, 5, 7]), [4, 7])
    }

    func testRelacionZYSimetrias() {
        let a: ConjuntoDeClases = [0, 1, 4, 6]
        let b: ConjuntoDeClases = [0, 1, 3, 7]
        XCTAssertEqual(a.numeroDeForte, "4-Z15")
        XCTAssertEqual(b.numeroDeForte, "4-Z29")
        XCTAssertTrue(a.estaEnRelacionZ(con: b))
        XCTAssertFalse(a.estaEnRelacionZ(con: a.transponer(5)))
        XCTAssertEqual(ConjuntoDeClases([0, 4, 8]).simetriasPorTransposicion, 3)
        XCTAssertEqual(ConjuntoDeClases([0, 2, 4, 6, 8, 10]).simetriasPorTransposicion, 6)
        XCTAssertEqual(ConjuntoDeClases([0, 3, 6, 9]).simetriasPorInversion, 4)
        XCTAssertEqual(ConjuntoDeClases([0, 4, 7]).simetriasPorTransposicion, 1)
        XCTAssertEqual(ConjuntoDeClases([0, 4, 7]).simetriasPorInversion, 0)
    }

    func testIntegracion() {
        XCTAssertEqual(Escala(.re).conjuntoDeClases.numeroDeForte, "7-35")
        XCTAssertEqual(Escala(.do, .menorMelodica).conjuntoDeClases.numeroDeForte, "7-34")
        XCTAssertEqual(Escala(.do, .disminuida).conjuntoDeClases.numeroDeForte, "8-28")
        XCTAssertEqual(Acorde("Sol7").conjuntoDeClases.numeroDeForte, "4-27")
        XCTAssertEqual(Acorde("Sim7b5").conjuntoDeClases.numeroDeForte, "4-27")
        XCTAssertEqual(Acorde("Do°7").conjuntoDeClases.nombreComun, "séptima disminuida")
    }
}
