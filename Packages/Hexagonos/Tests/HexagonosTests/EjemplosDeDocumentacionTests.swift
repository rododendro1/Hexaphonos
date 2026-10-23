import XCTest
import Hexagonos

/// Los resultados que la documentación (DocC y comentarios) promete en sus ejemplos.
final class EjemplosDeDocumentacionTests: XCTestCase {
    func testPortada() {
        let a = CoordenadaAxial(q: 1, r: -2)
        XCTAssertEqual(a.vecinos.count, 6)
        XCTAssertEqual(a.distancia(a: .origen), 2)
        XCTAssertEqual(a.linea(hasta: CoordenadaAxial(q: 4, r: -2)).count, 4)
        XCTAssertEqual(a.desplazada(.filasImpares), CoordenadaDesplazada(columna: 0, fila: -2))
        XCTAssertEqual(a.s, 1)
        XCTAssertEqual(a + CoordenadaAxial(q: 0, r: 1), CoordenadaAxial(q: 1, r: -1))
    }

    func testSistemasDeCoordenadas() {
        let a = CoordenadaAxial(q: 2, r: -1)
        XCTAssertEqual(a.cubica, CoordenadaCubica(q: 2, r: -1, s: -1))
        let d = CoordenadaDesplazada(columna: 3, fila: 1)
        XCTAssertEqual(d.axial(.filasImpares), CoordenadaAxial(q: 3, r: 1))
        XCTAssertEqual(d.axial(.filasImpares).desplazada(.filasPares), CoordenadaDesplazada(columna: 4, fila: 1))
        XCTAssertEqual(CoordenadaAxial(q: 1, r: 2).doblada(.anchoDoble), CoordenadaDoblada(columna: 4, fila: 2))
        XCTAssertEqual(CoordenadaAxial(q: 1, r: 2).doblada(.altoDoble), CoordenadaDoblada(columna: 1, fila: 5))
        let c = CoordenadaCubica(q: 1, r: -3, s: 2)
        XCTAssertEqual(c.axial, CoordenadaAxial(q: 1, r: -3))
    }

    func testAlgoritmos() {
        XCTAssertEqual(CoordenadaAxial.origen.vecino(0), CoordenadaAxial(q: 1, r: 0))
        XCTAssertEqual(CoordenadaAxial.origen.distancia(a: CoordenadaAxial(q: 3, r: -7)), 7)
        XCTAssertEqual(CoordenadaAxial.origen.alcance(radio: 2).count, 19)
        XCTAssertEqual(CoordenadaAxial.origen.anillo(radio: 2).count, 12)
        XCTAssertEqual(CoordenadaAxial.origen.linea(hasta: CoordenadaAxial(q: 3, r: 0)),
                       [CoordenadaAxial(q: 0, r: 0), CoordenadaAxial(q: 1, r: 0),
                        CoordenadaAxial(q: 2, r: 0), CoordenadaAxial(q: 3, r: 0)])
    }

    func testPixeles() {
        let puntiaguda = Disposicion(orientacion: .puntiaguda, tamano: 10)
        XCTAssertEqual(puntiaguda.centro(de: CoordenadaAxial(q: 1, r: 0)).x, 17.3205, accuracy: 1e-4)
        XCTAssertEqual(puntiaguda.casilla(en: Punto(x: 17, y: 1)), CoordenadaAxial(q: 1, r: 0))
        let plana = Disposicion(orientacion: .plana, tamano: 20, origen: Punto(x: 200, y: 150))
        let centro = plana.centro(de: CoordenadaAxial(q: 1, r: 0))
        XCTAssertEqual(centro.x, 230, accuracy: 1e-9)
        XCTAssertEqual(centro.y, 167.3205, accuracy: 1e-4)
        XCTAssertEqual(plana.casilla(en: Punto(x: 231, y: 160)), CoordenadaAxial(q: 1, r: 0))
    }
}
