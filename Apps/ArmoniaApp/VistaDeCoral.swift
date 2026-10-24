import SwiftUI
import Armonia
import HexaphonosUI

/// Armoniza una melodía, escribe unos acordes a cuatro voces o revisa la conducción de unas voces, y
/// exporta el coral como partitura o MIDI.
struct VistaDeCoral: View {
    @Environment(\.notacion) private var notacion
    @State private var tarea = PresentacionDeCoral.Tarea.armonizar
    @State private var textos: [PresentacionDeCoral.Tarea: String] = Dictionary(
        uniqueKeysWithValues: PresentacionDeCoral.Tarea.allCases.map { ($0, $0.ejemplo) })
    @State private var tonalidad = ""
    /// El resultado y para qué tarea, texto, tonalidad y notación. Mientras no coincida con lo que hay
    /// escrito, se muestra «Calculando…».
    @State private var resultado: Calculado<Result<CoralPresentado, Error>>?

    private var texto: String { textos[tarea] ?? "" }
    private var claveActual: String { "\(tarea.rawValue)|\(texto)|\(tonalidad)|\(notacion.clave)" }

    var body: some View {
        Form {
            Section {
                Picker(notacion.texto(.tarea), selection: $tarea) {
                    ForEach(PresentacionDeCoral.Tarea.allCases) { Text($0.titulo(en: notacion)).tag($0) }
                }
                .pickerStyle(.segmented)
                TextField(tarea.indicacion(en: notacion), text: Binding(get: { texto }, set: { textos[tarea] = $0 }), axis: .vertical)
                    .comoCampoDeCifrado()
                if tarea.usaTonalidad {
                    TextField(notacion.texto(.campoDeTonalidad), text: $tonalidad)
                        .comoCampoDeCifrado()
                }
            }
            if let valor = resultado?.valor(para: claveActual) {
                switch valor {
                case .success(let coral):
                    contenido(coral)
                case .failure(let error):
                    Section {
                        Text(notacion.mensaje(de: error)).foregroundColor(.red)
                    }
                }
            } else {
                Section {
                    FilaCalculando()
                }
            }
        }
        .navigationTitle(notacion.texto(.coral))
        .selectorDeNotacionEnLaBarra()
        .toolbar {
            ToolbarItem {
                BotonDeExportar(ficheros)
            }
        }
        // Armonizar a cuatro voces puede tardar: fuera del hilo principal, cuando se deja de escribir.
        .calcularEnSegundoPlano(para: claveActual, esperando: 0.3, en: $resultado) {
            [tarea = self.tarea, texto = self.texto, tonalidad = self.tonalidad, notacion = self.notacion] in
            Result { try PresentacionDeCoral.presentar(tarea, texto, tonalidad: tonalidad, notacion: notacion) }
        }
    }

    private var ficheros: [FicheroParaExportar] {
        guard case .success(let coral) = resultado?.valor(para: claveActual) else { return [] }
        return coral.ficheros
    }

    @ViewBuilder
    private func contenido(_ coral: CoralPresentado) -> some View {
        if !coral.titulo.isEmpty {
            Section(notacion.texto(.tonalidad)) {
                Text(coral.titulo).font(.headline)
            }
        }
        if !coral.propuestas.isEmpty {
            Section(notacion.texto(.armonizaciones)) {
                ForEach(Array(coral.propuestas.enumerated()), id: \.offset) { n, propuesta in
                    Text("\(n + 1). \(propuesta)")
                }
            }
        }
        if !coral.filas.isEmpty {
            Section(notacion.texto(.aCuatroVoces)) {
                BotonDeEscuchar(coral.sonido)
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
            let titulo = notacion.texto(tarea == .revisar ? .conduccionDeLasVoces : .avisos)
            Section(titulo) {
                ForEach(coral.avisos, id: \.self) { Text($0.texto(en: notacion)) }
            }
        }
    }
}
