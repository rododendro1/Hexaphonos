#if canImport(SwiftUI) && canImport(WebKit)
import SwiftUI
import Armonia

/// El Tonnetz de unas notas, un acorde o una escala, dibujado por el motor.
///
///     DiagramaDeTonnetz(Tonnetz(try Acorde(leyendo: "Dom7")))
///     DiagramaDeTonnetz(Tonnetz(Escala(.re, .dorico)), notacion: .ingles)
public struct DiagramaDeTonnetz: View {
    public let tonnetz: Tonnetz
    public let notacion: Notacion
    public let leyenda: Bool

    public init(_ tonnetz: Tonnetz, notacion: Notacion = .espanol, leyenda: Bool = true) {
        self.tonnetz = tonnetz
        self.notacion = notacion
        self.leyenda = leyenda
    }

    public var body: some View {
        VistaSVG(svg: tonnetz.svg(notacion: notacion, leyenda: leyenda))
            .clipShape(RoundedRectangle(cornerRadius: TemaHexaphonos.radioDeEsquina))
            .accessibilityLabel(Text("Tonnetz: " + tonnetz.notas.map { $0.nombre(en: notacion) }.joined(separator: ", ")))
    }
}

#endif
