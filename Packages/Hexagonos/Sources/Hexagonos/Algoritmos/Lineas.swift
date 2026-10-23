// MARK: - Líneas y visibilidad

extension CoordenadaAxial {
    /// Las casillas de la recta que va de esta a `destino`, las dos incluidas y en orden.
    ///
    /// Hay `distancia(a: destino) + 1` casillas y cada una es vecina de la anterior. Se toman puntos
    /// equiespaciados del segmento entre los centros y se redondean; los extremos se empujan una
    /// millonésima para que un punto que cae justo en una arista no salte de un lado a otro. El empujón
    /// es el mismo en los dos extremos, así que la línea de vuelta es la de ida al revés.
    ///
    /// ```swift
    /// CoordenadaAxial.origen.linea(hasta: CoordenadaAxial(q: 3, r: 0))
    /// // [(q: 0, r: 0), (q: 1, r: 0), (q: 2, r: 0), (q: 3, r: 0)]
    /// ```
    public func linea(hasta destino: CoordenadaAxial) -> [CoordenadaAxial] {
        linea(hasta: destino, empujon: 1)
    }

    /// La línea con los extremos empujados `empujon` millonésimas hacia `(q + 1, r + 2, s − 3)`: con
    /// `1`, la de ``linea(hasta:)``; con `-1`, la del otro lado cuando la recta pasa por una arista.
    func linea(hasta destino: CoordenadaAxial, empujon: Double) -> [CoordenadaAxial] {
        let pasos = distancia(a: destino)
        if pasos == 0 { return [self] }
        var desde = CoordenadaFraccionaria(self)
        var hasta = CoordenadaFraccionaria(destino)
        // El mismo empujón en los dos extremos, para que la línea de vuelta sea la de ida al revés.
        desde.q += 1e-6 * empujon; desde.r += 2e-6 * empujon
        hasta.q += 1e-6 * empujon; hasta.r += 2e-6 * empujon
        return (0...pasos).map { i in
            CoordenadaFraccionaria.interpolar(desde, hasta, Double(i) / Double(pasos)).redondeada()
        }
    }

    /// Si desde esta casilla se ve `destino`: ninguna casilla entre las dos (sin contar los extremos)
    /// está tapada.
    ///
    /// Cuando la recta pasa justo por una arista, ``linea(hasta:)`` elige uno de los dos lados; aquí
    /// basta con que uno de ellos esté libre. Así la visibilidad es simétrica: `a` ve a `b` si y solo
    /// si `b` ve a `a`, y girar o reflejar el mapa entero (con sus casillas tapadas) no la cambia.
    public func ve(_ destino: CoordenadaAxial, tapada: (CoordenadaAxial) -> Bool) -> Bool {
        func libre(_ empujon: Double) -> Bool {
            linea(hasta: destino, empujon: empujon).dropFirst().dropLast().allSatisfy { !tapada($0) }
        }
        return libre(1) || libre(-1)
    }

    /// Las casillas de `region` que se ven desde esta (las tapadas no se ven, pero tapan).
    public func visibles(en region: some Sequence<CoordenadaAxial>,
                         tapada: (CoordenadaAxial) -> Bool) -> [CoordenadaAxial] {
        region.filter { !tapada($0) && ve($0, tapada: tapada) }
    }
}
