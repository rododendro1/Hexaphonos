import SwiftUI
import Armonia
import HexaphonosUI

/// Elige una tónica y una escala del catálogo (occidentales y de otras tradiciones) y muestra sus notas,
/// sus acordes y dónde caen en el mástil.
struct VistaDeEscalas: View {
    @Environment(\.notacion) private var notacion
    @State private var tonica = 0          // índice en `tonicas`
    @State private var tipo = 0            // índice en `catalogo`

    /// Las escalas habituales y, después, las de otras tradiciones. Se elige por índice porque dos
    /// escalas con las mismas notas son iguales (`==`) aunque se llamen distinto.
    private static let catalogo = TipoDeEscala.todos + TipoDeEscala.tradicionales

    /// Las doce tónicas, de Do a Si, con la grafía habitual de una tonalidad: Re♭, Mi♭, La♭ y Si♭ con
    /// bemoles y Fa♯ con sostenido. (`Altura(midi:)` daría Do♯, Re♯, Sol♯ y La♯, con dobles sostenidos
    /// en la escala.) Se indican por su posición en la línea de quintas.
    private static let tonicas: [Nota] = [0, -5, 2, -3, 4, -1, 6, 1, -4, 3, -2, 5].map { Nota(pasosDeQuinta: $0) }

    private var escala: Escala {
        let nota = VistaDeEscalas.tonicas[min(tonica, VistaDeEscalas.tonicas.count - 1)]
        return Escala(nota, VistaDeEscalas.catalogo[min(tipo, VistaDeEscalas.catalogo.count - 1)])
    }

    var body: some View {
        let escala = self.escala
        Form {
            Section(notacion.texto(.escala)) {
                Picker(notacion.texto(.tonica), selection: $tonica) {
                    ForEach(VistaDeEscalas.tonicas.indices, id: \.self) { Text(VistaDeEscalas.tonicas[$0].nombre(en: notacion)).tag($0) }
                }
                Picker(notacion.texto(.tipo), selection: $tipo) {
                    Section(notacion.texto(.habituales)) {
                        ForEach(0..<TipoDeEscala.todos.count, id: \.self) { Text(nombre($0)).tag($0) }
                    }
                    Section(notacion.texto(.otrasTradiciones)) {
                        ForEach(TipoDeEscala.todos.count..<VistaDeEscalas.catalogo.count, id: \.self) {
                            Text(nombre($0)).tag($0)
                        }
                    }
                }
            }
            Section(notacion.texto(.notas)) {
                Text(escala.nombre(en: notacion)).font(.headline)
                Text(escala.notas.map { $0.nombre(en: notacion) }.joined(separator: "  "))
                    .font(.system(.body, design: .monospaced))
                BotonDeEscuchar(.escala(escala))
            }
            let acordes = escala.armonizar().compactMap { $0 }
            if !acordes.isEmpty {
                Section(notacion.texto(.acordesDeLaEscala)) {
                    Text(acordes.map { $0.cifrado(en: notacion) }.joined(separator: "   "))
                }
            }
            Section(notacion.texto(.mastilDeGuitarra)) {
                DiagramaDeMastil(mastil: Mastil(.guitarra, trastes: 12), escala: escala, notacion: notacion)
            }
        }
        .navigationTitle(notacion.texto(.escalas))
        .selectorDeNotacionEnLaBarra()
    }

    private func nombre(_ indice: Int) -> String {
        VistaDeEscalas.catalogo[indice].nombre(en: notacion)
    }
}
