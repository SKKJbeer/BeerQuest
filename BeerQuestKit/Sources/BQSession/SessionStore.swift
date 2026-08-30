import Foundation
import Observation
import BQCore
import BQAPI

/// Der einzige Ort, an dem "wer bin ich" steht.
/// Wird in P0.3 mit Sign in with Apple und `complete_onboarding` gefuellt.
@Observable
public final class SessionStore {

    public enum State: Equatable {
        /// Beim Start: Token wird geprueft.
        case launching
        /// Kein Token - Welcome-Screen.
        case signedOut
        /// Token vorhanden, aber noch kein Profil - Onboarding.
        case onboarding
        /// Spielfaehiger Account.
        case ready(UserProfile)

        public static func == (lhs: State, rhs: State) -> Bool {
            switch (lhs, rhs) {
            case (.launching, .launching), (.signedOut, .signedOut),
                 (.onboarding, .onboarding):
                return true
            case (.ready(let a), .ready(let b)):
                return a.id == b.id && a.xp == b.xp && a.level == b.level
            default:
                return false
            }
        }
    }

    public private(set) var state: State = .launching

    public init() {}

    public var profile: UserProfile? {
        if case .ready(let p) = state { return p }
        return nil
    }

    public func apply(_ newState: State) {
        state = newState
    }
}
