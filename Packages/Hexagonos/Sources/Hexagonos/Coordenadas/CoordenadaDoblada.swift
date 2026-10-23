// MARK: - Doblado

/// Qué eje se dobla en las coordenadas dobladas.
public enum Doblado: String, CaseIterable, Hashable, Sendable, Codable {
    /// Puntiagudos: la columna avanza de dos en dos por fila (*doubled-width*).
    case anchoDoble
    /// Planos: la fila avanza de dos en dos por columna (*doubled-height*).
    case altoDoble

    /// La orientación de los hexágonos con la que se usa.
    public var orientacion: Orientacion {
        self == .anchoDoble ? .puntiaguda : .plana
    }
}

// MARK: - CoordenadaDoblada

/// Una casilla en coordenadas dobladas `(columna, fila)`.
///
/// Como las desplazadas, dibujan la rejilla como una tabla rectangular, pero en vez de empujar filas
/// alternas cuentan uno de los ejes de dos en dos: solo valen las parejas con `columna + fila` par.
/// A cambio, los seis pasos a las vecinas son siempre los mismos, como en las axiales.
///
/// ```swift
/// let a = CoordenadaAxial(q: 1, r: 2)
/// a.doblada(.anchoDoble)                                             // (columna: 4, fila: 2)
/// CoordenadaAxial(CoordenadaDoblada(columna: 4, fila: 2), .anchoDoble)   // (q: 1, r: 2)
/// ```
public struct CoordenadaDoblada: Hashable, Sendable, Codable {
    public var columna: Int
    public var fila: Int

    public init(columna: Int, fila: Int) {
        self.columna = columna
        self.fila = fila
    }

    /// Si es una casilla de verdad: `columna + fila` tiene que ser par.
    public var esValida: Bool { (columna + fila) % 2 == 0 }

    /// La misma casilla en coordenadas axiales. Tiene que ser válida (``esValida``).
    public func axial(_ doblado: Doblado) -> CoordenadaAxial {
        CoordenadaAxial(self, doblado)
    }

    /// Las seis vecinas, en el orden de ``CoordenadaAxial/direcciones``.
    public func vecinos(_ doblado: Doblado) -> [CoordenadaDoblada] {
        axial(doblado).vecinos.map { $0.doblada(doblado) }
    }

    /// Los pasos hasta `otra`, sin pasar por las axiales.
    public func distancia(hasta otra: CoordenadaDoblada, _ doblado: Doblado) -> Int {
        let dc = abs(columna - otra.columna)
        let df = abs(fila - otra.fila)
        switch doblado {
        case .anchoDoble: return df + max(0, (dc - df) / 2)
        case .altoDoble: return dc + max(0, (df - dc) / 2)
        }
    }

    @available(*, deprecated, renamed: "distancia(hasta:_:)")
    public func distancia(a otra: CoordenadaDoblada, _ doblado: Doblado) -> Int { distancia(hasta: otra, doblado) }
}

extension CoordenadaDoblada: CustomStringConvertible {
    public var description: String { "(columna: \(columna), fila: \(fila))" }
}

extension CoordenadaAxial {
    /// La casilla que ocupa `doblada`, que tiene que ser válida (``CoordenadaDoblada/esValida``).
    public init(_ doblada: CoordenadaDoblada, _ doblado: Doblado) {
        precondition(doblada.esValida, "\(doblada) no es una casilla: columna + fila tiene que ser par")
        switch doblado {
        case .anchoDoble:
            self.init(q: (doblada.columna - doblada.fila) / 2, r: doblada.fila)
        case .altoDoble:
            self.init(q: doblada.columna, r: (doblada.fila - doblada.columna) / 2)
        }
    }

    /// La misma casilla en coordenadas dobladas.
    public func doblada(_ doblado: Doblado) -> CoordenadaDoblada {
        switch doblado {
        case .anchoDoble: return CoordenadaDoblada(columna: 2 * q + r, fila: r)
        case .altoDoble: return CoordenadaDoblada(columna: q, fila: 2 * r + q)
        }
    }
}
