import SwiftUI
import Armonia
import HexaphonosUI

@main
struct ArmoniaApp: App {
    var body: some Scene {
        WindowGroup {
            VistaRaiz()
                .notacionGuardada()
        }
    }
}

/// Las cuatro vistas de la app. Cada una tiene en su barra el selector de notación; la elegida está en el
/// entorno (`notacionGuardada()`) y decide también el idioma de la interfaz.
struct VistaRaiz: View {
    @Environment(\.notacion) private var notacion

    var body: some View {
        TabView {
            NavigationStack { VistaDeAcordes() }
                .tabItem { Label(notacion.texto(.acordes), systemImage: "music.note.list") }
            NavigationStack { VistaDeEscalas() }
                .tabItem { Label(notacion.texto(.escalas), systemImage: "chart.bar.xaxis") }
            NavigationStack { VistaDeAnalisis() }
                .tabItem { Label(notacion.texto(.analisis), systemImage: "waveform.path.ecg") }
            NavigationStack { VistaDeCoral() }
                .tabItem { Label(notacion.texto(.coral), systemImage: "music.quarternote.3") }
        }
    }
}
