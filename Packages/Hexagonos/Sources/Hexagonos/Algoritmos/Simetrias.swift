// MARK: - Ejes

/// Uno de los tres ejes de las coordenadas cúbicas.
public enum Eje: String, CaseIterable, Hashable, Sendable, Codable {
    case q, r, s
}

// MARK: - Rotaciones y reflexiones

extension CoordenadaAxial {
    /// La casilla girada 60° en sentido horario en pantalla (con el eje y hacia abajo) alrededor de
    /// `centro`: en cúbicas, `(q, r, s) → (−r, −s, −q)`. Lleva la dirección `i` a la `i − 1`.
    public func rotadaEnSentidoHorario(alrededorDe centro: CoordenadaAxial = .origen) -> CoordenadaAxial {
        let v = self - centro
        return centro + CoordenadaAxial(q: -v.r, r: -v.s)
    }

    /// La casilla girada 60° en sentido antihorario alrededor de `centro`: `(q, r, s) → (−s, −q, −r)`.
    /// Lleva la dirección `i` a la `i + 1`.
    public func rotadaEnSentidoAntihorario(alrededorDe centro: CoordenadaAxial = .origen) -> CoordenadaAxial {
        let v = self - centro
        return centro + CoordenadaAxial(q: -v.s, r: -v.q)
    }

    /// La casilla girada `sextos` veces 60° alrededor de `centro`: los positivos, en sentido antihorario
    /// (como las direcciones); los negativos, en sentido horario. Seis sextos dan la vuelta entera.
    public func rotada(sextos: Int, alrededorDe centro: CoordenadaAxial = .origen) -> CoordenadaAxial {
        var casilla = self
        for _ in 0..<modulo(sextos, 6) {
            casilla = casilla.rotadaEnSentidoAntihorario(alrededorDe: centro)
        }
        return casilla
    }

    /// La casilla reflejada sobre la recta del `eje` que pasa por `centro`: esa componente se queda y
    /// las otras dos se intercambian. Sobre `q`, `(q, r, s) → (q, s, r)`.
    public func reflejada(sobre eje: Eje, alrededorDe centro: CoordenadaAxial = .origen) -> CoordenadaAxial {
        let v = self - centro
        switch eje {
        case .q: return centro + CoordenadaAxial(q: v.q, r: v.s)
        case .r: return centro + CoordenadaAxial(q: v.s, r: v.r)
        case .s: return centro + CoordenadaAxial(q: v.r, r: v.q)
        }
    }
}
