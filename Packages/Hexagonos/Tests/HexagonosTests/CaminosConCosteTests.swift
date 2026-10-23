import XCTest
@testable import Hexagonos

final class CaminosConCosteTests: XCTestCase {
    /// Un terreno de prueba: cada casilla cuesta de 1 a 4, sin azar, y algunas son muros.
    private let mapa = FormasDeMapa.hexagono(radio: 6)
    private func terreno(_ c: CoordenadaAxial) -> Double? {
        guard c.longitud <= 6 else { return nil }
        let n = modulo(c.q * 7 + c.r * 13, 11)
        return n == 0 ? nil : Double(1 + n % 4)
    }

    /// Los costes de llegar a cada casilla calculados a lo bruto: relajando hasta que nada cambia.
    private func costesALoBruto(desde origen: CoordenadaAxial) -> [CoordenadaAxial: Double] {
        var costes: [CoordenadaAxial: Double] = [origen: 0]
        var cambia = true
        while cambia {
            cambia = false
            for casilla in mapa {
                guard let hastaAqui = costes[casilla] else { continue }
                for vecina in casilla.vecinos {
                    guard let paso = terreno(vecina) else { continue }
                    if hastaAqui + paso < costes[vecina, default: .infinity] {
                        costes[vecina] = hastaAqui + paso
                        cambia = true
                    }
                }
            }
        }
        return costes
    }

    func testMonticulo() {
        var monticulo = MonticuloDeMinimos<String>()
        for (clave, texto) in [(3.0, "c"), (1, "a"), (2, "b1"), (5, "e"), (2, "b2"), (0, "0")] {
            monticulo.insertar(texto, clave: clave)
        }
        XCTAssertEqual(monticulo.count, 6)
        var salida: [String] = []
        while let siguiente = monticulo.extraer() { salida.append(siguiente.elemento) }
        XCTAssertEqual(salida, ["0", "a", "b1", "b2", "c", "e"])
        XCTAssertTrue(monticulo.estaVacio)
    }

    func testSinCostesEsElCaminoMasCorto() {
        let camino = CoordenadaAxial.origen.caminoMasBarato(hasta: CoordenadaAxial(q: 3, r: -1)) { _, hacia in
            hacia.longitud <= 5 ? 1 : nil
        }
        XCTAssertEqual(camino?.pasos, 3)
        XCTAssertEqual(camino?.coste, 3)
        XCTAssertEqual(camino?.casillas.first, .origen)
        XCTAssertEqual(camino?.casillas.last, CoordenadaAxial(q: 3, r: -1))
        let vacio = CoordenadaAxial.origen.caminoMasBarato(hasta: .origen) { _, _ in 1 }
        XCTAssertEqual(vacio, CaminoHexagonal(casillas: [.origen], coste: 0))
    }

    func testRodeaLoCaro() {
        let pantano: Set = [CoordenadaAxial(q: 1, r: 0)]
        let camino = CoordenadaAxial.origen.caminoMasBarato(hasta: CoordenadaAxial(q: 2, r: 0)) { _, hacia in
            hacia.longitud > 4 ? nil : (pantano.contains(hacia) ? 5 : 1)
        }
        XCTAssertEqual(camino?.coste, 3)
        XCTAssertEqual(camino?.pasos, 3)
        XCTAssertFalse(camino?.casillas.contains(CoordenadaAxial(q: 1, r: 0)) ?? true)
    }

    func testCuestaLoMismoQueALoBruto() {
        let origen = CoordenadaAxial(q: -2, r: 1)
        let costes = costesALoBruto(desde: origen)
        for destino in mapa {
            for costeMinimo in [0.0, 1] {
                let encontrado = origen.caminoMasBarato(hasta: destino, costeMinimo: costeMinimo) { _, hacia in
                    self.terreno(hacia)
                }
                guard let esperado = costes[destino] else {
                    XCTAssertNil(encontrado, "\(destino)")
                    continue
                }
                guard let camino = encontrado else { return XCTFail("Sin camino a \(destino)") }
                XCTAssertEqual(camino.coste, esperado, "\(destino)")
                // El coste es el de sus pasos, y cada paso va a una vecina.
                XCTAssertEqual(camino.casillas.dropFirst().reduce(0) { $0 + terreno($1)! }, camino.coste)
                for (a, b) in zip(camino.casillas, camino.casillas.dropFirst()) {
                    XCTAssertEqual(a.distancia(hasta: b), 1)
                }
            }
        }
        let alcanzables = origen.alcanzables(presupuesto: .infinity) { _, hacia in self.terreno(hacia) }
        XCTAssertEqual(alcanzables, costes)
    }

    func testSiempreElMismoCamino() {
        let destino = CoordenadaAxial(q: 4, r: -2)
        let caminos = (0..<5).map { _ in
            CoordenadaAxial.origen.caminoMasBarato(hasta: destino) { _, hacia in hacia.longitud <= 6 ? 1 : nil }
        }
        XCTAssertTrue(caminos.allSatisfy { $0 == caminos[0] })
    }

    func testPresupuesto() {
        let destino = CoordenadaAxial(q: 4, r: 0)
        let barato = { (_: CoordenadaAxial, _: CoordenadaAxial) -> Double? in 2 }
        XCTAssertEqual(CoordenadaAxial.origen.caminoMasBarato(hasta: destino, presupuesto: 8, coste: barato)?.coste, 8)
        XCTAssertNil(CoordenadaAxial.origen.caminoMasBarato(hasta: destino, presupuesto: 7.9, coste: barato))
        // Sin región finita, el presupuesto hace que termine aunque no se pueda llegar.
        XCTAssertNil(CoordenadaAxial.origen.caminoMasBarato(hasta: destino, presupuesto: 20) { _, hacia in
            hacia == destino ? nil : 1
        })
    }

    func testAlcanzablesConCoste() {
        // Con todos los pasos a 1, son los de la búsqueda en anchura.
        let muro: Set = [CoordenadaAxial(q: 1, r: -1), CoordenadaAxial(q: 1, r: 0), CoordenadaAxial(q: 0, r: 1)]
        let porPasos = CoordenadaAxial.origen.alcanzables(movimientos: 4) { muro.contains($0) }
        let porCoste = CoordenadaAxial.origen.alcanzables(presupuesto: 4) { _, hacia in muro.contains(hacia) ? nil : 1 }
        XCTAssertEqual(porCoste, porPasos.mapValues { Double($0) })

        let costes = CoordenadaAxial.origen.alcanzables(presupuesto: 2) { _, hacia in hacia.q > 0 ? 2 : 1 }
        XCTAssertEqual(costes[.origen], 0)
        XCTAssertEqual(costes[CoordenadaAxial(q: -2, r: 0)], 2)
        XCTAssertEqual(costes[CoordenadaAxial(q: 1, r: 0)], 2)
        XCTAssertNil(costes[CoordenadaAxial(q: 2, r: 0)])
        XCTAssertTrue(costes.values.allSatisfy { $0 <= 2 })
        XCTAssertEqual(CoordenadaAxial.origen.alcanzables(presupuesto: 0) { _, _ in 1 }, [.origen: 0])
    }
}
