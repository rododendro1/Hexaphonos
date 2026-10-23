import Foundation
import XCTest
@testable import Hexagonos

final class DireccionHexagonalTests: XCTestCase {
    func testElPasoEsElDeLasDirecciones() {
        XCTAssertEqual(DireccionHexagonal.allCases.map(\.paso), CoordenadaAxial.direcciones)
        XCTAssertEqual(DireccionHexagonal.allCases.map(\.numero), Array(0..<6))
        // El nombre dice qué coordenada cúbica sube y cuál baja.
        let q = CoordenadaCubica(DireccionHexagonal.qMasSMenos.paso)
        XCTAssertEqual([q.q, q.r, q.s], [1, 0, -1])
        let r = CoordenadaCubica(DireccionHexagonal.rMasQMenos.paso)
        XCTAssertEqual([r.q, r.r, r.s], [-1, 1, 0])
        let s = CoordenadaCubica(DireccionHexagonal.sMasRMenos.paso)
        XCTAssertEqual([s.q, s.r, s.s], [0, -1, 1])
    }

    func testNumeroModuloSeis() {
        XCTAssertEqual(DireccionHexagonal(numero: 7), .qMasRMenos)
        XCTAssertEqual(DireccionHexagonal(numero: -1), .rMasSMenos)
        XCTAssertEqual(DireccionHexagonal(numero: 12), .qMasSMenos)
    }

    func testGiros() {
        for d in DireccionHexagonal.allCases {
            XCTAssertEqual(d.opuesta.opuesta, d)
            XCTAssertEqual(d.paso + d.opuesta.paso, .origen)
            XCTAssertEqual(d.siguiente.anterior, d)
            XCTAssertEqual(d.rotada(sextos: 6), d)
            // Girar la dirección es girar su paso.
            XCTAssertEqual(d.siguiente.paso, d.paso.rotadaEnSentidoAntihorario())
            XCTAssertEqual(d.anterior.paso, d.paso.rotadaEnSentidoHorario())
        }
        XCTAssertEqual(DireccionHexagonal.qMasSMenos.opuesta, .sMasQMenos)
    }

    func testPuntosCardinales() {
        XCTAssertEqual(DireccionHexagonal.allCases.map { $0.puntoCardinal(.puntiaguda) },
                       [.este, .noreste, .noroeste, .oeste, .suroeste, .sureste])
        XCTAssertEqual(DireccionHexagonal.allCases.map { $0.puntoCardinal(.plana) },
                       [.sureste, .noreste, .norte, .noroeste, .suroeste, .sur])
        XCTAssertEqual(DireccionHexagonal(.este, .puntiaguda), .qMasSMenos)
        XCTAssertEqual(DireccionHexagonal(.norte, .plana), .sMasRMenos)
        XCTAssertNil(DireccionHexagonal(.norte, .puntiaguda))
        XCTAssertNil(DireccionHexagonal(.este, .plana))
        for orientacion in Orientacion.allCases {
            for d in DireccionHexagonal.allCases {
                XCTAssertEqual(DireccionHexagonal(d.puntoCardinal(orientacion), orientacion), d)
            }
        }
    }

    func testElAnguloCoincideConElDibujo() {
        // Con el eje y hacia abajo, el ángulo antihorario desde el este es atan2(−dy, dx).
        for orientacion in Orientacion.allCases {
            let trazado = Trazado(orientacion: orientacion, tamano: 10)
            XCTAssertEqual(DireccionHexagonal.allCases.map { $0.angulo(orientacion) },
                           orientacion == .puntiaguda ? [0, 60, 120, 180, 240, 300] : [330, 30, 90, 150, 210, 270])
            for d in DireccionHexagonal.allCases {
                let centro = trazado.centro(de: d.paso)
                var grados = atan2(-centro.y, centro.x) * 180 / .pi
                if grados < -1e-9 { grados += 360 }
                XCTAssertEqual(grados, d.angulo(orientacion), accuracy: 1e-9, "\(orientacion) \(d)")
            }
        }
    }

    func testVecinosYAvances() {
        let a = CoordenadaAxial(q: 2, r: -1)
        for d in DireccionHexagonal.allCases {
            XCTAssertEqual(a.vecino(d), a.vecino(d.numero))
            XCTAssertEqual(a.direccion(hacia: a.vecino(d)), d)
            XCTAssertEqual(a.avanzando(3, hacia: d).distancia(hasta: a), 3)
            XCTAssertEqual(a.avanzando(-2, hacia: d), a.avanzando(2, hacia: d.opuesta))
        }
        XCTAssertEqual(CoordenadaAxial.origen.vecino(DireccionHexagonal(.este, .puntiaguda)!), CoordenadaAxial(q: 1, r: 0))
        XCTAssertEqual(DireccionHexagonal(.este, .puntiaguda)?.puntoCardinal(.plana), .sureste)
    }
}
