// MARK: - Desplazamiento

/// Cuál de las filas o columnas se desplaza media casilla en las coordenadas desplazadas (*offset*).
///
/// Con hexágonos puntiagudos las filas quedan rectas y se desplazan filas alternas; con hexágonos
/// planos, columnas alternas. «Impares» y «pares» dicen cuáles se empujan hacia fuera (hacia la
/// derecha en las filas, hacia abajo en las columnas).
public enum Desplazamiento: String, CaseIterable, Hashable, Sendable, Codable {
    /// Puntiagudos; las filas impares, media casilla a la derecha (*odd-r*).
    case filasImpares
    /// Puntiagudos; las filas pares, media casilla a la derecha (*even-r*).
    case filasPares
    /// Planos; las columnas impares, media casilla hacia abajo (*odd-q*).
    case columnasImpares
    /// Planos; las columnas pares, media casilla hacia abajo (*even-q*).
    case columnasPares

    /// La orientación de los hexágonos con la que se usa.
    public var orientacion: Orientacion {
        switch self {
        case .filasImpares, .filasPares: return .puntiaguda
        case .columnasImpares, .columnasPares: return .plana
        }
    }
}

// MARK: - CoordenadaDesplazada

/// Una casilla en coordenadas desplazadas `(columna, fila)`: la rejilla como una tabla rectangular
/// en la que filas (o columnas) alternas se empujan media casilla.
///
/// Son cómodas para guardar un mapa rectangular en una matriz, pero no se suman como vectores: los
/// vecinos dependen de si la fila es par o impar. Para cualquier cálculo, se pasan a axiales:
///
/// ```swift
/// let d = CoordenadaDesplazada(columna: 3, fila: 1)
/// let a = d.axial(.filasImpares)        // (q: 3, r: 1)
/// a.desplazada(.filasPares)             // (columna: 4, fila: 1)
/// ```
///
/// La conversión necesita saber qué ``Desplazamiento`` se usa: la misma pareja de números es una
/// casilla distinta en cada uno.
public struct CoordenadaDesplazada: Hashable, Sendable, Codable {
    public var columna: Int
    public var fila: Int

    public init(columna: Int, fila: Int) {
        self.columna = columna
        self.fila = fila
    }

    /// La misma casilla en coordenadas axiales.
    public func axial(_ desplazamiento: Desplazamiento) -> CoordenadaAxial {
        CoordenadaAxial(self, desplazamiento)
    }

    /// Las seis vecinas, en coordenadas desplazadas y en el orden de ``CoordenadaAxial/direcciones``.
    public func vecinos(_ desplazamiento: Desplazamiento) -> [CoordenadaDesplazada] {
        axial(desplazamiento).vecinos.map { $0.desplazada(desplazamiento) }
    }

    /// Los pasos hasta `otra`.
    public func distancia(hasta otra: CoordenadaDesplazada, _ desplazamiento: Desplazamiento) -> Int {
        axial(desplazamiento).distancia(hasta: otra.axial(desplazamiento))
    }

    @available(*, deprecated, renamed: "distancia(hasta:_:)")
    public func distancia(a otra: CoordenadaDesplazada, _ desplazamiento: Desplazamiento) -> Int {
        distancia(hasta: otra, desplazamiento)
    }
}

extension CoordenadaDesplazada: CustomStringConvertible {
    public var description: String { "(columna: \(columna), fila: \(fila))" }
}

extension CoordenadaAxial {
    /// La casilla que ocupa `desplazada` con ese desplazamiento.
    public init(_ desplazada: CoordenadaDesplazada, _ desplazamiento: Desplazamiento) {
        let (columna, fila) = (desplazada.columna, desplazada.fila)
        // `& 1` es 0 o 1 también para los negativos (complemento a dos), y `n ∓ (n & 1)` siempre es par.
        switch desplazamiento {
        case .filasImpares:
            self.init(q: columna - (fila - (fila & 1)) / 2, r: fila)
        case .filasPares:
            self.init(q: columna - (fila + (fila & 1)) / 2, r: fila)
        case .columnasImpares:
            self.init(q: columna, r: fila - (columna - (columna & 1)) / 2)
        case .columnasPares:
            self.init(q: columna, r: fila - (columna + (columna & 1)) / 2)
        }
    }

    /// La misma casilla en coordenadas desplazadas.
    public func desplazada(_ desplazamiento: Desplazamiento) -> CoordenadaDesplazada {
        switch desplazamiento {
        case .filasImpares:
            return CoordenadaDesplazada(columna: q + (r - (r & 1)) / 2, fila: r)
        case .filasPares:
            return CoordenadaDesplazada(columna: q + (r + (r & 1)) / 2, fila: r)
        case .columnasImpares:
            return CoordenadaDesplazada(columna: q, fila: r + (q - (q & 1)) / 2)
        case .columnasPares:
            return CoordenadaDesplazada(columna: q, fila: r + (q + (q & 1)) / 2)
        }
    }
}
