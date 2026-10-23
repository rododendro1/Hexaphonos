import XCTest
import Foundation
@testable import Hexagonos

final class MapaHexagonalTests: XCTestCase {
    func testValores() {
        var mapa = MapaHexagonal(repitiendo: "hierba", en: FormasDeMapa.hexagono(radio: 2))
        XCTAssertEqual(mapa.count, 19)
        XCTAssertFalse(mapa.isEmpty)
        XCTAssertEqual(mapa[.origen], "hierba")
        XCTAssertNil(mapa[CoordenadaAxial(q: 5, r: 0)])
        mapa[CoordenadaAxial(q: 1, r: 0)] = "agua"
        XCTAssertEqual(mapa[CoordenadaAxial(q: 1, r: 0)], "agua")
        mapa[CoordenadaAxial(q: 5, r: 0)] = "roca"
        XCTAssertEqual(mapa.count, 20)
        XCTAssertTrue(mapa.contiene(CoordenadaAxial(q: 5, r: 0)))
        mapa[CoordenadaAxial(q: 5, r: 0)] = nil
        XCTAssertFalse(mapa.contiene(CoordenadaAxial(q: 5, r: 0)))
        XCTAssertEqual(mapa.quitar(.origen), "hierba")
        XCTAssertNil(mapa.quitar(.origen))
        XCTAssertEqual(mapa.count, 18)
        XCTAssertEqual(Set(mapa.casillas), Set(FormasDeMapa.hexagono(radio: 2)).subtracting([.origen]))
        XCTAssertEqual(mapa.casillas(donde: { $0 == "agua" }), [CoordenadaAxial(q: 1, r: 0)])
        XCTAssertTrue(MapaHexagonal<Int>().isEmpty)
    }

    func testPorDefecto() {
        var cuenta = MapaHexagonal<Int>()
        for casilla in [CoordenadaAxial.origen, CoordenadaAxial(q: 1, r: 0), .origen] {
            cuenta[casilla, porDefecto: 0] += 1
        }
        XCTAssertEqual(cuenta, [.origen: 2, CoordenadaAxial(q: 1, r: 0): 1])
        XCTAssertEqual(cuenta[CoordenadaAxial(q: 9, r: 9), porDefecto: 0], 0)
        XCTAssertEqual(cuenta.count, 2)
    }

    func testColeccion() {
        let mapa = MapaHexagonal(FormasDeMapa.hexagono(radio: 1)) { $0.longitud }
        XCTAssertEqual(mapa.count, 7)
        XCTAssertEqual(mapa.reduce(0) { $0 + $1.valor }, 6)
        XCTAssertEqual(mapa.filter { $0.valor == 0 }.map { $0.casilla }, [.origen])
        var vistas = 0
        for (casilla, valor) in mapa {
            XCTAssertEqual(casilla.longitud, valor)
            vistas += 1
        }
        XCTAssertEqual(vistas, 7)
        XCTAssertEqual("\(mapa)", "MapaHexagonal (7 casillas)")
    }

    func testVecinas() {
        let mapa = MapaHexagonal(FormasDeMapa.hexagono(radio: 1)) { $0.q }
        XCTAssertEqual(mapa.vecinas(de: .origen).map { $0.casilla }, CoordenadaAxial.origen.vecinos)
        let borde = CoordenadaAxial(q: 1, r: 0)
        XCTAssertEqual(mapa.vecinas(de: borde).map { $0.casilla },
                       borde.vecinos.filter { $0.longitud <= 1 })
        XCTAssertEqual(mapa.vecinas(de: borde).map { $0.valor }, mapa.vecinas(de: borde).map { $0.casilla.q })
        XCTAssertEqual(mapa.vecinas(de: CoordenadaAxial(q: 2, r: -1)).count, 2)   // fuera del mapa
    }

    func testTransformarYFiltrar() {
        let mapa = MapaHexagonal(FormasDeMapa.hexagono(radio: 2)) { $0.longitud }
        let texto = mapa.transformado { "\($0)" }
        XCTAssertEqual(texto[CoordenadaAxial(q: 2, r: 0)], "2")
        let cerca = mapa.filtrado { _, valor in valor < 2 }
        XCTAssertEqual(Set(cerca.casillas), Set(FormasDeMapa.hexagono(radio: 1)))
    }

    func testSimetrias() {
        let mapa = MapaHexagonal(FormasDeMapa.triangulo(lado: 3)) { "\($0.q),\($0.r)" }
        let vector = CoordenadaAxial(q: 2, r: -5)
        let desplazado = mapa.desplazado(por: vector)
        let centro = CoordenadaAxial(q: 1, r: 1)
        let girado = mapa.rotado(sextos: 2, alrededorDe: centro)
        let reflejado = mapa.reflejado(sobre: .s)
        for (casilla, valor) in mapa {
            XCTAssertEqual(desplazado[casilla + vector], valor)
            XCTAssertEqual(girado[casilla.rotada(sextos: 2, alrededorDe: centro)], valor)
            XCTAssertEqual(reflejado[casilla.reflejada(sobre: .s)], valor)
        }
        XCTAssertEqual(girado.count, mapa.count)
        XCTAssertEqual(mapa.rotado(sextos: 6), mapa)
        XCTAssertEqual(mapa.rotado(sextos: 1).rotado(sextos: -1), mapa)
    }

    func testCaminosYVisibilidad() {
        var terreno = MapaHexagonal(repitiendo: 1.0, en: FormasDeMapa.hexagono(radio: 3))
        terreno[CoordenadaAxial(q: 1, r: 0)] = 10
        let camino = terreno.caminoMasBarato(desde: .origen, hasta: CoordenadaAxial(q: 2, r: 0)) { $0 }
        XCTAssertEqual(camino?.coste, 3)
        // Fuera del mapa no se puede pisar.
        XCTAssertNil(terreno.caminoMasBarato(desde: .origen, hasta: CoordenadaAxial(q: 4, r: 0)) { $0 })
        // Un muro (nil) se rodea.
        let conMuro = terreno.caminoMasBarato(desde: .origen, hasta: CoordenadaAxial(q: 2, r: 0)) { $0 > 5 ? nil : $0 }
        XCTAssertEqual(conMuro?.coste, 3)

        let alcanzables = terreno.alcanzables(desde: .origen, presupuesto: 2) { $0 }
        XCTAssertNil(alcanzables[CoordenadaAxial(q: 1, r: 0)])
        XCTAssertEqual(alcanzables[CoordenadaAxial(q: 2, r: -1)], 2)
        XCTAssertTrue(alcanzables.keys.allSatisfy { terreno.contiene($0) })

        let visibles = terreno.visibles(desde: .origen) { $0 > 5 }
        XCTAssertFalse(visibles.contains(CoordenadaAxial(q: 2, r: 0)))
        XCTAssertFalse(visibles.contains(CoordenadaAxial(q: 1, r: 0)))
        XCTAssertTrue(visibles.contains(CoordenadaAxial(q: 0, r: 2)))
    }

    func testCodable() throws {
        let mapa: MapaHexagonal = [CoordenadaAxial(q: 1, r: 0): "agua", .origen: "hierba"]
        let codificador = JSONEncoder()
        codificador.outputFormatting = .sortedKeys
        let datos = try codificador.encode(mapa)
        XCTAssertEqual(String(decoding: datos, as: UTF8.self),
                       #"[{"q":0,"r":0,"valor":"hierba"},{"q":1,"r":0,"valor":"agua"}]"#)
        XCTAssertEqual(try JSONDecoder().decode(MapaHexagonal<String>.self, from: datos), mapa)
        let repetida = Data(#"[{"q":0,"r":0,"valor":"a"},{"q":0,"r":0,"valor":"b"}]"#.utf8)
        XCTAssertThrowsError(try JSONDecoder().decode(MapaHexagonal<String>.self, from: repetida))
    }

    func testIgualdadYHash() {
        let a = MapaHexagonal(FormasDeMapa.hexagono(radio: 1)) { $0.q }
        var b = a
        XCTAssertEqual(a, b)
        XCTAssertEqual(Set([a, b]).count, 1)
        b[.origen] = 7
        XCTAssertNotEqual(a, b)
    }

    func testLimites() {
        let mapa = MapaHexagonal(repitiendo: 0, en: FormasDeMapa.hexagono(radio: 2))
        let trazado = Trazado(orientacion: .puntiaguda, tamano: 10)
        let limites = mapa.limites(con: trazado)
        XCTAssertNotNil(limites)
        XCTAssertEqual(limites?.minimo.x ?? 0, trazado.limites(de: FormasDeMapa.hexagono(radio: 2))?.minimo.x ?? 1)
        XCTAssertNil(MapaHexagonal<Int>().limites(con: trazado))
    }
}
