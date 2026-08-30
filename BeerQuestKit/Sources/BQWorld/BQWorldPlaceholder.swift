import SwiftUI
import BQCore
import BQDesign

/// Platzhalter aus P0.1. Wird in den Feature-Phasen ersetzt -
/// siehe docs/09-implementation-plan.md.
public struct BQWorldPlaceholder: View {
    private let title: String

    public init(title: String) {
        self.title = title
    }

    public var body: some View {
        ZStack {
            BQColor.background.ignoresSafeArea()
            EmptyState(icon: "\u{1F6A7}", message: "\(title) - coming in a later phase.")
        }
    }
}
