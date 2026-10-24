// MARK: - PuntoCardinal

/// Los ocho rumbos de la rosa de los vientos, con el norte arriba en pantalla.
public enum PuntoCardinal: String, CaseIterable, Hashable, Sendable, Codable {
    case norte, noreste, este, sureste, sur, suroeste, oeste, noroeste
}

// MARK: - DireccionHexagonal

/// Una de las seis direcciones hacia una casilla vecina.
///
/// Cada dirección suma 1 a una coordenada cúbica y resta 1 a otra, y el nombre lo dice:
/// ``qMasSMenos`` es el paso `(q + 1, r, s − 1)`. Así los nombres valen para las dos orientaciones,
/// mientras que el punto cardinal cambia (el este de los puntiagudos es el sureste de los planos):
///
/// | Número | Dirección        | Paso      | Puntiaguda | Plana     |
/// |-------:|------------------|-----------|------------|-----------|
/// |      0 | ``qMasSMenos``   | (+1,  0)  | este       | sureste   |
/// |      1 | ``qMasRMenos``   | (+1, −1)  | noreste    | noreste   |
/// |      2 | ``sMasRMenos``   | ( 0, −1)  | noroeste   | norte     |
/// |      3 | ``sMasQMenos``   | (−1,  0)  | oeste      | noroeste  |
/// |      4 | ``rMasQMenos``   | (−1, +1)  | suroeste   | suroeste  |
/// |      5 | ``rMasSMenos``   | ( 0, +1)  | sureste    | sur       |
///
/// Se numeran en sentido antihorario en pantalla (con el eje y hacia abajo), como
/// ``CoordenadaAxial/direcciones``. Para elegir una por su punto cardinal:
///
/// ```swift
/// let este = DireccionHexagonal(.este, .puntiaguda)!     // .qMasSMenos
/// CoordenadaAxial.origen.vecino(este)                    // (q: 1, r: 0)
/// este.puntoCardinal(.plana)                             // .sureste
/// ```
///
/// Se llama así, y no `Direccion`, para no chocar con la `Direccion` de Armonia (ascendente o
/// descendente) en un fichero que importe los dos paquetes.
public enum DireccionHexagonal: Int, CaseIterable, Hashable, Sendable, Codable {
    case qMasSMenos = 0
    case qMasRMenos = 1
    case sMasRMenos = 2
    case sMasQMenos = 3
    case rMasQMenos = 4
    case rMasSMenos = 5

    /// La dirección con ese número, tomado módulo 6 (`DireccionHexagonal(numero: 7) == .qMasRMenos`).
    public init(numero: Int) {
        self = DireccionHexagonal(rawValue: modulo(numero, 6))!
    }

    /// La dirección que apunta a ese punto cardinal en esa orientación, o `nil` si ninguna lo hace
    /// (los puntiagudos no tienen vecina al norte ni al sur; los planos, al este ni al oeste).
    public init?(_ punto: PuntoCardinal, _ orientacion: Orientacion) {
        guard let direccion = DireccionHexagonal.allCases.first(where: { $0.puntoCardinal(orientacion) == punto })
        else { return nil }
        self = direccion
    }

    /// El número de la dirección, del 0 al 5.
    public var numero: Int { rawValue }

    /// El paso en coordenadas axiales que lleva a la vecina.
    public var paso: CoordenadaAxial { CoordenadaAxial.direcciones[rawValue] }

    /// La dirección contraria.
    public var opuesta: DireccionHexagonal { rotada(sextos: 3) }

    /// La siguiente en sentido antihorario.
    public var siguiente: DireccionHexagonal { rotada(sextos: 1) }

    /// La anterior (la siguiente en sentido horario).
    public var anterior: DireccionHexagonal { rotada(sextos: -1) }

    /// La dirección girada `sextos` veces 60°: los positivos, en sentido antihorario.
    public func rotada(sextos: Int) -> DireccionHexagonal {
        DireccionHexagonal(numero: rawValue + sextos)
    }

    /// Hacia dónde apunta en pantalla con esa orientación.
    public func puntoCardinal(_ orientacion: Orientacion) -> PuntoCardinal {
        switch orientacion {
        case .puntiaguda:
            return [.este, .noreste, .noroeste, .oeste, .suroeste, .sureste][rawValue]
        case .plana:
            return [.sureste, .noreste, .norte, .noroeste, .suroeste, .sur][rawValue]
        }
    }

    /// El ángulo hacia la vecina en pantalla, en grados en sentido antihorario desde el este
    /// (0° es el este y 90° el norte): múltiplos de 60° en los puntiagudos, desplazados 30° en los planos.
    public func angulo(_ orientacion: Orientacion) -> Double {
        Double(orientacion == .puntiaguda ? rawValue * 60 : modulo(rawValue * 60 - 30, 360))
    }
}

extension CoordenadaAxial {
    /// La vecina en esa dirección.
    public func vecino(_ direccion: DireccionHexagonal) -> CoordenadaAxial {
        self + direccion.paso
    }

    /// La casilla a `pasos` pasos en esa dirección (hacia atrás si `pasos` es negativo).
    public func avanzando(_ pasos: Int, hacia direccion: DireccionHexagonal) -> CoordenadaAxial {
        self + direccion.paso * pasos
    }
}
