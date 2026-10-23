// MARK: - CoordenadaAxial

/// Una casilla de una rejilla hexagonal, en coordenadas axiales `(q, r)`.
///
/// Es la coordenada de trabajo del paquete: todos los algoritmos (vecinos, distancias, líneas,
/// regiones, rotaciones, paso a píxeles) se escriben sobre ella. Las axiales son las cúbicas
/// `(q, r, s)` sin la tercera componente, que siempre vale `s = −q − r`; por eso se pueden sumar,
/// restar y multiplicar por un entero como vectores.
///
/// ```swift
/// let a = CoordenadaAxial(q: 1, r: -2)
/// a.s                          // 1
/// a.distancia(a: .origen)      // 2
/// a + CoordenadaAxial(q: 0, r: 1)   // (q: 1, r: -1)
/// ```
///
/// Las mismas coordenadas valen para hexágonos puntiagudos y planos: la orientación solo importa
/// al dibujar (``Disposicion``) y en las coordenadas desplazadas y dobladas.
public struct CoordenadaAxial: Hashable, Sendable, Codable {
    /// La columna (el eje q).
    public var q: Int
    /// La fila (el eje r).
    public var r: Int

    public init(q: Int, r: Int) {
        self.q = q
        self.r = r
    }

    /// La casilla `(q, r)`, sin etiquetas: `CoordenadaAxial(1, -2)`.
    public init(_ q: Int, _ r: Int) {
        self.init(q: q, r: r)
    }

    /// La tercera coordenada cúbica, `−q − r`.
    public var s: Int { -q - r }

    /// La casilla `(0, 0)`.
    public static let origen = CoordenadaAxial(q: 0, r: 0)
}

extension CoordenadaAxial: CustomStringConvertible {
    public var description: String { "(q: \(q), r: \(r))" }
}

// MARK: - Aritmética

extension CoordenadaAxial {
    public static func + (a: CoordenadaAxial, b: CoordenadaAxial) -> CoordenadaAxial {
        CoordenadaAxial(q: a.q + b.q, r: a.r + b.r)
    }

    public static func - (a: CoordenadaAxial, b: CoordenadaAxial) -> CoordenadaAxial {
        CoordenadaAxial(q: a.q - b.q, r: a.r - b.r)
    }

    public static prefix func - (a: CoordenadaAxial) -> CoordenadaAxial {
        CoordenadaAxial(q: -a.q, r: -a.r)
    }

    public static func * (a: CoordenadaAxial, k: Int) -> CoordenadaAxial {
        CoordenadaAxial(q: a.q * k, r: a.r * k)
    }

    public static func * (k: Int, a: CoordenadaAxial) -> CoordenadaAxial {
        a * k
    }

    public static func += (a: inout CoordenadaAxial, b: CoordenadaAxial) { a = a + b }
    public static func -= (a: inout CoordenadaAxial, b: CoordenadaAxial) { a = a - b }
}

// MARK: - Vecinos

extension CoordenadaAxial {
    /// Los seis pasos a una casilla vecina, numerados del 0 al 5 en sentido antihorario en pantalla
    /// (con el eje y hacia abajo), como en la guía de Red Blob Games:
    ///
    /// | Número | Paso      | Puntiaguda | Plana     |
    /// |-------:|-----------|------------|-----------|
    /// |      0 | (+1,  0)  | este       | sureste   |
    /// |      1 | (+1, −1)  | noreste    | noreste   |
    /// |      2 | ( 0, −1)  | noroeste   | norte     |
    /// |      3 | (−1,  0)  | oeste      | noroeste  |
    /// |      4 | (−1, +1)  | suroeste   | suroeste  |
    /// |      5 | ( 0, +1)  | sureste    | sur       |
    public static let direcciones: [CoordenadaAxial] = [
        CoordenadaAxial(q: 1, r: 0), CoordenadaAxial(q: 1, r: -1), CoordenadaAxial(q: 0, r: -1),
        CoordenadaAxial(q: -1, r: 0), CoordenadaAxial(q: -1, r: 1), CoordenadaAxial(q: 0, r: 1),
    ]

    /// Los seis pasos a una casilla diagonal: las que están a distancia 2 cruzando la arista que
    /// separa dos vecinas. La diagonal `i` queda entre las direcciones `i` e `i + 1`.
    public static let diagonales: [CoordenadaAxial] = [
        CoordenadaAxial(q: 2, r: -1), CoordenadaAxial(q: 1, r: -2), CoordenadaAxial(q: -1, r: -1),
        CoordenadaAxial(q: -2, r: 1), CoordenadaAxial(q: -1, r: 2), CoordenadaAxial(q: 1, r: 1),
    ]

    /// La vecina en la dirección número `direccion` (de ``direcciones``; cualquier entero vale, se toma
    /// módulo 6). Con nombre, `vecino(_: DireccionHexagonal)`.
    public func vecino(_ direccion: Int) -> CoordenadaAxial {
        self + Self.direcciones[modulo(direccion, 6)]
    }

    /// Las seis vecinas, en el orden de ``direcciones``.
    public var vecinos: [CoordenadaAxial] {
        Self.direcciones.map { self + $0 }
    }

    /// La casilla diagonal número `diagonal` (de ``diagonales``, módulo 6).
    public func vecinoDiagonal(_ diagonal: Int) -> CoordenadaAxial {
        self + Self.diagonales[modulo(diagonal, 6)]
    }

    /// Las seis casillas diagonales, en el orden de ``diagonales``.
    public var vecinosDiagonales: [CoordenadaAxial] {
        Self.diagonales.map { self + $0 }
    }

    /// La dirección que lleva a `otra`, si es vecina; `nil` si no lo es.
    public func direccion(hacia otra: CoordenadaAxial) -> DireccionHexagonal? {
        Self.direcciones.firstIndex(of: otra - self).map(DireccionHexagonal.init(numero:))
    }

    /// Si `otra` es una de las seis vecinas.
    public func esVecina(de otra: CoordenadaAxial) -> Bool {
        distancia(a: otra) == 1
    }
}

// MARK: - Distancias

extension CoordenadaAxial {
    /// Los pasos que hay desde el origen: `max(|q|, |r|, |s|)`.
    public var longitud: Int {
        max(abs(q), abs(r), abs(s))
    }

    /// Los pasos entre las dos casillas (el menor número de vecinas que hay que recorrer).
    public func distancia(a otra: CoordenadaAxial) -> Int {
        (self - otra).longitud
    }
}

/// Módulo no negativo para divisor positivo: `modulo(-1, 6) == 5`.
func modulo(_ a: Int, _ b: Int) -> Int {
    let resto = a % b
    return resto < 0 ? resto + b : resto
}
