import Foundation
import XCTest
@testable import Hexagonos

/// Varios de los valores esperados son los de las pruebas de la guía de Red Blob Games
/// (https://www.redblobgames.com/grids/hexagons/implementation.html).
final class CoordenadaAxialTests: XCTestCase {
    func testLaTerceraCoordenadaHaceQueSumenCero() {
        let a = CoordenadaAxial(q: 3, r: -7)
        XCTAssertEqual(a.s, 4)
        XCTAssertEqual(a.q + a.r + a.s, 0)
        XCTAssertEqual(CoordenadaAxial(1, -2), CoordenadaAxial(q: 1, r: -2))
        XCTAssertEqual(CoordenadaAxial.origen.description, "(q: 0, r: 0)")
    }

    func testSeSumanYRestanComoVectores() {
        let a = CoordenadaAxial(q: 1, r: -3)
        let b = CoordenadaAxial(q: 3, r: -7)
        XCTAssertEqual(a + b, CoordenadaAxial(q: 4, r: -10))
        XCTAssertEqual(a - b, CoordenadaAxial(q: -2, r: 4))
        XCTAssertEqual(a * 2, CoordenadaAxial(q: 2, r: -6))
        XCTAssertEqual(2 * a, a * 2)
        XCTAssertEqual(-a, CoordenadaAxial(q: -1, r: 3))
        var c = a
        c += b
        c -= b
        XCTAssertEqual(c, a)
    }

    func testVecinos() {
        let a = CoordenadaAxial(q: 1, r: -2)
        XCTAssertEqual(a.vecino(2), CoordenadaAxial(q: 1, r: -3))
        XCTAssertEqual(a.vecino(8), a.vecino(2))
        XCTAssertEqual(a.vecino(-1), a.vecino(5))
        XCTAssertEqual(a.vecinos.count, 6)
        XCTAssertEqual(Set(a.vecinos).count, 6)
        for (i, vecina) in a.vecinos.enumerated() {
            XCTAssertEqual(a.distancia(a: vecina), 1)
            XCTAssertTrue(a.esVecina(de: vecina))
            XCTAssertEqual(a.direccion(hacia: vecina), i)
        }
        XCTAssertNil(a.direccion(hacia: a))
        XCTAssertNil(a.direccion(hacia: a.vecinoDiagonal(0)))
        XCTAssertFalse(a.esVecina(de: a))
    }

    func testLasDireccionesOpuestasSeAnulan() {
        for i in 0..<3 {
            XCTAssertEqual(CoordenadaAxial.direcciones[i] + CoordenadaAxial.direcciones[i + 3], .origen)
        }
    }

    func testDiagonales() {
        let a = CoordenadaAxial(q: 1, r: -2)
        XCTAssertEqual(a.vecinoDiagonal(3), CoordenadaAxial(q: -1, r: -1))
        for i in 0..<6 {
            // Cada diagonal queda entre dos direcciones seguidas, a distancia 2.
            XCTAssertEqual(CoordenadaAxial.diagonales[i],
                           CoordenadaAxial.direcciones[i] + CoordenadaAxial.direcciones[(i + 1) % 6])
            XCTAssertEqual(a.distancia(a: a.vecinoDiagonal(i)), 2)
        }
        XCTAssertEqual(Set(a.vecinosDiagonales).count, 6)
    }

    func testDistancia() {
        XCTAssertEqual(CoordenadaAxial(q: 3, r: -7).distancia(a: .origen), 7)
        XCTAssertEqual(CoordenadaAxial(q: 3, r: -7).longitud, 7)
        XCTAssertEqual(CoordenadaAxial(q: -2, r: 5).distancia(a: CoordenadaAxial(q: 1, r: 1)), 4)
        XCTAssertEqual(CoordenadaAxial.origen.longitud, 0)
    }
}

final class CoordenadaCubicaTests: XCTestCase {
    func testIdaYVueltaConLasAxiales() {
        let c = CoordenadaCubica(q: 1, r: -3, s: 2)
        XCTAssertEqual(c.axial, CoordenadaAxial(q: 1, r: -3))
        XCTAssertEqual(CoordenadaCubica(c.axial), c)
        XCTAssertEqual(CoordenadaAxial(c), c.axial)
        XCTAssertEqual(c.axial.cubica, c)
        XCTAssertEqual(c.description, "(q: 1, r: -3, s: 2)")
    }

    func testValidando() {
        XCTAssertNotNil(CoordenadaCubica(validando: 1, -3, 2))
        XCTAssertNil(CoordenadaCubica(validando: 1, 1, 1))
    }

    func testAritmeticaYDistancia() {
        let a = CoordenadaCubica(q: 1, r: -3, s: 2)
        let b = CoordenadaCubica(q: 3, r: -7, s: 4)
        XCTAssertEqual(a + b, CoordenadaCubica(q: 4, r: -10, s: 6))
        XCTAssertEqual(a - b, CoordenadaCubica(q: -2, r: 4, s: -2))
        XCTAssertEqual(a * 3, CoordenadaCubica(q: 3, r: -9, s: 6))
        XCTAssertEqual(b.distancia(a: .origen), 7)
        XCTAssertEqual(a.distancia(a: b), a.axial.distancia(a: b.axial))
        XCTAssertEqual(a.vecinos.map(\.axial), a.axial.vecinos)
    }

    func testCodable() throws {
        let c = CoordenadaCubica(q: 1, r: -3, s: 2)
        let datos = try JSONEncoder().encode(c)
        XCTAssertEqual(try JSONDecoder().decode(CoordenadaCubica.self, from: datos), c)
        let mal = Data(#"{"q": 1, "r": 1, "s": 1}"#.utf8)
        XCTAssertThrowsError(try JSONDecoder().decode(CoordenadaCubica.self, from: mal))
        let axial = CoordenadaAxial(q: 2, r: -5)
        XCTAssertEqual(try JSONDecoder().decode(CoordenadaAxial.self, from: JSONEncoder().encode(axial)), axial)
    }
}

final class CoordenadaFraccionariaTests: XCTestCase {
    private let a = CoordenadaFraccionaria(CoordenadaAxial(q: 0, r: 0))
    private let b = CoordenadaFraccionaria(CoordenadaAxial(q: 1, r: -1))
    private let c = CoordenadaFraccionaria(CoordenadaAxial(q: 0, r: -1))

    func testRedondeo() {
        let lejos = CoordenadaFraccionaria(q: 10, r: -20)
        XCTAssertEqual(CoordenadaFraccionaria.interpolar(a, lejos, 0.5).redondeada(), CoordenadaAxial(q: 5, r: -10))
        XCTAssertEqual(CoordenadaFraccionaria.interpolar(a, b, 0.499).redondeada(), a.redondeada())
        XCTAssertEqual(CoordenadaFraccionaria.interpolar(a, b, 0.501).redondeada(), b.redondeada())
    }

    func testRedondeoEntreTresCasillas() {
        func mezcla(_ pa: Double, _ pb: Double, _ pc: Double) -> CoordenadaFraccionaria {
            CoordenadaFraccionaria(q: a.q * pa + b.q * pb + c.q * pc, r: a.r * pa + b.r * pb + c.r * pc)
        }
        XCTAssertEqual(mezcla(0.4, 0.3, 0.3).redondeada(), a.redondeada())
        XCTAssertEqual(mezcla(0.3, 0.3, 0.4).redondeada(), c.redondeada())
    }

    func testElCentroDeUnaCasillaEsLaCasilla() {
        for casilla in CoordenadaAxial.origen.alcance(radio: 4) {
            XCTAssertEqual(CoordenadaFraccionaria(casilla).redondeada(), casilla)
        }
        XCTAssertEqual(CoordenadaFraccionaria(q: 1.5, r: 0.25).s, -1.75)
    }
}

final class CoordenadaDesplazadaTests: XCTestCase {
    func testValoresConocidos() {
        let a = CoordenadaAxial(q: 1, r: 2)
        XCTAssertEqual(a.desplazada(.columnasPares), CoordenadaDesplazada(columna: 1, fila: 3))
        XCTAssertEqual(a.desplazada(.columnasImpares), CoordenadaDesplazada(columna: 1, fila: 2))
        XCTAssertEqual(a.desplazada(.filasPares), CoordenadaDesplazada(columna: 2, fila: 2))
        XCTAssertEqual(a.desplazada(.filasImpares), CoordenadaDesplazada(columna: 2, fila: 2))
        // Una fila impar: aquí sí se distinguen.
        let d = CoordenadaDesplazada(columna: 3, fila: 1)
        XCTAssertEqual(d.axial(.filasImpares), CoordenadaAxial(q: 3, r: 1))
        XCTAssertEqual(d.axial(.filasImpares).desplazada(.filasPares), CoordenadaDesplazada(columna: 4, fila: 1))
        XCTAssertEqual(d.description, "(columna: 3, fila: 1)")
    }

    func testIdaYVueltaConNegativos() {
        for desplazamiento in Desplazamiento.allCases {
            for casilla in CoordenadaAxial.origen.alcance(radio: 6) {
                let d = casilla.desplazada(desplazamiento)
                XCTAssertEqual(d.axial(desplazamiento), casilla, "\(desplazamiento) \(casilla)")
                XCTAssertEqual(CoordenadaAxial(d, desplazamiento), casilla)
            }
            for columna in -5...5 {
                for fila in -5...5 {
                    let d = CoordenadaDesplazada(columna: columna, fila: fila)
                    XCTAssertEqual(d.axial(desplazamiento).desplazada(desplazamiento), d)
                }
            }
        }
    }

    func testEnLasFilasDesplazadasLasFilasSonRectas() {
        // Con filas desplazadas, la fila es r; con columnas desplazadas, la columna es q.
        let a = CoordenadaAxial(q: -3, r: 5)
        XCTAssertEqual(a.desplazada(.filasImpares).fila, a.r)
        XCTAssertEqual(a.desplazada(.columnasPares).columna, a.q)
        XCTAssertEqual(Desplazamiento.filasPares.orientacion, .puntiaguda)
        XCTAssertEqual(Desplazamiento.columnasImpares.orientacion, .plana)
    }

    func testVecinosYDistancia() {
        let d = CoordenadaDesplazada(columna: 2, fila: 3)
        for desplazamiento in Desplazamiento.allCases {
            let vecinas = d.vecinos(desplazamiento)
            XCTAssertEqual(Set(vecinas).count, 6)
            for vecina in vecinas {
                XCTAssertEqual(d.distancia(a: vecina, desplazamiento), 1)
            }
        }
        // En una fila impar con filas impares desplazadas, la vecina de arriba a la derecha está en la columna siguiente.
        XCTAssertTrue(d.vecinos(.filasImpares).contains(CoordenadaDesplazada(columna: 3, fila: 2)))
        XCTAssertFalse(d.vecinos(.filasPares).contains(CoordenadaDesplazada(columna: 3, fila: 2)))
    }
}

final class CoordenadaDobladaTests: XCTestCase {
    func testValoresConocidos() {
        let a = CoordenadaAxial(q: 1, r: 2)
        XCTAssertEqual(a.doblada(.altoDoble), CoordenadaDoblada(columna: 1, fila: 5))
        XCTAssertEqual(a.doblada(.anchoDoble), CoordenadaDoblada(columna: 4, fila: 2))
        XCTAssertEqual(CoordenadaAxial(CoordenadaDoblada(columna: 4, fila: 2), .anchoDoble), a)
        XCTAssertEqual(CoordenadaDoblada(columna: 1, fila: 5).axial(.altoDoble), a)
        XCTAssertEqual(Doblado.anchoDoble.orientacion, .puntiaguda)
        XCTAssertEqual(Doblado.altoDoble.orientacion, .plana)
    }

    func testValidez() {
        XCTAssertTrue(CoordenadaDoblada(columna: 4, fila: 2).esValida)
        XCTAssertTrue(CoordenadaDoblada(columna: -3, fila: 1).esValida)
        XCTAssertFalse(CoordenadaDoblada(columna: 3, fila: 2).esValida)
        XCTAssertFalse(CoordenadaDoblada(columna: -3, fila: 0).esValida)
    }

    func testIdaYVueltaYDistancia() {
        let region = CoordenadaAxial.origen.alcance(radio: 5)
        for doblado in Doblado.allCases {
            for casilla in region {
                let d = casilla.doblada(doblado)
                XCTAssertTrue(d.esValida)
                XCTAssertEqual(d.axial(doblado), casilla)
                XCTAssertEqual(Set(d.vecinos(doblado)).count, 6)
            }
            let centro = CoordenadaAxial(q: 1, r: -2)
            for casilla in region {
                XCTAssertEqual(casilla.doblada(doblado).distancia(a: centro.doblada(doblado), doblado),
                               casilla.distancia(a: centro), "\(doblado) \(casilla)")
            }
        }
    }
}
