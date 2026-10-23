// MARK: - CoordenadaFraccionaria

/// Un punto cualquiera del plano en coordenadas axiales con decimales.
///
/// Sale de convertir un píxel (``Disposicion/coordenada(en:)``) o de interpolar entre dos casillas,
/// y vuelve a una casilla con ``redondeada()``. La tercera componente es `s = −q − r`, como en las
/// enteras.
public struct CoordenadaFraccionaria: Hashable, Sendable, Codable {
    public var q: Double
    public var r: Double

    public init(q: Double, r: Double) {
        self.q = q
        self.r = r
    }

    /// El centro de una casilla.
    public init(_ axial: CoordenadaAxial) {
        self.init(q: Double(axial.q), r: Double(axial.r))
    }

    public var s: Double { -q - r }

    /// La casilla que contiene el punto.
    ///
    /// Redondea las tres componentes cúbicas y corrige la que más se ha movido, para que vuelvan a
    /// sumar cero: redondear `q` y `r` por separado daría casillas equivocadas cerca de los bordes.
    public func redondeada() -> CoordenadaAxial {
        var rq = q.rounded()
        var rr = r.rounded()
        let rs = s.rounded()
        let dq = abs(rq - q)
        let dr = abs(rr - r)
        let ds = abs(rs - s)
        if dq > dr && dq > ds {
            rq = -rr - rs
        } else if dr > ds {
            rr = -rq - rs
        }
        // Si la que más se movió es `s`, basta con `q` y `r`: la axial no guarda `s`.
        return CoordenadaAxial(q: Int(rq), r: Int(rr))
    }

    /// El punto a la fracción `t` del camino de `a` a `b` (`t = 0` es `a`, `t = 1` es `b`).
    public static func interpolar(_ a: CoordenadaFraccionaria, _ b: CoordenadaFraccionaria,
                                  _ t: Double) -> CoordenadaFraccionaria {
        CoordenadaFraccionaria(q: a.q + (b.q - a.q) * t, r: a.r + (b.r - a.r) * t)
    }
}

extension CoordenadaFraccionaria: CustomStringConvertible {
    public var description: String { "(q: \(q), r: \(r))" }
}
