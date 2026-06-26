import SwiftUI

@main
struct TOEICRulerApp: App {
    @StateObject private var store = AppDataStore()

    var body: some Scene {
        WindowGroup {
            AppLayout()
                .environmentObject(store)
        }
    }
}
