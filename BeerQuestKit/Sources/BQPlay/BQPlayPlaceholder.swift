import SwiftUI
import BQCore
import BQDesign

/// Platzhalter aus P0.1. Wird in den Feature-Phasen ersetzt -
/// siehe docs/09-implementation-plan.md.
public struct BQPlayPlaceholder: View {
    private let title: String

    public init(title: String) {
        self.title = title
    }

    public var body: some View {
        ZStack {
            ScreenBackground()
            EmptyState(icon: "hammer.fill",
                       message: "\(title) - coming in a later phase.")
        }
    }
}
