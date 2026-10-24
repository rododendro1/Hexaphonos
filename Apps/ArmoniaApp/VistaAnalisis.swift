import SwiftUI
import Armonia
import HexaphonosUI

/// Escribe una progresión (Do Lam Re7 Sol7 Do) y muestra su tonalidad, los grados y las funciones.
struct VistaAnalisis: View {
    @AppStorage(AjustesHexaphonos.claveDeNotacion) private var claveDeNotacion = Nomenclatura.espanol.clave
    @State private var texto = "Do Lam Re7 Sol7 Do"

    private var notacion: Nomenclatura { .desde(clave: claveDeNotacion) }

    var body: some View {
        Form {
            Section("Progresión") {
                TextField("Acordes separados por espacios", text: $texto)
                    .comoCampoDeCifrado()
            }
            switch Result(catching: { try AnalisisArmonico.analizar(leyendo: texto) }) {
            case .success(let analisis):
                Section("Resultado") {
                    Text(analisis.nombre(en: notacion)).font(.headline)
                }
                Section("Acorde a acorde") {
                    ForEach(Array(analisis.acordes.enumerated()), id: \.offset) { _, analizado in
                        HStack {
                            Text(analizado.acorde.cifrado(en: notacion))
                                .font(.system(.body, design: .monospaced))
                                .frame(minWidth: 80, alignment: .leading)
                            Text(analizado.cifrado).bold()
                            Spacer()
                            Text(analizado.funcion?.nombre(en: notacion) ?? "")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            case .failure(let error):
                Section {
                    Text(notacion.mensaje(de: error)).foregroundColor(.red)
                }
            }
        }
        .navigationTitle("Análisis")
        .selectorDeNotacionEnLaBarra(clave: $claveDeNotacion)
    }
}
