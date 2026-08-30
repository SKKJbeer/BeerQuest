import SwiftUI
import BQCore
import BQDesign
import BQSession

@main
struct BeerQuestApp: App {
    @State private var session = SessionStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(session)
                .preferredColorScheme(.dark)
                .tint(BQColor.accent)
        }
    }
}
