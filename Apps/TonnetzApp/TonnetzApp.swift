import SwiftUI
import Armonia
import HexaphonosUI

@main
struct TonnetzApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationStack { VistaTonnetz() }
                .notacionGuardada()
        }
    }
}
