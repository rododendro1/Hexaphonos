#if canImport(SwiftUI)
import SwiftUI
import Armonia

/// El menú para elegir la notación. Guarda la `clave` de la `Nomenclatura`:
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
        Picker("Notación", selection: $clave) {
            ForEach(Nomenclatura.allCases, id: \.self) { notacion in
                Text(notacion.titulo).tag(notacion.clave)
            }
        }
        .pickerStyle(.menu)
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
