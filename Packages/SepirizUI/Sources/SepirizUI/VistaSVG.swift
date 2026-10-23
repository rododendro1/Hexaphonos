#if canImport(SwiftUI) && canImport(WebKit)
import SwiftUI
import WebKit

/// Muestra un dibujo SVG (el de `Tonnetz.svg()` o `TablaArmonica.svg()`), que se ajusta al tamaño
/// disponible. Usa un `WKWebView`, así que el texto y las flechas son los mismos que en un fichero `.svg`.
public struct VistaSVG {
    public let svg: String

    public init(svg: String) {
        self.svg = svg
    }

    /// El SVG dentro de una página sin márgenes. Los dibujos del motor traen su propio fondo blanco.
    static func pagina(_ svg: String) -> String {
        """
        <!doctype html><html><head><meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <style>html,body{margin:0;height:100%;background:#fff}svg{width:100%;height:100%}</style>
        </head><body>\(svg)</body></html>
        """
    }

    /// El `WKWebView` de las dos plataformas: sin JavaScript, porque el SVG es solo un dibujo.
    static func crearVista() -> WKWebView {
        let preferencias = WKWebpagePreferences()
        preferencias.allowsContentJavaScript = false
        let configuracion = WKWebViewConfiguration()
        configuracion.defaultWebpagePreferences = preferencias
        return WKWebView(frame: .zero, configuration: configuracion)
    }

    /// Recuerda el último SVG cargado para no recargar la página si no ha cambiado.
    public final class Coordinador {
        var ultimo: String?
    }

    public func makeCoordinator() -> Coordinador { Coordinador() }

    func cargar(en vista: WKWebView, _ coordinador: Coordinador) {
        guard coordinador.ultimo != svg else { return }
        coordinador.ultimo = svg
        vista.loadHTMLString(VistaSVG.pagina(svg), baseURL: nil)
    }
}

#if os(macOS)
extension VistaSVG: NSViewRepresentable {
    public func makeNSView(context: Context) -> WKWebView {
        // La página trae su propio fondo blanco: no hace falta un fondo transparente.
        VistaSVG.crearVista()
    }

    public func updateNSView(_ vista: WKWebView, context: Context) {
        cargar(en: vista, context.coordinator)
    }
}
#else
extension VistaSVG: UIViewRepresentable {
    public func makeUIView(context: Context) -> WKWebView {
        let vista = VistaSVG.crearVista()
        vista.isOpaque = false
        vista.backgroundColor = .clear
        vista.scrollView.isScrollEnabled = false
        return vista
    }

    public func updateUIView(_ vista: WKWebView, context: Context) {
        cargar(en: vista, context.coordinator)
    }
}
#endif

@available(*, deprecated, renamed: "VistaSVG")
public typealias SVGView = VistaSVG
#endif
