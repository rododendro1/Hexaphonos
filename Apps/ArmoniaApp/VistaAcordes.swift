import SwiftUI
import Armonia
import SepirizUI

/// Escribe un cifrado (Sol7/Si, Dom, Fa#m7b5…) y muestra el acorde con sus digitaciones.
struct VistaAcordes: View {
    @AppStorage(AjustesSepiriz.claveDeNotacion) private var claveDeNotacion = Nomenclatura.espanol.clave
    @State private var texto = "Sol7/Si"
    /// El acorde leído de `texto`. Se lee una vez por cambio del texto, no en cada redibujado.
    @State private var lectura = VistaAcordes.leer("Sol7/Si")
    @State private var encordado = Encordado.guitarra
    /// Las digitaciones calculadas y para qué texto e instrumento. Mientras no coincida con lo que hay
    /// escrito, se muestra «Calculando…» y no las de otro acorde.
    @State private var resultado: (clave: String, formas: [Digitacion])?

    private var notacion: Nomenclatura { .desde(clave: claveDeNotacion) }
    private var claveActual: String { "\(texto)|\(encordado.nombre)" }

    var body: some View {
        Form {
            Section("Acorde") {
                TextField("Cifrado, por ejemplo Sol7/Si", text: $texto)
                    .campoDeCifrado()
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
        .navigationTitle("Acordes")
        .toolbarNotacion(clave: $claveDeNotacion)
        .onChange(of: texto) { lectura = Self.leer($0) }
        // La búsqueda de digitaciones puede tardar: se espera a que se deje de escribir y se hace
        // fuera del hilo principal. `.task(id:)` cancela la anterior cuando cambia el texto.
        .task(id: claveActual) { await calcularDigitaciones() }
    }

    @ViewBuilder
    private func informacion(de acorde: Acorde) -> some View {
        Section("Información") {
            LabeledContent("Nombre", value: acorde.nombre(en: notacion))
            LabeledContent("Cifrado", value: acorde.cifrado(en: notacion))
            LabeledContent("Notas", value: acorde.notasDesdeElBajo.map { $0.nombre(en: notacion) }.joined(separator: " "))
        }
    }

    @ViewBuilder
    private func digitaciones(de acorde: Acorde) -> some View {
        Section("Digitaciones") {
            Picker("Instrumento", selection: $encordado) {
                ForEach(Encordado.todos, id: \.self) { Text($0.nombre.capitalized).tag($0) }
            }
            if let resultado, resultado.clave == claveActual {
                if resultado.formas.isEmpty {
                    Text("No hay digitaciones cómodas para este acorde en este instrumento.")
                        .foregroundColor(.secondary)
                }
                ForEach(resultado.formas, id: \.cifra) { forma in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(alignment: .firstTextBaseline) {
                            Text(forma.cifra).font(.system(.body, design: .monospaced))
                            Text(descripcionDeDedos(de: forma)).font(.caption).foregroundColor(.secondary)
                        }
                        DiagramaDeMastil(digitacion: forma, acorde: acorde, notacion: notacion)
                            .frame(maxHeight: 120)
                    }
                }
            } else {
                HStack {
                    ProgressView()
                    Text("Calculando…").foregroundColor(.secondary)
                }
            }
        }
    }

    /// «3 dedos», o «4 dedos, cejilla en el traste 1».
    private func descripcionDeDedos(de forma: Digitacion) -> String {
        var texto = "\(forma.dedos) \(forma.dedos == 1 ? "dedo" : "dedos")"
        if let cejilla = forma.cejilla { texto += ", cejilla en el traste \(cejilla)" }
        return texto
    }

    private static func leer(_ texto: String) -> Result<Acorde, Error> {
        Result { try Acorde(leyendo: texto) }
    }

    private func calcularDigitaciones() async {
        let clave = claveActual
        let encordado = self.encordado
        // Espera a que se deje de escribir; si cambia el texto, la tarea se cancela aquí.
        try? await Task.sleep(nanoseconds: 250_000_000)
        guard !Task.isCancelled else { return }
        // Tras la espera, `lectura` ya corresponde al texto de `clave` (`onChange` va antes que la tarea).
        guard case .success(let acorde) = lectura else {
            resultado = nil
            return
        }
        let formas = await Task.detached(priority: .userInitiated) {
            // La quinta puede faltar en los acordes de cuatro notas o más (el Do7 `x32310`), como se toca.
            Mastil(encordado, trastes: 15).digitaciones(de: acorde, exigirQuinta: false, limite: 6)
        }.value
        guard !Task.isCancelled else { return }
        resultado = (clave, formas)
    }
}
