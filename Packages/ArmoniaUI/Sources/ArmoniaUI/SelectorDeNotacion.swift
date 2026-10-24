#if canImport(SwiftUI)
import SwiftUI
import Armonia
import ArmoniaPresentacion

/// El menú para elegir la notación de las notas y, aparte, el idioma de los textos. Guarda la `clave`
/// de la `Notacion` (combinada si los textos van en otro idioma). Lo habitual es ponerlo en la barra
/// con `selectorDeNotacionEnLaBarra()`, que lo guarda en los ajustes que lee `notacionGuardada()`.
public struct SelectorDeNotacion: View {
    @Binding var clave: String

    public init(clave: Binding<String>) {
        self._clave = clave
    }

    public var body: some View {
        Menu {
            Picker(notacion.texto(.notas), selection: notas) {
                ForEach(Notacion.allCases, id: \.self) { notacion in
                    Text(notacion.titulo).tag(notacion.clave)
                }
            }
            Picker(notacion.texto(.textos), selection: textos) {
                Text(notacion.texto(.comoLasNotas)).tag("")
                ForEach(Idioma.traducidos, id: \.self) { idioma in
                    Text(idioma.titulo).tag(idioma.clave)
                }
            }
        } label: {
            Text(notacion.titulo)
        }
    }

    private var notacion: Notacion { .desde(clave: clave) }

    /// La notación de las notas; al cambiarla se conserva el idioma de los textos.
    private var notas: Binding<String> {
        Binding(get: { Notacion.desde(clave: clave).notas.clave },
                set: { clave = Notacion.desde(clave: clave).conNotas(Notacion.desde(clave: $0)).clave })
    }

    /// El idioma de los textos, o "" si van en el de las notas.
    private var textos: Binding<String> {
        Binding(get: { Notacion.desde(clave: clave).idiomaElegidoParaLosTextos?.clave ?? "" },
                set: { nuevo in
                    let idioma = Idioma.allCases.first { $0.clave == nuevo }
                    clave = Notacion.desde(clave: clave).conTextosElegidos(idioma).clave
                })
    }
}

/// El selector, guardando la notación en los ajustes de las apps.
struct SelectorDeNotacionGuardada: View {
    @AppStorage(AjustesDeLasApps.claveDeNotacion) private var clave = Notacion.delSistema().clave

    var body: some View {
        SelectorDeNotacion(clave: $clave)
    }
}

extension View {
    /// Pone en la barra de herramientas el selector de notación, que guarda la elegida en los ajustes
    /// (`notacionGuardada()` la pone en el entorno).
    public func selectorDeNotacionEnLaBarra() -> some View {
        toolbar {
            ToolbarItem {
                SelectorDeNotacionGuardada()
            }
        }
    }

    /// Pone el selector de notación en la barra de herramientas, guardando la clave en `clave`.
    public func selectorDeNotacionEnLaBarra(clave: Binding<String>) -> some View {
        toolbar {
            ToolbarItem {
                SelectorDeNotacion(clave: clave)
            }
        }
    }

    /// Un campo de texto para cifrados y escalas: sin autocorrección y, en iOS, sin mayúscula inicial
    /// (los cifrados distinguen `M` de `m`).
    public func comoCampoDeCifrado() -> some View {
        #if os(iOS)
        return self.autocorrectionDisabled().textInputAutocapitalization(.never)
        #else
        return self.autocorrectionDisabled()
        #endif
    }
}
#endif
