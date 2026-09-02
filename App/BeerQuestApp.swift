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
                .task {
                    // P0.5 ersetzt das durch die Tokenpruefung. Bis dahin
                    // startet die App im Onboarding - `launching` haette
                    // sonst einen schwarzen Schirm ohne Ausweg ergeben.
                    if session.state == .launching { session.apply(.onboarding) }
                }
                .preferredColorScheme(.dark)
                .tint(BQColor.accent)
        }
    }
}
