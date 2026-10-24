import SwiftUI
import Armonia
import ArmoniaUI

/// Un acorde, una escala o un recorrido de tríadas con las transformaciones P, L y R, en el Tonnetz, en la
/// tabla armónica o en un teclado isomorfo (Wicki-Hayden o Jankó), y su dibujo para exportar. Al tocar una
/// nota del dibujo, suena.
struct VistaDeTonnetz: View {
    enum Contenido: CaseIterable, Identifiable {
        case recorrido
        case acorde
        case escala
        var id: Self { self }

        var texto: TextoDeLasApps {
            switch self {
            case .recorrido: return .recorridoPLR
            case .acorde: return .acorde
            case .escala: return .escala
            }
        }
    }

    @Environment(\.notacion) private var notacion
    @State private var contenido = Contenido.recorrido
    @State private var red = RedDeNotas.tonnetz
    @State private var textoInicial = "Do"
    @State private var textoAcorde = "Dom7"
    @State private var textoEscala = "Re dórico"
    @State private var recorrido: [Acorde] = []
    @State private var transformaciones: [TransformacionNeorriemanniana] = []

    var body: some View {
        VStack(spacing: 12) {
            Picker(notacion.texto(.modo), selection: $contenido) {
                ForEach(Contenido.allCases) { Text(notacion.texto($0.texto)).tag($0) }
            }
            .pickerStyle(.segmented)

            Picker(notacion.texto(.red), selection: $red) {
                ForEach(RedDeNotas.allCases) { Text($0.nombre(en: notacion)).tag($0) }
            }

            controles
            BotonDeEscuchar(sonido)

            if let dibujado, let svg = PresentacionDeRedes.svg(dibujado, en: red, notacion: notacion) {
                VistaSVG(svg: svg)
                    // Tocar una nota la hace sonar.
                    .alTocarElSVG(svg) { punto in
                        if let midi = PresentacionDeRedes.midi(en: punto, de: dibujado, enLaRed: red) {
                            Reproductor.compartido.tocar(.nota(midi))
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: TemaDeLasApps.radioDeEsquina))
                    .accessibilityLabel(Text(PresentacionDeRedes.nombre(dibujado, en: red, notacion: notacion)))
            } else {
                Spacer()
                Text(notacion.texto(.noSeDibuja)).foregroundColor(.secondary)
                Spacer()
            }
        }
        .padding(TemaDeLasApps.margen)
        .navigationTitle(red.nombre(en: notacion))
        .selectorDeNotacionEnLaBarra()
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
                TextField(notacion.texto(.campoDeTriadaInicial), text: $textoInicial)
                    .textFieldStyle(.roundedBorder)
                    .comoCampoDeCifrado()
                    .onSubmit(reiniciar)
                Button(notacion.texto(.reiniciar), action: reiniciar)
            }
            HStack {
                ForEach(TransformacionNeorriemanniana.allCases, id: \.self) { transformacion in
                    Button(transformacion.rawValue.uppercased()) { aplicar(transformacion) }
                        .buttonStyle(.borderedProminent)
                        .help(transformacion.nombre(en: notacion))
                }
                Button(notacion.texto(.deshacer)) { deshacer() }
                    .disabled(recorrido.count < 2)
            }
            Text(recorrido.map { $0.cifrado(en: notacion) }.joined(separator: " → "))
                .font(.system(.callout, design: .monospaced))
        case .acorde:
            TextField(notacion.texto(.campoDeAcorde), text: $textoAcorde)
                .textFieldStyle(.roundedBorder)
                .comoCampoDeCifrado()
        case .escala:
            TextField(notacion.texto(.campoDeEscala), text: $textoEscala)
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

    /// Lo que suena al pulsar «Escuchar»: el acorde, la escala o el recorrido.
    private var sonido: Sonido {
        switch dibujado {
        case .acorde(let acorde): return .acorde(acorde)
        case .escala(let escala): return .escala(escala)
        case .recorrido(let acordes): return .acordes(acordes)
        default: return .silencio
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
