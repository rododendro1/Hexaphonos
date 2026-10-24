import XCTest
import Hexagonos
@testable import ArmoniaUI

// No usa SwiftUI: se ejecuta también en Linux.

final class PresentacionHexagonalTests: XCTestCase {
    private let mapa = FormasDeMapa.hexagono(radio: 2)

    func testLaProporcionEsLaDeLosHexagonos() throws {
        let raiz3 = 3.0.squareRoot()
        // Un solo hexágono puntiagudo mide √3 de ancho por 2 de alto; uno plano, al revés.
        XCTAssertEqual(try XCTUnwrap(PresentacionHexagonal.proporcion(de: [.origen], orientacion: .puntiaguda)),
                       raiz3 / 2, accuracy: 1e-9)
        XCTAssertEqual(try XCTUnwrap(PresentacionHexagonal.proporcion(de: [.origen], orientacion: .plana)),
                       2 / raiz3, accuracy: 1e-9)
        XCTAssertNil(PresentacionHexagonal.proporcion(de: [], orientacion: .plana))
    }

    func testElMapaCabeCentradoYConMargen() throws {
        for orientacion in Orientacion.allCases {
            for (ancho, alto) in [(300.0, 200.0), (120.0, 400.0)] {
                let d = try XCTUnwrap(PresentacionHexagonal.trazado(para: mapa, orientacion: orientacion,
                                                                       ancho: ancho, alto: alto, margen: 5))
                let caja = try XCTUnwrap(d.limites(de: mapa))
                XCTAssertGreaterThanOrEqual(caja.minimo.x, 5 - 1e-9)
                XCTAssertGreaterThanOrEqual(caja.minimo.y, 5 - 1e-9)
                XCTAssertLessThanOrEqual(caja.maximo.x, ancho - 5 + 1e-9)
                XCTAssertLessThanOrEqual(caja.maximo.y, alto - 5 + 1e-9)
                // Centrado en los dos ejes, y tocando el margen en al menos uno (lo más grande posible).
                XCTAssertEqual(caja.minimo.x + caja.maximo.x, ancho, accuracy: 1e-9)
                XCTAssertEqual(caja.minimo.y + caja.maximo.y, alto, accuracy: 1e-9)
                let holguraX = caja.minimo.x - 5
                let holguraY = caja.minimo.y - 5
                XCTAssertEqual(min(holguraX, holguraY), 0, accuracy: 1e-9)
            }
        }
    }

    func testSinCasillasOSinSitioNoHayTrazado() {
        XCTAssertNil(PresentacionHexagonal.trazado(para: [], orientacion: .plana, ancho: 100, alto: 100))
        XCTAssertNil(PresentacionHexagonal.trazado(para: mapa, orientacion: .plana, ancho: 10, alto: 10, margen: 5))
        XCTAssertNil(PresentacionHexagonal.trazado(para: mapa, orientacion: .plana, ancho: 0, alto: 0))
    }

    func testElToqueDaLaCasillaDelMapa() throws {
        let d = try XCTUnwrap(PresentacionHexagonal.trazado(para: mapa, orientacion: .puntiaguda,
                                                               ancho: 300, alto: 300, margen: 3))
        let conjunto = Set(mapa)
        for casilla in mapa {
            XCTAssertEqual(PresentacionHexagonal.casilla(en: d.centro(de: casilla), trazado: d, mapa: conjunto), casilla)
        }
        // Fuera del mapa: la esquina del rectángulo y una casilla que no está.
        XCTAssertNil(PresentacionHexagonal.casilla(en: Punto(x: 1, y: 1), trazado: d, mapa: conjunto))
        let fuera = CoordenadaAxial(q: 3, r: 0)
        XCTAssertNil(PresentacionHexagonal.casilla(en: d.centro(de: fuera), trazado: d, mapa: conjunto))
    }

    func testDescripcion() {
        XCTAssertEqual(PresentacionHexagonal.descripcion(casillas: 19, seleccionada: nil), "19 casillas")
        XCTAssertEqual(PresentacionHexagonal.descripcion(casillas: 1, seleccionada: CoordenadaAxial(q: 2, r: -1)),
                       "1 casilla; elegida q 2, r -1")
    }
}
