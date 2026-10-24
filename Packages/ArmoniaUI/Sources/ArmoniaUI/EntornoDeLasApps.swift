#if canImport(SwiftUI)
import SwiftUI
import Armonia
import ArmoniaPresentacion

// Lo que comparten las vistas de las apps: la notación elegida, en el entorno, y los cálculos que se hacen
// fuera del hilo principal mientras se escribe.

private struct ClaveDeEntornoDeNotacion: EnvironmentKey {
    static let defaultValue = Notacion.espanol
}

extension EnvironmentValues {
    /// La notación elegida en las apps. La pone `notacionGuardada()` en la raíz de cada app; cada vista la
    /// lee con `@Environment(\.notacion)`.
    public var notacion: Notacion {
        get { self[ClaveDeEntornoDeNotacion.self] }
        set { self[ClaveDeEntornoDeNotacion.self] = newValue }
    }
}

/// Lee la notación guardada en los ajustes (o, si no se ha elegido ninguna, la del idioma del sistema) y la
/// pone en el entorno. El selector de la barra escribe en el mismo ajuste.
struct NotacionGuardada: ViewModifier {
    @AppStorage(AjustesDeLasApps.claveDeNotacion) private var clave = Notacion.delSistema().clave

    func body(content: Content) -> some View {
        content.environment(\.notacion, .desde(clave: clave))
    }
}

extension View {
    /// Pone en el entorno la notación guardada en los ajustes. Va en la raíz de cada app:
    ///
    ///     WindowGroup { VistaRaiz().notacionGuardada() }
    public func notacionGuardada() -> some View {
        modifier(NotacionGuardada())
    }

    /// Calcula `calculo` fuera del hilo principal cada vez que cambia `clave`, tras `espera` segundos sin
    /// cambios (mientras se escribe), y lo guarda en `resultado`. Si la clave cambia mientras tanto, el
    /// cálculo se descarta. `calculo` solo debe depender de lo que entra en la clave.
    ///
    ///     @State private var digitaciones: Calculado<[Digitacion]>?
    ///     …
    ///     .calcularEnSegundoPlano(para: claveActual, en: $digitaciones) { [texto] in … }
    public func calcularEnSegundoPlano<Valor: Sendable>(
        para clave: String, esperando espera: Double = 0.25, en resultado: Binding<Calculado<Valor>?>,
        _ calculo: @escaping @Sendable () -> Valor
    ) -> some View {
        task(id: clave) {
            // Espera a que se deje de escribir; si cambia la clave, la tarea se cancela aquí.
            try? await Task.sleep(nanoseconds: UInt64(espera * 1_000_000_000))
            guard !Task.isCancelled else { return }
            let valor = await Task.detached(priority: .userInitiated) { calculo() }.value
            guard !Task.isCancelled else { return }
            resultado.wrappedValue = Calculado(clave: clave, valor: valor)
        }
    }
}

/// Un valor y la clave para la que se calculó (el texto, el instrumento, la notación…).
public struct Calculado<Valor> {
    public let clave: String
    public let valor: Valor

    /// El valor si se calculó para `clave`; si no (aún se está calculando el nuevo), `nil`.
    public func valor(para clave: String) -> Valor? {
        self.clave == clave ? valor : nil
    }
}

/// «Calculando…» con su indicador, para mientras no hay resultado.
public struct FilaCalculando: View {
    @Environment(\.notacion) private var notacion

    public init() {}

    public var body: some View {
        HStack {
            ProgressView()
            Text(notacion.texto(.calculando)).foregroundColor(.secondary)
        }
    }
}
#endif
