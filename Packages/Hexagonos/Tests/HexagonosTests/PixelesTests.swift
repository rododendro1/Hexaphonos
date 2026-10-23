import Foundation
import XCTest
@testable import Hexagonos

final class TrazadoTests: XCTestCase {
    private let raiz3 = 3.0.squareRoot()

    private func igual(_ a: Punto, _ b: Punto, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertEqual(a.x, b.x, accuracy: 1e-9, file: file, line: line)
        XCTAssertEqual(a.y, b.y, accuracy: 1e-9, file: file, line: line)
    }

    func testCentrosPuntiagudos() {
        let d = Trazado(orientacion: .puntiaguda, tamano: 10)
        igual(d.centro(de: .origen), .cero)
        igual(d.centro(de: CoordenadaAxial(q: 1, r: 0)), Punto(x: 10 * raiz3, y: 0))
        igual(d.centro(de: CoordenadaAxial(q: 0, r: 1)), Punto(x: 5 * raiz3, y: 15))
    }

    func testCentrosPlanos() {
        let d = Trazado(orientacion: .plana, tamano: 10, origen: Punto(x: 100, y: 50))
        igual(d.centro(de: .origen), Punto(x: 100, y: 50))
        igual(d.centro(de: CoordenadaAxial(q: 1, r: 0)), Punto(x: 115, y: 50 + 5 * raiz3))
        igual(d.centro(de: CoordenadaAxial(q: 0, r: 1)), Punto(x: 100, y: 50 + 10 * raiz3))
    }

    func testDePixelACasillaYVuelta() {
        let trazados = [
            Trazado(orientacion: .puntiaguda, tamano: Punto(x: 3, y: 2), origen: Punto(x: 1, y: -4)),
            Trazado(orientacion: .plana, tamano: Punto(x: 7, y: 5), origen: Punto(x: -2, y: 9)),
        ]
        for d in trazados {
            for casilla in CoordenadaAxial.origen.alcance(radio: 5) {
                let centro = d.centro(de: casilla)
                XCTAssertEqual(d.casilla(en: centro), casilla)
                let c = d.coordenada(en: centro)
                XCTAssertEqual(c.q, Double(casilla.q), accuracy: 1e-9)
                XCTAssertEqual(c.r, Double(casilla.r), accuracy: 1e-9)
                // Un punto un poco desplazado del centro sigue en la misma casilla.
                XCTAssertEqual(d.casilla(en: centro + Punto(x: d.tamano.x * 0.3, y: -d.tamano.y * 0.3)), casilla)
            }
        }
    }

    func testVertices() {
        for orientacion in Orientacion.allCases {
            let d = Trazado(orientacion: orientacion, tamano: 10)
            let casilla = CoordenadaAxial(q: 2, r: -1)
            let centro = d.centro(de: casilla)
            let vertices = d.vertices(de: casilla)
            XCTAssertEqual(vertices.count, 6)
            for (v, siguiente) in zip(vertices, vertices.dropFirst() + [vertices[0]]) {
                // Hexágono regular: todos a distancia 10 del centro y lados de 10.
                XCTAssertEqual(hypot(v.x - centro.x, v.y - centro.y), 10, accuracy: 1e-9)
                XCTAssertEqual(hypot(v.x - siguiente.x, v.y - siguiente.y), 10, accuracy: 1e-9)
            }
        }
        // El primer vértice: a 30° en los puntiagudos, a 0° en los planos.
        igual(Trazado(orientacion: .puntiaguda, tamano: 10).vertices(de: .origen)[0], Punto(x: 5 * raiz3, y: 5))
        igual(Trazado(orientacion: .plana, tamano: 10).vertices(de: .origen)[0], Punto(x: 10, y: 0))
    }

    func testVerticesCompartidos() {
        // Dos vecinas comparten exactamente dos vértices.
        let d = Trazado(orientacion: .puntiaguda, tamano: 10)
        func redondear(_ p: Punto) -> [Double] { [(p.x * 1e6).rounded(), (p.y * 1e6).rounded()] }
        let a = Set(d.vertices(de: .origen).map(redondear))
        for vecina in CoordenadaAxial.origen.vecinos {
            XCTAssertEqual(a.intersection(d.vertices(de: vecina).map(redondear)).count, 2)
        }
    }

    func testAnchuraYAltura() {
        let p = Trazado(orientacion: .puntiaguda, tamano: 10)
        XCTAssertEqual(p.anchura, 10 * raiz3, accuracy: 1e-9)
        XCTAssertEqual(p.altura, 20, accuracy: 1e-9)
        // En los puntiagudos, dos vecinas de la misma fila están a una anchura.
        XCTAssertEqual(p.centro(de: CoordenadaAxial(q: 1, r: 0)).x - p.centro(de: .origen).x, p.anchura, accuracy: 1e-9)
        let f = Trazado(orientacion: .plana, tamano: 10)
        XCTAssertEqual(f.anchura, 20, accuracy: 1e-9)
        XCTAssertEqual(f.altura, 10 * raiz3, accuracy: 1e-9)
        XCTAssertEqual(f.centro(de: CoordenadaAxial(q: 0, r: 1)).y - f.centro(de: .origen).y, f.altura, accuracy: 1e-9)
    }

    func testLimites() {
        let d = Trazado(orientacion: .plana, tamano: 10)
        XCTAssertNil(d.limites(de: []))
        let uno = d.limites(de: [.origen])
        XCTAssertEqual(uno?.minimo.x ?? 0, -10, accuracy: 1e-9)
        XCTAssertEqual(uno?.maximo.x ?? 0, 10, accuracy: 1e-9)
        XCTAssertEqual(uno?.minimo.y ?? 0, -5 * raiz3, accuracy: 1e-9)
        XCTAssertEqual(uno?.maximo.y ?? 0, 5 * raiz3, accuracy: 1e-9)
    }

    func testSVG() {
        let d = Trazado(orientacion: .puntiaguda, tamano: 10)
        let casillas = FormasDeMapa.hexagono(radio: 1)
        let svg = d.svg(casillas, relleno: { $0 == .origen ? "red" : nil }, rotulo: { "\($0.q),\($0.r)" })
        XCTAssertTrue(svg.hasPrefix("<svg xmlns=\"http://www.w3.org/2000/svg\""))
        XCTAssertTrue(svg.hasSuffix("</svg>"))
        XCTAssertEqual(svg.components(separatedBy: "<polygon").count - 1, 7)
        XCTAssertEqual(svg.components(separatedBy: "<text").count - 1, 7)
        XCTAssertEqual(svg.components(separatedBy: "fill=\"red\"").count - 1, 1)
        XCTAssertTrue(svg.contains(">0,0</text>"))
        XCTAssertTrue(d.svg([.origen], rotulo: { _ in "<&>" }).contains("&lt;&amp;&gt;"))
        XCTAssertFalse(d.svg([.origen]).contains("<text"))
        XCTAssertTrue(d.svg([]).contains("width=\"0\""))
    }

    func testCodable() throws {
        let d = Trazado(orientacion: .plana, tamano: Punto(x: 3, y: 4), origen: Punto(x: 1, y: 2))
        XCTAssertEqual(try JSONDecoder().decode(Trazado.self, from: JSONEncoder().encode(d)), d)
    }
}
