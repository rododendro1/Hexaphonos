import Foundation

// MARK: - Punto

/// Un punto del plano de dibujo, en píxeles (o en la unidad que se quiera), con el eje y hacia abajo
/// como en SwiftUI y SVG.
public struct Punto: Hashable, Sendable, Codable {
    public var x: Double
    public var y: Double

    public init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }

    public static let cero = Punto(x: 0, y: 0)

    public static func + (a: Punto, b: Punto) -> Punto { Punto(x: a.x + b.x, y: a.y + b.y) }
    public static func - (a: Punto, b: Punto) -> Punto { Punto(x: a.x - b.x, y: a.y - b.y) }
}

extension Punto: CustomStringConvertible {
    public var description: String { "(x: \(x), y: \(y))" }
}

// MARK: - Orientacion

/// Cómo se colocan los hexágonos al dibujarlos.
public enum Orientacion: String, CaseIterable, Hashable, Sendable, Codable {
    /// Con un vértice arriba: las filas quedan rectas (*pointy-top*).
    case puntiaguda
    /// Con una arista arriba: las columnas quedan rectas (*flat-top*).
    case plana

    /// La matriz que lleva `(q, r)` a `(x, y)` para hexágonos de radio 1: `x = f0·q + f1·r`,
    /// `y = f2·q + f3·r`.
    var directa: (f0: Double, f1: Double, f2: Double, f3: Double) {
        let raiz3 = 3.0.squareRoot()
        switch self {
        case .puntiaguda: return (raiz3, raiz3 / 2, 0, 1.5)
        case .plana: return (1.5, 0, raiz3 / 2, raiz3)
        }
    }

    /// La inversa de ``directa``.
    var inversa: (b0: Double, b1: Double, b2: Double, b3: Double) {
        let raiz3 = 3.0.squareRoot()
        switch self {
        case .puntiaguda: return (raiz3 / 3, -1.0 / 3, 0, 2.0 / 3)
        case .plana: return (2.0 / 3, 0, -1.0 / 3, raiz3 / 3)
        }
    }

    /// El ángulo del primer vértice, en sextos de vuelta: 30° en los puntiagudos y 0° en los planos.
    var anguloInicial: Double {
        self == .puntiaguda ? 0.5 : 0
    }
}

// MARK: - Trazado

/// Cómo se dibuja la rejilla: la orientación de los hexágonos, su tamaño y dónde cae el origen.
///
/// Pasa de casillas a píxeles y de vuelta:
///
/// ```swift
/// let trazado = Trazado(orientacion: .puntiaguda, tamano: 10)
/// trazado.centro(de: CoordenadaAxial(q: 1, r: 0))   // (x: 17.32…, y: 0)
/// trazado.casilla(en: Punto(x: 17, y: 1))            // (q: 1, r: 0)
/// trazado.vertices(de: .origen)                      // los seis vértices
/// ```
///
/// El tamaño es el radio del hexágono (del centro a un vértice). Con un tamaño distinto en `x` y
/// en `y` los hexágonos se estiran.
public struct Trazado: Hashable, Sendable, Codable {
    public var orientacion: Orientacion
    /// El radio de los hexágonos en cada eje.
    public var tamano: Punto
    /// Dónde cae el centro de la casilla `(0, 0)`.
    public var origen: Punto

    public init(orientacion: Orientacion, tamano: Punto, origen: Punto = .cero) {
        self.orientacion = orientacion
        self.tamano = tamano
        self.origen = origen
    }

    /// Hexágonos regulares de radio `tamano`.
    public init(orientacion: Orientacion, tamano: Double, origen: Punto = .cero) {
        self.init(orientacion: orientacion, tamano: Punto(x: tamano, y: tamano), origen: origen)
    }

    /// El ancho de un hexágono: `√3·tamaño` si es puntiagudo y `2·tamaño` si es plano.
    public var anchura: Double {
        orientacion == .puntiaguda ? 3.0.squareRoot() * tamano.x : 2 * tamano.x
    }

    /// El alto de un hexágono: `2·tamaño` si es puntiagudo y `√3·tamaño` si es plano.
    public var altura: Double {
        orientacion == .puntiaguda ? 2 * tamano.y : 3.0.squareRoot() * tamano.y
    }

    /// El centro de una casilla.
    public func centro(de casilla: CoordenadaAxial) -> Punto {
        centro(de: CoordenadaFraccionaria(casilla))
    }

    /// El punto del plano que corresponde a unas coordenadas con decimales.
    public func centro(de coordenada: CoordenadaFraccionaria) -> Punto {
        let m = orientacion.directa
        return Punto(x: (m.f0 * coordenada.q + m.f1 * coordenada.r) * tamano.x + origen.x,
                     y: (m.f2 * coordenada.q + m.f3 * coordenada.r) * tamano.y + origen.y)
    }

    /// Las coordenadas (con decimales) de un punto del plano.
    public func coordenada(en punto: Punto) -> CoordenadaFraccionaria {
        let m = orientacion.inversa
        let x = (punto.x - origen.x) / tamano.x
        let y = (punto.y - origen.y) / tamano.y
        return CoordenadaFraccionaria(q: m.b0 * x + m.b1 * y, r: m.b2 * x + m.b3 * y)
    }

    /// La casilla que contiene un punto del plano (por ejemplo, donde se ha tocado la pantalla).
    public func casilla(en punto: Punto) -> CoordenadaAxial {
        coordenada(en: punto).redondeada()
    }

    /// Los seis vértices de una casilla, en sentido horario en pantalla. En los puntiagudos el primero
    /// es el de abajo a la derecha (30°); en los planos, el de la derecha (0°).
    public func vertices(de casilla: CoordenadaAxial) -> [Punto] {
        let c = centro(de: casilla)
        return (0..<6).map { i in
            let angulo = 2 * Double.pi * (orientacion.anguloInicial + Double(i)) / 6
            return Punto(x: c.x + tamano.x * cos(angulo), y: c.y + tamano.y * sin(angulo))
        }
    }

    /// El rectángulo que ocupan los hexágonos de `casillas` (sus vértices), o `nil` si no hay ninguna.
    public func limites(de casillas: some Sequence<CoordenadaAxial>) -> (minimo: Punto, maximo: Punto)? {
        var minimo = Punto(x: .infinity, y: .infinity)
        var maximo = Punto(x: -.infinity, y: -.infinity)
        var alguna = false
        for casilla in casillas {
            alguna = true
            for v in vertices(de: casilla) {
                minimo = Punto(x: min(minimo.x, v.x), y: min(minimo.y, v.y))
                maximo = Punto(x: max(maximo.x, v.x), y: max(maximo.y, v.y))
            }
        }
        guard alguna else { return nil }
        return (minimo: minimo, maximo: maximo)
    }
}

@available(*, deprecated, renamed: "Trazado")
public typealias Disposicion = Trazado
