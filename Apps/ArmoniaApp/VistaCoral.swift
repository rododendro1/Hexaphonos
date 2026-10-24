import SwiftUI
import Armonia
import HexaphonosUI

/// Armoniza una melodía, escribe unos acordes a cuatro voces o revisa la conducción de unas voces, y
/// exporta el coral como partitura o MIDI.
struct VistaCoral: View {
    @AppStorage(AjustesHexaphonos.claveDeNotacion) private var claveDeNotacion = Nomenclatura.espanol.clave
    @State private var tarea = PresentacionDeCoral.Tarea.armonizar
    @State private var textos: [PresentacionDeCoral.Tarea: String] = Dictionary(
        uniqueKeysWithValues: PresentacionDeCoral.Tarea.allCases.map { ($0, $0.ejemplo) })
    @State private var tonalidad = ""
    /// El resultado y para qué tarea, texto y tonalidad. Mientras no coincida con lo que hay escrito,
    /// se muestra «Calculando…».
    @State private var resultado: (clave: String, valor: Result<CoralPresentado, Error>)?

    private var notacion: Nomenclatura { .desde(clave: claveDeNotacion) }
    private var texto: String { textos[tarea] ?? "" }
    private var claveActual: String { "\(tarea.rawValue)|\(texto)|\(tonalidad)|\(claveDeNotacion)" }

    var body: some View {
        Form {
            Section {
                Picker("Tarea", selection: $tarea) {
                    ForEach(PresentacionDeCoral.Tarea.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                TextField(tarea.indicacion, text: Binding(get: { texto }, set: { textos[tarea] = $0 }), axis: .vertical)
                    .comoCampoDeCifrado()
                if tarea.usaTonalidad {
                    TextField("Tonalidad (vacío: la que mejor encaje)", text: $tonalidad)
                        .comoCampoDeCifrado()
                }
            }
            if let resultado, resultado.clave == claveActual {
                switch resultado.valor {
                case .success(let coral):
                    contenido(coral)
                case .failure(let error):
                    Section {
                        Text(notacion.mensaje(de: error)).foregroundColor(.red)
                    }
                }
            } else {
                Section {
                    HStack {
                        ProgressView()
                        Text("Calculando…").foregroundColor(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Coral")
        .selectorDeNotacionEnLaBarra(clave: $claveDeNotacion)
        .toolbar {
            ToolbarItem {
                BotonDeExportar(ficheros)
            }
        }
        .task(id: claveActual) { await calcular() }
    }

    private var ficheros: [FicheroParaExportar] {
        guard let resultado, resultado.clave == claveActual, case .success(let coral) = resultado.valor else { return [] }
        return coral.ficheros
    }

    @ViewBuilder
    private func contenido(_ coral: CoralPresentado) -> some View {
        if !coral.titulo.isEmpty {
            Section("Tonalidad") {
                Text(coral.titulo).font(.headline)
            }
        }
        if !coral.propuestas.isEmpty {
            Section("Armonizaciones, de mejor a peor") {
                ForEach(Array(coral.propuestas.enumerated()), id: \.offset) { n, propuesta in
                    Text("\(n + 1). \(propuesta)")
                }
            }
        }
        if !coral.filas.isEmpty {
            Section("A cuatro voces, de grave a agudo") {
                ForEach(Array(coral.filas.enumerated()), id: \.offset) { _, fila in
                    HStack {
                        Text(fila.cifrado)
                            .font(.system(.body, design: .monospaced))
                            .frame(minWidth: 70, alignment: .leading)
                        Text(fila.grado).bold()
                            .frame(minWidth: 50, alignment: .leading)
                        Spacer()
                        Text(fila.voces).font(.system(.callout, design: .monospaced))
                    }
                }
            }
        }
        if !coral.avisos.isEmpty {
            let titulo: String = tarea == .revisar ? "Conducción de las voces" : "Avisos"
            Section(titulo) {
                ForEach(coral.avisos, id: \.self) { Text($0) }
            }
        }
    }

    private func calcular() async {
        let clave = claveActual
        let (tarea, texto, tonalidad, notacion) = (self.tarea, self.texto, self.tonalidad, self.notacion)
        // Espera a que se deje de escribir; si cambia el texto, la tarea se cancela aquí.
        try? await Task.sleep(nanoseconds: 300_000_000)
        guard !Task.isCancelled else { return }
        // Armonizar a cuatro voces puede tardar: fuera del hilo principal.
        let valor = await Task.detached(priority: .userInitiated) {
            Result { try PresentacionDeCoral.presentar(tarea, texto, tonalidad: tonalidad, notacion: notacion) }
        }.value
        guard !Task.isCancelled else { return }
        resultado = (clave, valor)
    }
}
