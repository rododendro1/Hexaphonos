#if canImport(SwiftUI)
import SwiftUI
import Armonia
import HexaphonosPresentacion

/// Un menú «Exportar» con una entrada por fichero, que abre la hoja de compartir del sistema
/// (guardar en Archivos, AirDrop, Mail…):
///
///     .toolbar {
///         ToolbarItem { BotonDeExportar([.midi(analisis.midi(), nombre: "Progresión")]) }
///     }
///
/// Los ficheros se escriben en la carpeta temporal cada vez que cambian, no al pulsar.
public struct BotonDeExportar: View {
    public let ficheros: [FicheroParaExportar]
    @State private var escritos: [Escrito] = []
    @Environment(\.notacion) private var notacion

    struct Escrito: Identifiable {
        let fichero: FicheroParaExportar
        let url: URL
        var id: String { fichero.id }
    }

    public init(_ ficheros: [FicheroParaExportar]) {
        self.ficheros = ficheros
    }

    public var body: some View {
        Menu {
            ForEach(escritos) { escrito in
                ShareLink(item: escrito.url) {
                    Label("\(escrito.fichero.formato.titulo(en: notacion)) · \(escrito.fichero.nombreDeFichero)",
                          systemImage: escrito.fichero.formato.icono)
                }
            }
        } label: {
            Label(notacion.texto(.exportar), systemImage: "square.and.arrow.up")
        }
        .disabled(escritos.isEmpty)
        .task(id: ficheros) {
            escritos = ficheros.compactMap { fichero in
                (try? fichero.escribir()).map { Escrito(fichero: fichero, url: $0) }
            }
        }
    }
}
#endif
