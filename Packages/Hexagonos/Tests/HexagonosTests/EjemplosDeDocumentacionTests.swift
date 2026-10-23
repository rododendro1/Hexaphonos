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

    func testMapasYCaminos() {
        var mapa = MapaHexagonal(repitiendo: "hierba", en: FormasDeMapa.hexagono(radio: 2))
        mapa[CoordenadaAxial(q: 1, r: 0)] = "agua"
        XCTAssertEqual(mapa.count, 19)
        XCTAssertNil(mapa[CoordenadaAxial(q: 5, r: 0)])
        XCTAssertEqual(mapa.vecinas(de: .origen).count, 6)

        let pantano: Set = [CoordenadaAxial(q: 1, r: 0)]
        let camino = CoordenadaAxial.origen.caminoMasBarato(hasta: CoordenadaAxial(q: 2, r: 0)) { _, hacia in
            hacia.longitud > 4 ? nil : (pantano.contains(hacia) ? 5 : 1)
        }
        XCTAssertEqual(camino?.coste, 3.0)
        XCTAssertEqual(camino?.pasos, 3)

        let costes = CoordenadaAxial.origen.alcanzables(presupuesto: 2) { _, hacia in
            hacia.q > 0 ? 2 : 1
        }
        XCTAssertEqual(costes[CoordenadaAxial(q: -2, r: 0)], 2.0)
        XCTAssertNil(costes[CoordenadaAxial(q: 2, r: 0)])

        var terreno = MapaHexagonal(repitiendo: 1.0, en: FormasDeMapa.hexagono(radio: 3))
        terreno[CoordenadaAxial(q: 1, r: 0)] = 10
        XCTAssertEqual(terreno.caminoMasBarato(desde: .origen, hasta: CoordenadaAxial(q: 2, r: 0)) { $0 }?.coste, 3.0)
        XCTAssertEqual(terreno.alcanzables(desde: .origen, presupuesto: 2) { $0 }.count, 17)
    }
}
