import SwiftUI
import Armonia
import ArmoniaUI

@main
struct TonnetzApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationStack { VistaDeTonnetz() }
                .notacionGuardada()
        }
    }
}
