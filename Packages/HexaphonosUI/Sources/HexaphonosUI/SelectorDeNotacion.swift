#if canImport(SwiftUI)
import SwiftUI
import Armonia

/// El menú para elegir la notación de las notas y, aparte, el idioma de los textos. Guarda la `clave`
/// de la `Nomenclatura` (combinada si los textos van en otro idioma):
///
///     @AppStorage(AjustesHexaphonos.claveDeNotacion) private var claveDeNotacion = Nomenclatura.espanol.clave
///     …
///     .selectorDeNotacionEnLaBarra(clave: $claveDeNotacion)
public struct SelectorDeNotacion: View {
    @Binding var clave: String

    public init(clave: Binding<String>) {
        self._clave = clave
    }

    public var body: some View {
        Menu {
            Picker("Notas", selection: notas) {
                ForEach(Nomenclatura.allCases, id: \.self) { notacion in
                    Text(notacion.titulo).tag(notacion.clave)
                }
            }
            Picker("Textos", selection: textos) {
                Text("Como las notas").tag("")
                ForEach(Idioma.traducidos, id: \.self) { idioma in
                    Text(idioma.titulo).tag(idioma.clave)
                }
            }
        } label: {
            Text(Nomenclatura.desde(clave: clave).titulo)
        }
    }

    /// La notación de las notas; al cambiarla se conserva el idioma de los textos.
    private var notas: Binding<String> {
        Binding(get: { Nomenclatura.desde(clave: clave).notas.clave },
                set: { clave = Nomenclatura.desde(clave: clave).conNotas(Nomenclatura.desde(clave: $0)).clave })
    }

    /// El idioma de los textos, o "" si van en el de las notas.
    private var textos: Binding<String> {
        Binding(get: { Nomenclatura.desde(clave: clave).idiomaElegidoParaLosTextos?.clave ?? "" },
                set: { nuevo in
                    let idioma = Idioma.allCases.first { $0.clave == nuevo }
                    clave = Nomenclatura.desde(clave: clave).conTextosElegidos(idioma).clave
                })
    }
}

extension View {
    /// Pone el selector de notación en la barra de herramientas.
    public func selectorDeNotacionEnLaBarra(clave: Binding<String>) -> some View {
        toolbar {
            ToolbarItem {
                SelectorDeNotacion(clave: clave)
            }
        }
    }

    @available(*, deprecated, renamed: "selectorDeNotacionEnLaBarra(clave:)")
    public func toolbarNotacion(clave: Binding<String>) -> some View { selectorDeNotacionEnLaBarra(clave: clave) }

    /// Un campo de texto para cifrados y escalas: sin autocorrección y, en iOS, sin mayúscula inicial
    /// (los cifrados distinguen `M` de `m`).
    public func comoCampoDeCifrado() -> some View {
        #if os(iOS)
        return self.autocorrectionDisabled().textInputAutocapitalization(.never)
        #else
        return self.autocorrectionDisabled()
        #endif
    }

    @available(*, deprecated, renamed: "comoCampoDeCifrado()")
    public func campoDeCifrado() -> some View { comoCampoDeCifrado() }
}
#endif
