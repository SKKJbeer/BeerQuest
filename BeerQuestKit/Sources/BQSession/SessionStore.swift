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

    /// **Attrappe bis P0.5.** Setzt den Zustand nur lokal, damit der Weg
    /// durchs Onboarding begehbar ist, solange weder Sign in with Apple
    /// noch der Aufruf von `complete_onboarding` existieren.
    ///
    /// Sie heisst absichtlich `local`: Wer sie liest, soll nicht glauben,
    /// hier sei ein Account entstanden. Es ist keiner. Sobald P0.5 den
    /// echten Aufruf bringt, faellt diese Methode ersatzlos weg - deshalb
    /// steht sie hier und nicht mitten im View, wo sie jemand uebersehen
    /// wuerde.
    ///
    /// Das Geburtsjahr wird bewusst **nicht** gespeichert: Es geht an den
    /// Server, der die Altersgrenze durchsetzt, und wird danach nicht mehr
    /// gebraucht. Was man nicht haelt, kann man nicht verlieren
    /// (docs/05-architecture.md §11).
    public func applyLocalOnboardingResult(username: String, birthYear: Int) {
        state = .ready(UserProfile(id: UUID(),
                                   username: username,
                                   avatarKey: "mug_01",
                                   avatarColor: "amber",
                                   level: 1,
                                   xp: 0))
    }
}
