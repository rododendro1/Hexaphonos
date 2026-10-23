#if canImport(SwiftUI)
import SwiftUI

/// Colores y medidas comunes de las apps del ecosistema.
public enum TemaSepiriz {
    /// El color de énfasis: el mismo violeta de las notas en los dibujos del Tonnetz.
    public static let acento = Color(red: 0.36, green: 0.25, blue: 0.62)
    /// Madera clara del mástil.
    public static let madera = Color(red: 0.86, green: 0.74, blue: 0.56)
    /// Madera oscura de la cejilla y de los trastes pisados.
    public static let maderaOscura = Color(red: 0.36, green: 0.24, blue: 0.14)

    public static let radioDeEsquina: CGFloat = 12
    public static let margen: CGFloat = 16
}
#endif
