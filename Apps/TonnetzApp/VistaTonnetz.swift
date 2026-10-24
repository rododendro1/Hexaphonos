import SwiftUI
import Armonia
import HexaphonosUI

/// Un acorde, una escala o un recorrido de tríadas con las transformaciones P, L y R, en el Tonnetz, en la
/// tabla armónica o en un teclado isomorfo (Wicki-Hayden o Jankó), y su dibujo para exportar.
struct VistaTonnetz: View {
    enum Contenido: String, CaseIterable, Identifiable {
        case recorrido = "Recorrido P·L·R"
        case acorde = "Acorde"
        case escala = "Escala"
        var id: Self { self }
    }

    @AppStorage(AjustesHexaphonos.claveDeNotacion) private var claveDeNotacion = Nomenclatura.espanol.clave
    @State private var contenido = Contenido.recorrido
    @State private var red = RedDeNotas.tonnetz
    @State private var textoInicial = "Do"
    @State private var textoAcorde = "Dom7"
    @State private var textoEscala = "Re dórico"
    @State private var recorrido: [Acorde] = []
    @State private var transformaciones: [TransformacionNeorriemanniana] = []

    private var notacion: Nomenclatura { .desde(clave: claveDeNotacion) }

    var body: some View {
        VStack(spacing: 12) {
            Picker("Modo", selection: $contenido) {
                ForEach(Contenido.allCases) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)

            Picker("Red", selection: $red) {
                ForEach(RedDeNotas.allCases) { Text($0.rawValue).tag($0) }
            }

            controles

            if let dibujado, let svg = PresentacionDeRedes.svg(dibujado, en: red, notacion: notacion) {
                VistaSVG(svg: svg)
                    .clipShape(RoundedRectangle(cornerRadius: TemaHexaphonos.radioDeEsquina))
                    .accessibilityLabel(Text(PresentacionDeRedes.nombre(dibujado, en: red, notacion: notacion)))
            } else {
                Spacer()
                Text("No se puede dibujar: revisa el texto.").foregroundColor(.secondary)
                Spacer()
            }
        }
        .padding(TemaHexaphonos.margen)
        .navigationTitle(red.rawValue)
        .selectorDeNotacionEnLaBarra(clave: $claveDeNotacion)
        .toolbar {
            ToolbarItem {
                BotonDeExportar(ficheros)
            }
        }
        .onAppear { if recorrido.isEmpty { reiniciar() } }
    }

    // MARK: Controles

    @ViewBuilder
    private var controles: some View {
        switch contenido {
        case .recorrido:
            HStack {
                TextField("Tríada inicial (Do, Lam…)", text: $textoInicial)
                    .textFieldStyle(.roundedBorder)
                    .comoCampoDeCifrado()
                    .onSubmit(reiniciar)
                Button("Reiniciar", action: reiniciar)
            }
            HStack {
                ForEach(TransformacionNeorriemanniana.allCases, id: \.self) { transformacion in
                    Button(transformacion.rawValue.uppercased()) { aplicar(transformacion) }
                        .buttonStyle(.borderedProminent)
                        .help(transformacion.nombre)
                }
                Button("Deshacer") { deshacer() }
                    .disabled(recorrido.count < 2)
            }
            Text(recorrido.map { $0.cifrado(en: notacion) }.joined(separator: " → "))
                .font(.system(.callout, design: .monospaced))
        case .acorde:
            TextField("Cifrado (Dom7, Fa#m7b5…)", text: $textoAcorde)
                .textFieldStyle(.roundedBorder)
                .comoCampoDeCifrado()
        case .escala:
            TextField("Escala (Re dórico, La menor armónica…)", text: $textoEscala)
                .textFieldStyle(.roundedBorder)
                .comoCampoDeCifrado()
        }
    }

    // MARK: El dibujo

    /// Lo que se dibuja; `nil` si el texto no se puede leer.
    private var dibujado: ContenidoDeRed? {
        switch contenido {
        case .recorrido:
            return recorrido.isEmpty ? nil : .recorrido(recorrido)
        case .acorde:
            return (try? Acorde(leyendo: textoAcorde)).map { .acorde($0) }
        case .escala:
            return (try? Escala(leyendo: textoEscala)).map { .escala($0) }
        }
    }

    private var ficheros: [FicheroParaExportar] {
        guard let dibujado, let svg = PresentacionDeRedes.svg(dibujado, en: red, notacion: notacion) else { return [] }
        return [.svg(svg, nombre: PresentacionDeRedes.nombre(dibujado, en: red, notacion: notacion))]
    }

    // MARK: Acciones

    private func reiniciar() {
        transformaciones = []
        recorrido = (try? Acorde(leyendo: textoInicial)).map { [$0] } ?? []
    }

    private func aplicar(_ transformacion: TransformacionNeorriemanniana) {
        guard let ultimo = recorrido.last, let siguiente = ultimo.transformar(transformacion) else { return }
        recorrido.append(siguiente)
        transformaciones.append(transformacion)
    }

    private func deshacer() {
        guard recorrido.count > 1 else { return }
        recorrido.removeLast()
        transformaciones.removeLast()
    }
}
