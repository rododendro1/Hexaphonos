import SwiftUI
import Armonia
import HexaphonosUI

/// Escribe una progresión (Do Fa Sol7 Do Lam Re7 Sol) y muestra sus tonalidades, los grados, las funciones,
/// las modulaciones y las cadencias, y la exporta como partitura o MIDI.
struct VistaAnalisis: View {
    @AppStorage(AjustesHexaphonos.claveDeNotacion) private var claveDeNotacion = Nomenclatura.espanol.clave
    @State private var texto = "Do Fa Sol7 Do Lam Re7 Sol"
    /// El análisis de `texto`, que se rehace al cambiar el texto o la notación, no en cada redibujado.
    @State private var resultado: Result<AnalisisPresentado, Error>?

    private var notacion: Nomenclatura { .desde(clave: claveDeNotacion) }

    var body: some View {
        Form {
            Section("Progresión") {
                TextField("Acordes separados por espacios", text: $texto)
                    .comoCampoDeCifrado()
            }
            switch resultado {
            case .some(.success(let analisis)):
                Section("Resultado") {
                    Text(analisis.titulo).font(.headline)
                }
                ForEach(Array(analisis.tramos.enumerated()), id: \.offset) { _, tramo in
                    Section(tramo.cabecera ?? "Acorde a acorde") {
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
                    Section("Cadencias") {
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
        .navigationTitle("Análisis")
        .selectorDeNotacionEnLaBarra(clave: $claveDeNotacion)
        .toolbar {
            ToolbarItem {
                BotonDeExportar((try? resultado?.get())?.ficheros ?? [])
            }
        }
        .task(id: "\(texto)|\(claveDeNotacion)") {
            resultado = Result { try PresentacionDeAnalisis.analizar(texto, notacion: notacion) }
        }
    }
}
