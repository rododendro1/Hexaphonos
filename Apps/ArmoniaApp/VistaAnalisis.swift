import SwiftUI
import Armonia
import HexaphonosUI

/// Escribe una progresión (Do Fa Sol7 Do Lam Re7 Sol) y muestra sus tonalidades, los grados, las funciones,
/// las modulaciones y las cadencias, y la exporta como partitura o MIDI.
struct VistaAnalisis: View {
    @Environment(\.notacion) private var notacion
    @State private var texto = "Do Fa Sol7 Do Lam Re7 Sol"
    /// El análisis de `texto`, que se rehace al cambiar el texto o la notación, no en cada redibujado.
    @State private var resultado: Result<AnalisisPresentado, Error>?

    var body: some View {
        Form {
            Section(notacion.texto(.progresion)) {
                TextField(notacion.texto(.campoDeProgresion), text: $texto)
                    .comoCampoDeCifrado()
            }
            switch resultado {
            case .some(.success(let analisis)):
                Section(notacion.texto(.resultado)) {
                    Text(analisis.titulo).font(.headline)
                }
                ForEach(Array(analisis.tramos.enumerated()), id: \.offset) { _, tramo in
                    Section(tramo.cabecera ?? notacion.texto(.acordeAAcorde)) {
                        ForEach(Array(tramo.filas.enumerated()), id: \.offset) { _, fila in
                            HStack {
                                Text(fila.cifrado)
                                    .font(.system(.body, design: .monospaced))
                                    .frame(minWidth: 80, alignment: .leading)
                                Text(fila.grado).bold()
                                Spacer()
                                Text(fila.funcion).foregroundColor(.secondary)
                            }
                        }
                    }
                }
                if !analisis.cadencias.isEmpty {
                    Section(notacion.texto(.cadencias)) {
                        ForEach(analisis.cadencias, id: \.self) { Text($0) }
                    }
                }
            case .some(.failure(let error)):
                Section {
                    Text(notacion.mensaje(de: error)).foregroundColor(.red)
                }
            case .none:
                EmptyView()
            }
        }
        .navigationTitle(notacion.texto(.analisis))
        .selectorDeNotacionEnLaBarra()
        .toolbar {
            ToolbarItem {
                BotonDeExportar((try? resultado?.get())?.ficheros ?? [])
            }
        }
        .task(id: "\(texto)|\(notacion.clave)") {
            resultado = Result { try PresentacionDeAnalisis.analizar(texto, notacion: notacion) }
        }
    }
}
