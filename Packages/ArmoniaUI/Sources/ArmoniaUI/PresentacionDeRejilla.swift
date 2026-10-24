import Armonia
import Hexagonos
import ArmoniaPresentacion

/// La parte de `DiagramaDeRejilla` que no es dibujo: cómo se encaja un mapa en el espacio que hay, qué
/// casilla se ha tocado y cómo se describe a VoiceOver. No usa SwiftUI, así que se prueba también en Linux.
enum PresentacionDeRejilla {
    /// La proporción (ancho / alto) que ocupan los hexágonos de `casillas`, o `nil` si no hay ninguna.
    static func proporcion(de casillas: [CoordenadaAxial], orientacion: Orientacion) -> Double? {
        guard let caja = Trazado(orientacion: orientacion, tamano: 1).limites(de: casillas) else { return nil }
        let alto = caja.maximo.y - caja.minimo.y
        return alto > 0 ? (caja.maximo.x - caja.minimo.x) / alto : nil
    }

    /// El trazado que encaja `casillas` lo más grandes posible en un rectángulo de `ancho × alto`,
    /// centradas y con `margen` alrededor. `nil` si no hay casillas o no caben.
    static func trazado(para casillas: [CoordenadaAxial], orientacion: Orientacion,
                        ancho: Double, alto: Double, margen: Double = 0) -> Trazado? {
        guard let caja = Trazado(orientacion: orientacion, tamano: 1).limites(de: casillas) else { return nil }
        let anchoUnidad = caja.maximo.x - caja.minimo.x
        let altoUnidad = caja.maximo.y - caja.minimo.y
        let escala = min((ancho - 2 * margen) / anchoUnidad, (alto - 2 * margen) / altoUnidad)
        guard escala > 0, escala.isFinite else { return nil }
        let origen = Punto(x: ancho / 2 - escala * (caja.minimo.x + caja.maximo.x) / 2,
                           y: alto / 2 - escala * (caja.minimo.y + caja.maximo.y) / 2)
        return Trazado(orientacion: orientacion, tamano: escala, origen: origen)
    }

    /// La casilla del mapa que hay bajo `punto`, o `nil` si el punto cae fuera del mapa.
    static func casilla(en punto: Punto, trazado: Trazado, mapa: Set<CoordenadaAxial>) -> CoordenadaAxial? {
        let casilla = trazado.casilla(en: punto)
        return mapa.contains(casilla) ? casilla : nil
    }

    /// Una descripción corta para VoiceOver, en el idioma de los textos: cuántas casillas hay y cuál está elegida.
    static func descripcion(casillas: Int, seleccionada: CoordenadaAxial?, en notacion: Notacion = .espanol) -> String {
        let cuantas = notacion.texto(.casillas(casillas))
        guard let seleccionada else { return cuantas }
        return cuantas + "; " + notacion.texto(.casillaElegida(q: seleccionada.q, r: seleccionada.r))
    }
}
