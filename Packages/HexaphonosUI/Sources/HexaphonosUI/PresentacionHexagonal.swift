import Hexagonos

/// La parte de `DiagramaHexagonal` que no es dibujo: cómo se encaja un mapa en el espacio que hay, qué
/// casilla se ha tocado y cómo se describe a VoiceOver. No usa SwiftUI, así que se prueba también en Linux.
enum PresentacionHexagonal {
    /// La proporción (ancho / alto) que ocupan los hexágonos de `casillas`, o `nil` si no hay ninguna.
    static func proporcion(de casillas: [CoordenadaAxial], orientacion: Orientacion) -> Double? {
        guard let caja = Disposicion(orientacion: orientacion, tamano: 1).limites(de: casillas) else { return nil }
        let alto = caja.maximo.y - caja.minimo.y
        return alto > 0 ? (caja.maximo.x - caja.minimo.x) / alto : nil
    }

    /// La disposición que encaja `casillas` lo más grandes posible en un rectángulo de `ancho × alto`,
    /// centradas y con `margen` alrededor. `nil` si no hay casillas o no caben.
    static func disposicion(para casillas: [CoordenadaAxial], orientacion: Orientacion,
                            ancho: Double, alto: Double, margen: Double = 0) -> Disposicion? {
        guard let caja = Disposicion(orientacion: orientacion, tamano: 1).limites(de: casillas) else { return nil }
        let anchoUnidad = caja.maximo.x - caja.minimo.x
        let altoUnidad = caja.maximo.y - caja.minimo.y
        let escala = min((ancho - 2 * margen) / anchoUnidad, (alto - 2 * margen) / altoUnidad)
        guard escala > 0, escala.isFinite else { return nil }
        let origen = Punto(x: ancho / 2 - escala * (caja.minimo.x + caja.maximo.x) / 2,
                           y: alto / 2 - escala * (caja.minimo.y + caja.maximo.y) / 2)
        return Disposicion(orientacion: orientacion, tamano: escala, origen: origen)
    }

    /// La casilla del mapa que hay bajo `punto`, o `nil` si el punto cae fuera del mapa.
    static func casilla(en punto: Punto, disposicion: Disposicion, mapa: Set<CoordenadaAxial>) -> CoordenadaAxial? {
        let casilla = disposicion.casilla(en: punto)
        return mapa.contains(casilla) ? casilla : nil
    }

    /// Una descripción corta para VoiceOver: cuántas casillas hay y cuál está elegida.
    static func descripcion(casillas: Int, seleccionada: CoordenadaAxial?) -> String {
        let cuantas = casillas == 1 ? "1 casilla" : "\(casillas) casillas"
        guard let seleccionada else { return cuantas }
        return "\(cuantas); elegida q \(seleccionada.q), r \(seleccionada.r)"
    }
}
