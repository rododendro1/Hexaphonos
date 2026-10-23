// MARK: - Caminos con coste

/// Un camino por la rejilla y lo que cuesta recorrerlo.
public struct CaminoHexagonal: Hashable, Sendable {
    /// Las casillas, de la de salida a la de llegada (las dos incluidas); cada una es vecina de la anterior.
    public let casillas: [CoordenadaAxial]
    /// La suma de los costes de cada paso.
    public let coste: Double

    public init(casillas: [CoordenadaAxial], coste: Double) {
        self.casillas = casillas
        self.coste = coste
    }

    /// Cuántos pasos tiene (una casilla menos que ``casillas``).
    public var pasos: Int { casillas.count - 1 }
}

extension CoordenadaAxial {
    /// El camino más barato hasta `destino` cuando cada paso cuesta algo distinto (un pantano más que
    /// un camino, una subida más que una bajada): el algoritmo A*.
    ///
    /// `coste(desde, hacia)` es lo que cuesta pasar de una casilla a su vecina, o `nil` si no se puede
    /// (un muro, o fuera del mapa). Tiene que ser `≥ 0`.
    ///
    /// ```swift
    /// let pantano: Set = [CoordenadaAxial(q: 1, r: 0)]
    /// let camino = CoordenadaAxial.origen.caminoMasBarato(hasta: CoordenadaAxial(q: 2, r: 0)) { _, hacia in
    ///     hacia.longitud > 4 ? nil : (pantano.contains(hacia) ? 5 : 1)
    /// }
    /// camino?.coste   // 3.0
    /// ```
    ///
    /// - Parameters:
    ///   - costeMinimo: lo menos que cuesta un paso. Con `0`, es el algoritmo de Dijkstra; cuanto más
    ///     se acerque al coste real, menos casillas se miran. Si algún paso cuesta menos, el camino
    ///     puede no ser el más barato.
    ///   - presupuesto: lo más que se puede gastar; se deja de buscar por encima.
    /// - Returns: `nil` si no hay camino que quepa en el `presupuesto`. Entre caminos igual de baratos,
    ///   uno cualquiera, pero siempre el mismo.
    ///
    /// Si se busca sin presupuesto, `coste` tiene que dar `nil` fuera de una región finita: si no, y
    /// `destino` no se puede alcanzar, la búsqueda no termina.
    public func caminoMasBarato(hasta destino: CoordenadaAxial, costeMinimo: Double = 0,
                                presupuesto: Double = .infinity,
                                coste: (_ desde: CoordenadaAxial, _ hacia: CoordenadaAxial) -> Double?)
        -> CaminoHexagonal? {
        precondition(costeMinimo >= 0, "El coste mínimo no puede ser negativo (\(costeMinimo))")
        func estimado(_ casilla: CoordenadaAxial) -> Double { costeMinimo * Double(casilla.distancia(hasta: destino)) }

        var gastado: [CoordenadaAxial: Double] = [self: 0]
        var previa: [CoordenadaAxial: CoordenadaAxial] = [:]
        var cerradas: Set<CoordenadaAxial> = []
        var pendientes = MonticuloDeMinimos<CoordenadaAxial>()
        pendientes.insertar(self, clave: estimado(self))
        while let siguiente = pendientes.extraer() {
            let (clave, casilla) = siguiente
            guard clave <= presupuesto else { return nil }
            guard cerradas.insert(casilla).inserted else { continue }
            let hastaAqui = gastado[casilla]!
            if casilla == destino {
                var recorrido = [destino]
                var actual = destino
                while let anterior = previa[actual] {
                    recorrido.append(anterior)
                    actual = anterior
                }
                return CaminoHexagonal(casillas: recorrido.reversed(), coste: hastaAqui)
            }
            for vecina in casilla.vecinos where !cerradas.contains(vecina) {
                guard let paso = coste(casilla, vecina) else { continue }
                precondition(paso >= 0, "Un paso no puede costar menos de 0 (\(casilla) → \(vecina): \(paso))")
                let total = hastaAqui + paso
                guard total <= presupuesto, total < gastado[vecina, default: .infinity] else { continue }
                gastado[vecina] = total
                previa[vecina] = casilla
                pendientes.insertar(vecina, clave: total + estimado(vecina))
            }
        }
        return nil
    }

    /// Las casillas a las que se llega gastando `presupuesto` o menos, con lo que cuesta llegar a cada
    /// una por el camino más barato (esta, con 0): el algoritmo de Dijkstra.
    ///
    /// Es ``alcanzables(movimientos:bloqueada:)`` con un coste distinto en cada paso: `coste(desde, hacia)`
    /// es lo que cuesta pasar de una casilla a su vecina (`≥ 0`), o `nil` si no se puede.
    ///
    /// ```swift
    /// let costes = CoordenadaAxial.origen.alcanzables(presupuesto: 2) { _, hacia in
    ///     hacia.q > 0 ? 2 : 1
    /// }
    /// costes[CoordenadaAxial(q: -2, r: 0)]   // 2.0
    /// costes[CoordenadaAxial(q: 2, r: 0)]    // nil
    /// ```
    public func alcanzables(presupuesto: Double,
                            coste: (_ desde: CoordenadaAxial, _ hacia: CoordenadaAxial) -> Double?)
        -> [CoordenadaAxial: Double] {
        precondition(presupuesto >= 0, "El presupuesto no puede ser negativo (\(presupuesto))")
        var gastado: [CoordenadaAxial: Double] = [self: 0]
        var cerradas: Set<CoordenadaAxial> = []
        var pendientes = MonticuloDeMinimos<CoordenadaAxial>()
        pendientes.insertar(self, clave: 0)
        while let siguiente = pendientes.extraer() {
            let (hastaAqui, casilla) = siguiente
            guard cerradas.insert(casilla).inserted else { continue }
            for vecina in casilla.vecinos where !cerradas.contains(vecina) {
                guard let paso = coste(casilla, vecina) else { continue }
                precondition(paso >= 0, "Un paso no puede costar menos de 0 (\(casilla) → \(vecina): \(paso))")
                let total = hastaAqui + paso
                guard total <= presupuesto, total < gastado[vecina, default: .infinity] else { continue }
                gastado[vecina] = total
                pendientes.insertar(vecina, clave: total)
            }
        }
        return gastado
    }
}

// MARK: - Montículo

/// Una cola de prioridad: saca primero el elemento de clave más baja y, entre claves iguales, el que
/// entró antes (así los caminos no dependen del azar).
struct MonticuloDeMinimos<Elemento> {
    private var nodos: [(clave: Double, orden: Int, elemento: Elemento)] = []
    private var insertados = 0

    var estaVacio: Bool { nodos.isEmpty }
    var count: Int { nodos.count }

    private func antes(_ i: Int, _ j: Int) -> Bool {
        nodos[i].clave < nodos[j].clave || (nodos[i].clave == nodos[j].clave && nodos[i].orden < nodos[j].orden)
    }

    mutating func insertar(_ elemento: Elemento, clave: Double) {
        nodos.append((clave, insertados, elemento))
        insertados += 1
        var hijo = nodos.count - 1
        while hijo > 0 {
            let padre = (hijo - 1) / 2
            guard antes(hijo, padre) else { break }
            nodos.swapAt(hijo, padre)
            hijo = padre
        }
    }

    mutating func extraer() -> (clave: Double, elemento: Elemento)? {
        guard !nodos.isEmpty else { return nil }
        nodos.swapAt(0, nodos.count - 1)
        let primero = nodos.removeLast()
        var padre = 0
        while true {
            let izquierdo = 2 * padre + 1, derecho = izquierdo + 1
            var menor = padre
            if izquierdo < nodos.count && antes(izquierdo, menor) { menor = izquierdo }
            if derecho < nodos.count && antes(derecho, menor) { menor = derecho }
            if menor == padre { break }
            nodos.swapAt(padre, menor)
            padre = menor
        }
        return (primero.clave, primero.elemento)
    }
}
