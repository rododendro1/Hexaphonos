// MARK: - CoordenadaCubica

/// Una casilla en coordenadas cúbicas `(q, r, s)`, con `q + r + s = 0`.
///
/// Cada hexágono es un cubo del plano `x + y + z = 0`: los tres ejes son simétricos, y por eso
/// las rotaciones y reflexiones son permutaciones de las componentes con cambio de signo. Guardan lo
/// mismo que las axiales (``CoordenadaAxial``), con la tercera componente explícita.
///
/// ```swift
/// let c = CoordenadaCubica(q: 1, r: -3, s: 2)
/// c.axial                       // (q: 1, r: -3)
/// CoordenadaCubica(c.axial) == c   // true
/// ```
public struct CoordenadaCubica: Hashable, Sendable, Codable {
    public let q: Int
    public let r: Int
    public let s: Int

    /// La casilla `(q, r, s)`. Las tres tienen que sumar cero.
    public init(q: Int, r: Int, s: Int) {
        precondition(q + r + s == 0, "Las coordenadas cúbicas suman cero: \(q) + \(r) + \(s) = \(q + r + s)")
        self.q = q
        self.r = r
        self.s = s
    }

    /// La casilla `(q, r, s)`, o `nil` si las tres no suman cero.
    public init?(validando q: Int, _ r: Int, _ s: Int) {
        guard q + r + s == 0 else { return nil }
        self.init(q: q, r: r, s: s)
    }

    /// La misma casilla que una axial: `s = −q − r`.
    public init(_ axial: CoordenadaAxial) {
        self.init(q: axial.q, r: axial.r, s: axial.s)
    }

    /// La misma casilla en coordenadas axiales (sin `s`).
    public var axial: CoordenadaAxial {
        CoordenadaAxial(q: q, r: r)
    }

    /// La casilla `(0, 0, 0)`.
    public static let origen = CoordenadaCubica(q: 0, r: 0, s: 0)

    // `Decodable` comprueba también la suma: un JSON con `q + r + s ≠ 0` es un error, no una casilla.
    private enum CodingKeys: String, CodingKey { case q, r, s }

    public init(from decoder: Decoder) throws {
        let contenedor = try decoder.container(keyedBy: CodingKeys.self)
        let q = try contenedor.decode(Int.self, forKey: .q)
        let r = try contenedor.decode(Int.self, forKey: .r)
        let s = try contenedor.decode(Int.self, forKey: .s)
        guard q + r + s == 0 else {
            throw DecodingError.dataCorruptedError(forKey: .s, in: contenedor,
                                                   debugDescription: "q + r + s tiene que ser 0")
        }
        self.init(q: q, r: r, s: s)
    }
}

extension CoordenadaCubica: CustomStringConvertible {
    public var description: String { "(q: \(q), r: \(r), s: \(s))" }
}

extension CoordenadaCubica {
    public static func + (a: CoordenadaCubica, b: CoordenadaCubica) -> CoordenadaCubica {
        CoordenadaCubica(q: a.q + b.q, r: a.r + b.r, s: a.s + b.s)
    }

    public static func - (a: CoordenadaCubica, b: CoordenadaCubica) -> CoordenadaCubica {
        CoordenadaCubica(q: a.q - b.q, r: a.r - b.r, s: a.s - b.s)
    }

    public static func * (a: CoordenadaCubica, k: Int) -> CoordenadaCubica {
        CoordenadaCubica(q: a.q * k, r: a.r * k, s: a.s * k)
    }

    /// Los pasos desde el origen: `max(|q|, |r|, |s|)`, que es también `(|q| + |r| + |s|) / 2`.
    public var longitud: Int { max(abs(q), abs(r), abs(s)) }

    /// Los pasos entre las dos casillas.
    public func distancia(hasta otra: CoordenadaCubica) -> Int { (self - otra).longitud }

    @available(*, deprecated, renamed: "distancia(hasta:)")
    public func distancia(a otra: CoordenadaCubica) -> Int { distancia(hasta: otra) }

    /// Las seis vecinas, en el orden de ``CoordenadaAxial/direcciones``.
    public var vecinos: [CoordenadaCubica] { axial.vecinos.map { CoordenadaCubica($0) } }
}

extension CoordenadaAxial {
    /// La misma casilla que una cúbica (se olvida `s`).
    public init(_ cubica: CoordenadaCubica) {
        self.init(q: cubica.q, r: cubica.r)
    }

    /// La misma casilla en coordenadas cúbicas.
    public var cubica: CoordenadaCubica { CoordenadaCubica(self) }
}
