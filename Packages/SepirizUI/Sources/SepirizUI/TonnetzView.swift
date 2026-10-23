#if canImport(SwiftUI) && canImport(WebKit)
import SwiftUI
import Armonia

/// El Tonnetz de unas notas, un acorde o una escala, dibujado por el motor.
///
///     TonnetzView(Tonnetz(try Acorde(leyendo: "Dom7")))
///     TonnetzView(Tonnetz(Escala(.re, .dorico)), notacion: .ingles)
public struct TonnetzView: View {
    public let tonnetz: Tonnetz
    public let notacion: Nomenclatura
    public let leyenda: Bool

    public init(_ tonnetz: Tonnetz, notacion: Nomenclatura = .espanol, leyenda: Bool = true) {
        self.tonnetz = tonnetz
        self.notacion = notacion
        self.leyenda = leyenda
    }

    public var body: some View {
        SVGView(svg: tonnetz.svg(notacion: notacion, leyenda: leyenda))
            .clipShape(RoundedRectangle(cornerRadius: TemaSepiriz.radioDeEsquina))
            .accessibilityLabel(Text(tonnetz.description))
    }
}
#endif
