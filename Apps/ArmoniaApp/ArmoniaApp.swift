import SwiftUI
import Armonia

@main
struct ArmoniaApp: App {
    var body: some Scene {
        WindowGroup {
            VistaRaiz()
        }
    }
}

/// Las cuatro vistas de la app. Cada una tiene en su barra el selector de notación, que comparten
/// con el ajuste `notacion`.
struct VistaRaiz: View {
    var body: some View {
        TabView {
            NavigationStack { VistaAcordes() }
                .tabItem { Label("Acordes", systemImage: "music.note.list") }
            NavigationStack { VistaEscalas() }
                .tabItem { Label("Escalas", systemImage: "chart.bar.xaxis") }
            NavigationStack { VistaAnalisis() }
                .tabItem { Label("Análisis", systemImage: "waveform.path.ecg") }
            NavigationStack { VistaCoral() }
                .tabItem { Label("Coral", systemImage: "music.quarternote.3") }
        }
    }
}
