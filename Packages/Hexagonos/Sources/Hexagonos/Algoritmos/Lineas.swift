// MARK: - Líneas y visibilidad

extension CoordenadaAxial {
    /// Las casillas de la recta que va de esta a `destino`, las dos incluidas y en orden.
    ///
    /// Hay `distancia(a: destino) + 1` casillas y cada una es vecina de la anterior. Se toman puntos
    /// equiespaciados del segmento entre los centros y se redondean; los extremos se empujan una
    /// millonésima para que un punto que cae justo en una arista no salte de un lado a otro.
    ///
    /// ```swift
    /// CoordenadaAxial.origen.linea(hasta: CoordenadaAxial(q: 3, r: 0))
    /// // [(q: 0, r: 0), (q: 1, r: 0), (q: 2, r: 0), (q: 3, r: 0)]
    /// ```
    public func linea(hasta destino: CoordenadaAxial) -> [CoordenadaAxial] {
        let pasos = distancia(a: destino)
        if pasos == 0 { return [self] }
        var desde = CoordenadaFraccionaria(self)
        var hasta = CoordenadaFraccionaria(destino)
        // El mismo empujón en los dos extremos: q + 1e-6, r + 2e-6 (y s − 3e-6).
        desde.q += 1e-6; desde.r += 2e-6
        hasta.q += 1e-6; hasta.r += 2e-6
        return (0...pasos).map { i in
            CoordenadaFraccionaria.interpolar(desde, hasta, Double(i) / Double(pasos)).redondeada()
        }
    }

    /// Si desde esta casilla se ve `destino`: ninguna casilla de la línea entre las dos (sin contar
    /// los extremos) está tapada.
    public func ve(_ destino: CoordenadaAxial, tapada: (CoordenadaAxial) -> Bool) -> Bool {
        linea(hasta: destino).dropFirst().dropLast().allSatisfy { !tapada($0) }
    }

    /// Las casillas de `region` que se ven desde esta (las tapadas no se ven, pero tapan).
    public func visibles(en region: some Sequence<CoordenadaAxial>,
                         tapada: (CoordenadaAxial) -> Bool) -> [CoordenadaAxial] {
        region.filter { !tapada($0) && ve($0, tapada: tapada) }
    }
}
