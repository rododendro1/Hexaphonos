import SwiftUI
import Armonia
import HexaphonosUI

/// Escribe un cifrado (Sol7/Si, Dom, Fa#m7b5…) y muestra el acorde con sus digitaciones.
struct VistaAcordes: View {
    @Environment(\.notacion) private var notacion
    @State private var texto = "Sol7/Si"
    /// El acorde leído de `texto`. Se lee una vez por cambio del texto, no en cada redibujado.
    @State private var lectura = VistaAcordes.leer("Sol7/Si")
    @State private var encordado = Encordado.guitarra
    /// Las digitaciones y para qué texto e instrumento se calcularon. Mientras no coincidan con lo que hay
    /// escrito, se muestra «Calculando…» y no las de otro acorde.
    @State private var digitaciones: Calculado<[Digitacion]>?

    private var claveActual: String { "\(texto)|\(encordado.nombre)" }

    var body: some View {
        Form {
            Section(notacion.texto(.acorde)) {
                TextField(notacion.texto(.campoDeCifrado), text: $texto)
                    .comoCampoDeCifrado()
            }
            switch lectura {
            case .success(let acorde):
                informacion(de: acorde)
                digitaciones(de: acorde)
            case .failure(let error):
                Section {
                    Text(notacion.mensaje(de: error)).foregroundColor(.red)
                }
            }
        }
        .navigationTitle(notacion.texto(.acordes))
        .selectorDeNotacionEnLaBarra()
        .onChange(of: texto) { lectura = Self.leer($0) }
        // La búsqueda de digitaciones puede tardar: se hace fuera del hilo principal cuando se deja de escribir.
        .calcularEnSegundoPlano(para: claveActual, en: $digitaciones) { [texto = self.texto, encordado = self.encordado] in
            guard let acorde = try? Acorde(leyendo: texto) else { return [] }
            // La quinta puede faltar en los acordes de cuatro notas o más (el Do7 `x32310`), como se toca.
            return Mastil(encordado, trastes: 15).digitaciones(de: acorde, exigirQuinta: false, limite: 6)
        }
    }

    @ViewBuilder
    private func informacion(de acorde: Acorde) -> some View {
        Section(notacion.texto(.informacion)) {
            LabeledContent(notacion.texto(.nombre), value: acorde.nombre(en: notacion))
            LabeledContent(notacion.texto(.cifrado), value: acorde.cifrado(en: notacion))
            LabeledContent(notacion.texto(.notas),
                           value: acorde.notasDesdeElBajo.map { $0.nombre(en: notacion) }.joined(separator: " "))
            BotonDeEscuchar(.acorde(acorde))
        }
    }

    @ViewBuilder
    private func digitaciones(de acorde: Acorde) -> some View {
        Section(notacion.texto(.digitaciones)) {
            Picker(notacion.texto(.instrumentoYAfinacion), selection: $encordado) {
                ForEach(Encordado.todos, id: \.self) { Text($0.titulo(en: notacion)).tag($0) }
            }
            if let formas = digitaciones?.valor(para: claveActual) {
                if formas.isEmpty {
                    Text(notacion.texto(.sinDigitaciones))
                        .foregroundColor(.secondary)
                }
                ForEach(formas, id: \.tablatura) { forma in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(alignment: .firstTextBaseline) {
                            Text(forma.tablatura).font(.system(.body, design: .monospaced))
                            Text(notacion.texto(.dedos(forma.dedos, cejilla: forma.cejilla)))
                                .font(.caption).foregroundColor(.secondary)
                        }
                        DiagramaDeMastil(digitacion: forma, acorde: acorde, notacion: notacion)
                            .frame(maxHeight: 120)
                    }
                }
            } else {
                FilaCalculando()
            }
        }
    }

    private static func leer(_ texto: String) -> Result<Acorde, Error> {
        Result { try Acorde(leyendo: texto) }
    }
}
