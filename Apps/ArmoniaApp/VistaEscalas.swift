import SwiftUI
import Armonia
import SepirizUI

/// Elige una tónica y una escala del catálogo (occidentales y de otras tradiciones) y muestra sus notas,
/// sus acordes y dónde caen en el mástil.
struct VistaEscalas: View {
    @AppStorage(AjustesSepiriz.claveDeNotacion) private var claveDeNotacion = Nomenclatura.espanol.clave
    @State private var tonica = 0          // índice en `tonicas`
    @State private var tipo = 0            // índice en `catalogo`

    private var notacion: Nomenclatura { .desde(clave: claveDeNotacion) }

    /// Las escalas habituales y, después, las de otras tradiciones. Se elige por índice porque dos
    /// escalas con las mismas notas son iguales (`==`) aunque se llamen distinto.
    private static let catalogo = TipoDeEscala.todos + TipoDeEscala.tradicionales

    /// Las doce tónicas, de Do a Si, con la grafía habitual de una tonalidad: Re♭, Mi♭, La♭ y Si♭ con
    /// bemoles y Fa♯ con sostenido. (`Altura(midi:)` daría Do♯, Re♯, Sol♯ y La♯, con dobles sostenidos
    /// en la escala.) Se indican por su posición en la línea de quintas.
    private static let tonicas: [Nota] = [0, -5, 2, -3, 4, -1, 6, 1, -4, 3, -2, 5].map { Nota(pasosDeQuinta: $0) }

    private var escala: Escala {
        let nota = VistaEscalas.tonicas[min(tonica, VistaEscalas.tonicas.count - 1)]
        return Escala(nota, VistaEscalas.catalogo[min(tipo, VistaEscalas.catalogo.count - 1)])
    }

    var body: some View {
        let escala = self.escala
        Form {
            Section("Escala") {
                Picker("Tónica", selection: $tonica) {
                    ForEach(VistaEscalas.tonicas.indices, id: \.self) { Text(VistaEscalas.tonicas[$0].nombre(en: notacion)).tag($0) }
                }
                Picker("Tipo", selection: $tipo) {
                    Section("Habituales") {
                        ForEach(0..<TipoDeEscala.todos.count, id: \.self) { Text(nombre($0)).tag($0) }
                    }
                    Section("Otras tradiciones") {
                        ForEach(TipoDeEscala.todos.count..<VistaEscalas.catalogo.count, id: \.self) {
                            Text(nombre($0)).tag($0)
                        }
                    }
                }
            }
            Section("Notas") {
                Text(escala.nombre(en: notacion)).font(.headline)
                Text(escala.notas.map { $0.nombre(en: notacion) }.joined(separator: "  "))
                    .font(.system(.body, design: .monospaced))
            }
            let acordes = escala.armonizar().compactMap { $0 }
            if !acordes.isEmpty {
                Section("Acordes de la escala") {
                    Text(acordes.map { $0.cifrado(en: notacion) }.joined(separator: "   "))
                }
            }
            Section("Mástil de guitarra") {
                MastilView(mastil: Mastil(.guitarra, trastes: 12), escala: escala, notacion: notacion)
            }
        }
        .navigationTitle("Escalas")
        .toolbarNotacion(clave: $claveDeNotacion)
    }

    private func nombre(_ indice: Int) -> String {
        VistaEscalas.catalogo[indice].nombre(en: notacion)
    }
}
