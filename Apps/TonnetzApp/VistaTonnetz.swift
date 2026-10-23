import SwiftUI
import Armonia
import SepirizUI

/// El Tonnetz de un acorde, una escala o un recorrido de tríadas con las transformaciones P, L y R.
struct VistaTonnetz: View {
    enum Modo: String, CaseIterable, Identifiable {
        case recorrido = "Recorrido P·L·R"
        case acorde = "Acorde"
        case escala = "Escala"
        var id: Self { self }
    }

    @AppStorage(AjustesSepiriz.claveDeNotacion) private var claveDeNotacion = Nomenclatura.espanol.clave
    @State private var modo = Modo.recorrido
    @State private var textoInicial = "Do"
    @State private var textoAcorde = "Dom7"
    @State private var textoEscala = "Re dórico"
    @State private var recorrido: [Acorde] = []
    @State private var transformaciones: [TransformacionNeorriemanniana] = []

    private var notacion: Nomenclatura { .desde(clave: claveDeNotacion) }

    var body: some View {
        VStack(spacing: 12) {
            Picker("Modo", selection: $modo) {
                ForEach(Modo.allCases) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)

            controles

            if let tonnetz {
                TonnetzView(tonnetz, notacion: notacion)
            } else {
                Spacer()
                Text("No se puede dibujar: revisa el texto.").foregroundColor(.secondary)
                Spacer()
            }
        }
        .padding(TemaSepiriz.margen)
        .navigationTitle("Tonnetz")
        .toolbarNotacion(clave: $claveDeNotacion)
        .onAppear { if recorrido.isEmpty { reiniciar() } }
    }

    // MARK: Controles

    @ViewBuilder
    private var controles: some View {
        switch modo {
        case .recorrido:
            HStack {
                TextField("Tríada inicial (Do, Lam…)", text: $textoInicial)
                    .textFieldStyle(.roundedBorder)
                    .campoDeCifrado()
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
                .campoDeCifrado()
        case .escala:
            TextField("Escala (Re dórico, La menor armónica…)", text: $textoEscala)
                .textFieldStyle(.roundedBorder)
                .campoDeCifrado()
        }
    }

    // MARK: El dibujo

    private var tonnetz: Tonnetz? {
        switch modo {
        case .recorrido:
            return recorrido.count >= 2 ? Tonnetz(recorrido: recorrido) : recorrido.first.map { Tonnetz($0) }
        case .acorde:
            return (try? Acorde(leyendo: textoAcorde)).map { Tonnetz($0) }
        case .escala:
            return (try? Escala(leyendo: textoEscala)).map { Tonnetz($0) }
        }
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
