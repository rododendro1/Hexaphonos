// MARK: - Alcances, anillos y espirales

extension CoordenadaAxial {
    /// Todas las casillas a `radio` pasos o menos: un hexágono de `3·radio·(radio + 1) + 1` casillas.
    ///
    /// Van por columnas (`q` creciente) y, dentro de cada una, por `r` creciente.
    public func alcance(radio: Int) -> [CoordenadaAxial] {
        precondition(radio >= 0, "El radio no puede ser negativo (\(radio))")
        var casillas: [CoordenadaAxial] = []
        casillas.reserveCapacity(3 * radio * (radio + 1) + 1)
        for dq in -radio...radio {
            for dr in max(-radio, -dq - radio)...min(radio, -dq + radio) {
                casillas.append(CoordenadaAxial(q: q + dq, r: r + dr))
            }
        }
        return casillas
    }

    /// Las casillas que están a la vez en todos los alcances: a `radio` pasos o menos de su `centro`.
    ///
    /// No genera cada alcance: recorta los límites de `q`, `r` y `s`, así que cuesta lo que mide la
    /// intersección. Vacía si los alcances no se tocan.
    public static func interseccion(de alcances: [(centro: CoordenadaAxial, radio: Int)]) -> [CoordenadaAxial] {
        precondition(!alcances.isEmpty, "La intersección necesita al menos un alcance")
        precondition(alcances.allSatisfy { $0.radio >= 0 }, "Los radios no pueden ser negativos")
        let qMinimo = alcances.map { $0.centro.q - $0.radio }.max()!
        let qMaximo = alcances.map { $0.centro.q + $0.radio }.min()!
        let rMinimo = alcances.map { $0.centro.r - $0.radio }.max()!
        let rMaximo = alcances.map { $0.centro.r + $0.radio }.min()!
        let sMinimo = alcances.map { $0.centro.s - $0.radio }.max()!
        let sMaximo = alcances.map { $0.centro.s + $0.radio }.min()!
        guard qMinimo <= qMaximo else { return [] }
        var casillas: [CoordenadaAxial] = []
        for q in qMinimo...qMaximo {
            let desde = max(rMinimo, -q - sMaximo)
            let hasta = min(rMaximo, -q - sMinimo)
            guard desde <= hasta else { continue }
            for r in desde...hasta {
                casillas.append(CoordenadaAxial(q: q, r: r))
            }
        }
        return casillas
    }

    /// Las casillas a exactamente `radio` pasos: `6·radio` casillas (solo esta si el radio es 0).
    ///
    /// Empiezan en `self + direcciones[4] · radio` y dan la vuelta recorriendo las direcciones 0 a 5,
    /// cada una `radio` veces, así que cada casilla es vecina de la anterior.
    public func anillo(radio: Int) -> [CoordenadaAxial] {
        precondition(radio >= 0, "El radio no puede ser negativo (\(radio))")
        if radio == 0 { return [self] }
        var casillas: [CoordenadaAxial] = []
        casillas.reserveCapacity(6 * radio)
        var casilla = self + Self.direcciones[4] * radio
        for direccion in 0..<6 {
            for _ in 0..<radio {
                casillas.append(casilla)
                casilla = casilla.vecino(direccion)
            }
        }
        return casillas
    }

    /// Las casillas del alcance de `radio`, del centro hacia fuera: esta, el anillo 1, el anillo 2…
    public func espiral(radio: Int) -> [CoordenadaAxial] {
        precondition(radio >= 0, "El radio no puede ser negativo (\(radio))")
        var casillas = [self]
        for anillo in stride(from: 1, through: radio, by: 1) {
            casillas += self.anillo(radio: anillo)
        }
        return casillas
    }
}

// MARK: - Movimiento con obstáculos

extension CoordenadaAxial {
    /// Las casillas a las que se llega desde esta en `movimientos` pasos o menos, sin pisar ninguna
    /// casilla `bloqueada`, con los pasos que cuesta llegar a cada una (esta, con 0).
    ///
    /// Es una búsqueda en anchura: a diferencia de ``alcance(radio:)``, rodea los obstáculos.
    public func alcanzables(movimientos: Int,
                            bloqueada: (CoordenadaAxial) -> Bool) -> [CoordenadaAxial: Int] {
        precondition(movimientos >= 0, "Los movimientos no pueden ser negativos (\(movimientos))")
        var pasos: [CoordenadaAxial: Int] = [self: 0]
        var frontera = [self]
        for k in stride(from: 1, through: movimientos, by: 1) {
            var siguiente: [CoordenadaAxial] = []
            for casilla in frontera {
                for vecina in casilla.vecinos where pasos[vecina] == nil && !bloqueada(vecina) {
                    pasos[vecina] = k
                    siguiente.append(vecina)
                }
            }
            if siguiente.isEmpty { break }
            frontera = siguiente
        }
        return pasos
    }

    /// El camino más corto hasta `destino` pasando solo por casillas de `transitables`: de esta a
    /// `destino`, las dos incluidas. `nil` si no hay camino o `destino` no es transitable.
    ///
    /// Esta casilla no tiene por qué ser transitable (es donde se está). Entre caminos igual de
    /// cortos, prefiere el que toma antes las direcciones más bajas de ``direcciones``.
    public func camino(hasta destino: CoordenadaAxial,
                       por transitables: Set<CoordenadaAxial>) -> [CoordenadaAxial]? {
        if destino == self { return [self] }
        guard transitables.contains(destino) else { return nil }
        var previa: [CoordenadaAxial: CoordenadaAxial] = [:]
        var frontera = [self]
        var vistas: Set<CoordenadaAxial> = [self]
        while !frontera.isEmpty {
            var siguiente: [CoordenadaAxial] = []
            for casilla in frontera {
                for vecina in casilla.vecinos where transitables.contains(vecina) {
                    guard vistas.insert(vecina).inserted else { continue }
                    previa[vecina] = casilla
                    if vecina == destino {
                        var recorrido = [destino]
                        var actual = destino
                        while let anterior = previa[actual] {
                            recorrido.append(anterior)
                            actual = anterior
                        }
                        return recorrido.reversed()
                    }
                    siguiente.append(vecina)
                }
            }
            frontera = siguiente
        }
        return nil
    }
}
