import Hexagonos
// El Tonnetz y la tabla armónica son la misma rejilla hexagonal vista de dos maneras: en el Tonnetz
// cada nota es un vértice de la red triangular (el centro de un hexágono invisible); en la tabla
// armónica, un hexágono. Aquí se traduce un punto del Tonnetz a las coordenadas del paquete
// `Hexagonos`, y de ahí salen las posiciones de los dibujos y el camino de vuelta: de un punto del
// dibujo (donde se ha tocado) a la nota.

import Foundation

extension PuntoDelTonnetz {
    /// El punto como casilla de una rejilla hexagonal: `q` son las quintas y `r` las terceras mayores.
    ///
    /// Los seis pasos del Tonnetz (quinta justa, tercera mayor y tercera menor, arriba o abajo) son
    /// las seis direcciones de la rejilla, así que la distancia es la de la rejilla:
    /// `p.distancia(hasta: o) == p.coordenada.distancia(hasta: o.coordenada)`.
    public var coordenada: CoordenadaAxial {
        CoordenadaAxial(q: quintas, r: terceras)
    }

    /// El punto que ocupa la casilla: `PuntoDelTonnetz(CoordenadaAxial(q: 0, r: 1)).nota` es Mi.
    public init(_ coordenada: CoordenadaAxial) {
        self.init(quintas: coordenada.q, terceras: coordenada.r)
    }
}

extension Tonnetz {
    /// Dónde dibuja `svg(paso:)` cada nota: hexágonos puntiagudos (invisibles) con su centro en la
    /// nota, las quintas hacia la derecha y las terceras mayores hacia arriba a la derecha.
    ///
    /// Las coordenadas son las del SVG (las de su `viewBox`), con el Do de partida en `(0, 0)`.
    public static func trazado(paso: Double) -> Trazado {
        // El lado del hexágono es paso / √3 para que dos centros vecinos queden a `paso`; el tamaño
        // vertical va en negativo porque las terceras suben y en SVG el eje y baja.
        let lado = paso / 3.0.squareRoot()
        return Trazado(orientacion: .puntiaguda, tamano: Punto(x: lado, y: -lado))
    }

    @available(*, deprecated, renamed: "trazado(paso:)")
    public static func disposicion(paso: Double) -> Trazado { trazado(paso: paso) }

    /// La nota más cercana a un punto del dibujo de `svg(paso:)`, en las coordenadas del SVG: para
    /// saber qué nota se ha tocado.
    public static func punto(en punto: Punto, paso: Double) -> PuntoDelTonnetz {
        PuntoDelTonnetz(trazado(paso: paso).casilla(en: punto))
    }
}

extension TablaArmonica {
    /// La casilla del hexágono de un punto en la rejilla de la tabla, de hexágonos planos con la
    /// quinta hacia arriba: la del Tonnetz girada 120° (`q` son las terceras mayores y `s`, las quintas).
    public static func coordenada(de punto: PuntoDelTonnetz) -> CoordenadaAxial {
        punto.coordenada.rotada(sextos: 2)
    }

    /// El punto del Tonnetz cuyo hexágono es esa casilla de la tabla (la inversa de `coordenada(de:)`).
    public static func punto(de coordenada: CoordenadaAxial) -> PuntoDelTonnetz {
        PuntoDelTonnetz(coordenada.rotada(sextos: -2))
    }

    /// Dónde dibuja `svg(paso:)` cada hexágono, en las casillas de `coordenada(de:)`: hexágonos planos
    /// con dos vecinos a `paso` de distancia, en las coordenadas del SVG y con el Do de partida en `(0, 0)`.
    public static func trazado(paso: Double) -> Trazado {
        Trazado(orientacion: .plana, tamano: paso / 3.0.squareRoot())
    }

    @available(*, deprecated, renamed: "trazado(paso:)")
    public static func disposicion(paso: Double) -> Trazado { trazado(paso: paso) }

    /// El hexágono que hay bajo un punto del dibujo de `svg(paso:)`, en las coordenadas del SVG.
    public static func punto(en punto: Punto, paso: Double) -> PuntoDelTonnetz {
        self.punto(de: trazado(paso: paso).casilla(en: punto))
    }
}
