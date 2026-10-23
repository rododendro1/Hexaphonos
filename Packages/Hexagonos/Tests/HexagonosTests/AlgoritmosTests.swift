import XCTest
@testable import Hexagonos

final class LineasTests: XCTestCase {
    func testLineaConocida() {
        let linea = CoordenadaAxial.origen.linea(hasta: CoordenadaAxial(q: 1, r: -5))
        XCTAssertEqual(linea, [
            CoordenadaAxial(q: 0, r: 0), CoordenadaAxial(q: 0, r: -1), CoordenadaAxial(q: 0, r: -2),
            CoordenadaAxial(q: 1, r: -3), CoordenadaAxial(q: 1, r: -4), CoordenadaAxial(q: 1, r: -5),
        ])
    }

    func testLineaRecta() {
        XCTAssertEqual(CoordenadaAxial.origen.linea(hasta: CoordenadaAxial(q: 3, r: 0)),
                       (0...3).map { CoordenadaAxial(q: $0, r: 0) })
        let a = CoordenadaAxial(q: 2, r: -1)
        XCTAssertEqual(a.linea(hasta: a), [a])
    }

    func testCadaCasillaEsVecinaDeLaAnterior() {
        let origen = CoordenadaAxial(q: -2, r: 1)
        for destino in origen.alcance(radio: 6) {
            let linea = origen.linea(hasta: destino)
            XCTAssertEqual(linea.count, origen.distancia(a: destino) + 1)
            XCTAssertEqual(linea.first, origen)
            XCTAssertEqual(linea.last, destino)
            for (anterior, siguiente) in zip(linea, linea.dropFirst()) {
                XCTAssertEqual(anterior.distancia(a: siguiente), 1, "\(origen) → \(destino)")
            }
        }
    }

    func testVisibilidad() {
        let muro: Set = [CoordenadaAxial(q: 1, r: 0)]
        let tapada = { muro.contains($0) }
        XCTAssertFalse(CoordenadaAxial.origen.ve(CoordenadaAxial(q: 3, r: 0), tapada: tapada))
        XCTAssertTrue(CoordenadaAxial.origen.ve(CoordenadaAxial(q: 0, r: 3), tapada: tapada))
        // Una casilla tapada no se tapa a sí misma, ni tapa a una vecina.
        XCTAssertTrue(CoordenadaAxial.origen.ve(CoordenadaAxial(q: 1, r: 0), tapada: tapada))
        let visibles = CoordenadaAxial.origen.visibles(en: CoordenadaAxial.origen.alcance(radio: 3), tapada: tapada)
        XCTAssertFalse(visibles.contains(CoordenadaAxial(q: 1, r: 0)))
        XCTAssertFalse(visibles.contains(CoordenadaAxial(q: 2, r: 0)))
        XCTAssertTrue(visibles.contains(CoordenadaAxial(q: 0, r: 1)))
        XCTAssertTrue(visibles.contains(.origen))
    }

    func testLaLineaDeVueltaEsLaDeIdaAlReves() {
        let a = CoordenadaAxial(q: 1, r: -2)
        for b in a.alcance(radio: 6) {
            XCTAssertEqual(b.linea(hasta: a), a.linea(hasta: b).reversed(), "\(a) ↔ \(b)")
        }
    }

    func testPorUnaAristaBastaUnLado() {
        // La recta a (2, −1) pasa justo entre (1, −1) y (1, 0).
        let destino = CoordenadaAxial(q: 2, r: -1)
        let lados = [CoordenadaAxial(q: 1, r: -1), CoordenadaAxial(q: 1, r: 0)]
        XCTAssertTrue(lados.contains(CoordenadaAxial.origen.linea(hasta: destino)[1]))
        XCTAssertTrue(CoordenadaAxial.origen.ve(destino) { $0 == lados[0] })
        XCTAssertTrue(CoordenadaAxial.origen.ve(destino) { $0 == lados[1] })
        XCTAssertFalse(CoordenadaAxial.origen.ve(destino) { lados.contains($0) })
    }

    func testLaVisibilidadEsSimetrica() {
        // Unos muros sin azar, y las doce simetrías de la rejilla alrededor de una casilla cualquiera.
        let region = FormasDeMapa.hexagono(radio: 6)
        let muros = Set(region.filter { modulo($0.q * 7 + $0.r * 13, 6) == 0 && $0 != .origen })
        let centro = CoordenadaAxial(q: 1, r: -1)
        var simetrias: [(CoordenadaAxial) -> CoordenadaAxial] = []
        for sextos in 0..<6 {
            simetrias.append { $0.rotada(sextos: sextos, alrededorDe: centro) }
            simetrias.append { $0.reflejada(sobre: .q, alrededorDe: centro).rotada(sextos: sextos, alrededorDe: centro) }
        }
        for a in [CoordenadaAxial.origen, CoordenadaAxial(q: -2, r: 3)] {
            for b in region {
                let ve = a.ve(b) { muros.contains($0) }
                XCTAssertEqual(b.ve(a) { muros.contains($0) }, ve, "\(a) ↔ \(b)")
                for simetria in simetrias {
                    let movidos = Set(muros.map(simetria))
                    XCTAssertEqual(simetria(a).ve(simetria(b)) { movidos.contains($0) }, ve, "\(a) → \(b)")
                }
            }
        }
    }
}

final class RegionesTests: XCTestCase {
    func testAlcance() {
        let centro = CoordenadaAxial(q: 2, r: -3)
        for radio in 0...5 {
            let alcance = centro.alcance(radio: radio)
            XCTAssertEqual(alcance.count, 3 * radio * (radio + 1) + 1)
            XCTAssertEqual(Set(alcance).count, alcance.count)
            XCTAssertTrue(alcance.allSatisfy { $0.distancia(a: centro) <= radio })
        }
        XCTAssertEqual(centro.alcance(radio: 0), [centro])
    }

    func testInterseccion() {
        let a = (centro: CoordenadaAxial(q: 0, r: 0), radio: 3)
        let b = (centro: CoordenadaAxial(q: 3, r: -1), radio: 2)
        let c = (centro: CoordenadaAxial(q: 1, r: 1), radio: 2)
        let esperada = a.centro.alcance(radio: a.radio).filter {
            $0.distancia(a: b.centro) <= b.radio && $0.distancia(a: c.centro) <= c.radio
        }
        XCTAssertFalse(esperada.isEmpty)
        XCTAssertEqual(Set(CoordenadaAxial.interseccion(de: [a, b, c])), Set(esperada))
        XCTAssertEqual(Set(CoordenadaAxial.interseccion(de: [a])), Set(a.centro.alcance(radio: a.radio)))
        let lejos = (centro: CoordenadaAxial(q: 20, r: 0), radio: 1)
        XCTAssertEqual(CoordenadaAxial.interseccion(de: [a, lejos]), [])
    }

    func testAnillo() {
        let centro = CoordenadaAxial(q: -1, r: 2)
        XCTAssertEqual(centro.anillo(radio: 0), [centro])
        for radio in 1...5 {
            let anillo = centro.anillo(radio: radio)
            XCTAssertEqual(anillo.count, 6 * radio)
            XCTAssertEqual(Set(anillo).count, anillo.count)
            XCTAssertTrue(anillo.allSatisfy { $0.distancia(a: centro) == radio })
            XCTAssertEqual(anillo.first, centro + CoordenadaAxial.direcciones[4] * radio)
            // Se recorre de vecina en vecina, y la última vuelve a tocar la primera.
            for (anterior, siguiente) in zip(anillo, anillo.dropFirst() + [anillo[0]]) {
                XCTAssertEqual(anterior.distancia(a: siguiente), 1)
            }
        }
        XCTAssertEqual(CoordenadaAxial.origen.anillo(radio: 1).count, 6)
    }

    func testEspiral() {
        let centro = CoordenadaAxial(q: 4, r: -1)
        let espiral = centro.espiral(radio: 3)
        XCTAssertEqual(Set(espiral), Set(centro.alcance(radio: 3)))
        XCTAssertEqual(espiral.count, 37)
        XCTAssertEqual(espiral.first, centro)
        XCTAssertEqual(espiral.map { $0.distancia(a: centro) }, espiral.map { $0.distancia(a: centro) }.sorted())
        XCTAssertEqual(centro.espiral(radio: 0), [centro])
    }

    func testAlcanzablesSinObstaculosEsElAlcance() {
        let pasos = CoordenadaAxial.origen.alcanzables(movimientos: 3) { _ in false }
        XCTAssertEqual(Set(pasos.keys), Set(CoordenadaAxial.origen.alcance(radio: 3)))
        for (casilla, n) in pasos {
            XCTAssertEqual(n, casilla.longitud)
        }
    }

    func testAlcanzablesRodeaLosObstaculos() {
        // Un muro de una casilla de grueso al este del origen, con hueco por arriba y por abajo.
        let muro: Set = [CoordenadaAxial(q: 1, r: -1), CoordenadaAxial(q: 1, r: 0), CoordenadaAxial(q: 0, r: 1)]
        let pasos = CoordenadaAxial.origen.alcanzables(movimientos: 4) { muro.contains($0) }
        for bloque in muro {
            XCTAssertNil(pasos[bloque])
        }
        XCTAssertEqual(pasos[.origen], 0)
        // (2, 0) está a 2 en línea recta, pero hay que rodear el muro.
        XCTAssertGreaterThan(pasos[CoordenadaAxial(q: 2, r: 0)] ?? .max, 2)
        XCTAssertTrue(pasos.allSatisfy { $0.value <= 4 })
    }

    func testAlcanzablesEncerrado() {
        let pasos = CoordenadaAxial.origen.alcanzables(movimientos: 10) { $0.longitud == 1 }
        XCTAssertEqual(pasos, [.origen: 0])
    }

    func testCamino() {
        let mapa = Set(FormasDeMapa.hexagono(radio: 4)).subtracting([
            CoordenadaAxial(q: 1, r: -1), CoordenadaAxial(q: 1, r: 0), CoordenadaAxial(q: 1, r: 1),
        ])
        let destino = CoordenadaAxial(q: 3, r: 0)
        let camino = CoordenadaAxial.origen.camino(hasta: destino, por: mapa)
        XCTAssertNotNil(camino)
        if let camino {
            XCTAssertEqual(camino.first, .origen)
            XCTAssertEqual(camino.last, destino)
            XCTAssertTrue(camino.dropFirst().allSatisfy { mapa.contains($0) })
            for (anterior, siguiente) in zip(camino, camino.dropFirst()) {
                XCTAssertEqual(anterior.distancia(a: siguiente), 1)
            }
            let pasos = CoordenadaAxial.origen.alcanzables(movimientos: 20) { !mapa.contains($0) }
            XCTAssertEqual(camino.count - 1, pasos[destino])
        }
        XCTAssertEqual(CoordenadaAxial.origen.camino(hasta: .origen, por: []), [.origen])
        XCTAssertNil(CoordenadaAxial.origen.camino(hasta: CoordenadaAxial(q: 9, r: 0), por: mapa))
        let isla: Set = [CoordenadaAxial(q: 3, r: 0)]
        XCTAssertNil(CoordenadaAxial.origen.camino(hasta: CoordenadaAxial(q: 3, r: 0), por: isla))
    }
}

final class SimetriasTests: XCTestCase {
    func testRotacionesConocidas() {
        let a = CoordenadaAxial(CoordenadaCubica(q: 1, r: -3, s: 2))
        XCTAssertEqual(a.rotadaEnSentidoHorario().cubica, CoordenadaCubica(q: 3, r: -2, s: -1))
        XCTAssertEqual(a.rotadaEnSentidoAntihorario().cubica, CoordenadaCubica(q: -2, r: -1, s: 3))
    }

    func testLasRotacionesSiguenLasDirecciones() {
        for i in 0..<6 {
            let d = CoordenadaAxial.direcciones[i]
            XCTAssertEqual(d.rotadaEnSentidoAntihorario(), CoordenadaAxial.direcciones[(i + 1) % 6])
            XCTAssertEqual(d.rotadaEnSentidoHorario(), CoordenadaAxial.direcciones[(i + 5) % 6])
            XCTAssertEqual(d.rotada(sextos: 2), CoordenadaAxial.direcciones[(i + 2) % 6])
        }
    }

    func testRotarAlrededorDeUnCentro() {
        let centro = CoordenadaAxial(q: 2, r: -1)
        let a = CoordenadaAxial(q: 4, r: -3)
        XCTAssertEqual(a.rotada(sextos: 6, alrededorDe: centro), a)
        XCTAssertEqual(a.rotada(sextos: 0, alrededorDe: centro), a)
        XCTAssertEqual(a.rotada(sextos: -1, alrededorDe: centro), a.rotadaEnSentidoHorario(alrededorDe: centro))
        XCTAssertEqual(a.rotada(sextos: 3, alrededorDe: centro), centro - (a - centro))
        XCTAssertEqual(centro.rotada(sextos: 1, alrededorDe: centro), centro)
        for k in 0..<6 {
            XCTAssertEqual(a.rotada(sextos: k, alrededorDe: centro).distancia(a: centro), a.distancia(a: centro))
        }
        XCTAssertEqual(a.rotadaEnSentidoHorario(alrededorDe: centro).rotadaEnSentidoAntihorario(alrededorDe: centro), a)
    }

    func testRotadaEsGirarVariasVeces() {
        let centro = CoordenadaAxial(q: -1, r: 3)
        for a in centro.alcance(radio: 3) {
            var girada = a
            for sextos in 0...7 {
                XCTAssertEqual(a.rotada(sextos: sextos, alrededorDe: centro), girada, "\(a), \(sextos)")
                XCTAssertEqual(girada.rotada(sextos: -sextos, alrededorDe: centro), a)
                girada = girada.rotadaEnSentidoAntihorario(alrededorDe: centro)
            }
        }
    }

    func testReflexiones() {
        let a = CoordenadaAxial(CoordenadaCubica(q: 1, r: -3, s: 2))
        XCTAssertEqual(a.reflejada(sobre: .q).cubica, CoordenadaCubica(q: 1, r: 2, s: -3))
        XCTAssertEqual(a.reflejada(sobre: .r).cubica, CoordenadaCubica(q: 2, r: -3, s: 1))
        XCTAssertEqual(a.reflejada(sobre: .s).cubica, CoordenadaCubica(q: -3, r: 1, s: 2))
        let centro = CoordenadaAxial(q: -1, r: 2)
        for eje in Eje.allCases {
            let b = a.reflejada(sobre: eje, alrededorDe: centro)
            XCTAssertEqual(b.reflejada(sobre: eje, alrededorDe: centro), a)
            XCTAssertEqual(b.distancia(a: centro), a.distancia(a: centro))
        }
    }
}

final class FormasDeMapaTests: XCTestCase {
    func testHexagono() {
        XCTAssertEqual(FormasDeMapa.hexagono(radio: 2).count, 19)
        XCTAssertEqual(FormasDeMapa.hexagono(radio: 1, centro: CoordenadaAxial(q: 5, r: 5)).count, 7)
    }

    func testParalelogramo() {
        let p = FormasDeMapa.paralelogramo(columnas: -1...2, filas: 0...2)
        XCTAssertEqual(p.count, 12)
        XCTAssertTrue(p.contains(CoordenadaAxial(q: -1, r: 2)))
    }

    func testTriangulo() {
        let t = FormasDeMapa.triangulo(lado: 4)
        XCTAssertEqual(t.count, 10)
        XCTAssertTrue(t.allSatisfy { $0.q >= 0 && $0.r >= 0 && $0.q + $0.r < 4 })
        let invertido = FormasDeMapa.triangulo(lado: 4, invertido: true)
        XCTAssertEqual(Set(invertido), Set(t.map { -$0 }))
        XCTAssertEqual(FormasDeMapa.triangulo(lado: 0), [])
    }

    func testRectangulo() {
        for desplazamiento in Desplazamiento.allCases {
            let r = FormasDeMapa.rectangulo(columnas: 5, filas: 3, desplazamiento)
            XCTAssertEqual(r.count, 15)
            XCTAssertEqual(Set(r).count, 15)
            let desplazadas = r.map { $0.desplazada(desplazamiento) }
            XCTAssertTrue(desplazadas.allSatisfy { (0..<5).contains($0.columna) && (0..<3).contains($0.fila) })
        }
    }
}
