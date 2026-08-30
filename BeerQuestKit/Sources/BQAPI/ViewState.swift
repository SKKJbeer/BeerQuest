import Foundation

/// Jeder datengetriebene Screen wird gegen genau dieses Enum spezifiziert -
/// siehe `docs/08-screens.md`. Damit ist "hat der Screen einen Empty State?"
/// keine Frage der Disziplin mehr, sondern des Compilers.
public enum ViewState<T> {
    case idle
    case loading
    case loaded(T)
    case empty
    case failed(BQError)

    public var value: T? {
        if case .loaded(let v) = self { return v }
        return nil
    }

    public var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }
}

public enum BQError: Error, Equatable, Sendable {
    case offline
    case unauthorized
    case rateLimited
    case notFound
    case conflict(String)
    case server(String)
    case decoding(String)

    /// Nutzertext. Nie ein technischer Code, nie ein leerer Screen.
    public var userMessage: String {
        switch self {
        case .offline:
            return "You're offline. We'll try again automatically."
        case .unauthorized:
            return "Your session expired. Please sign in again."
        case .rateLimited:
            return "Slow down a moment - too many requests."
        case .notFound:
            return "We couldn't find that."
        case .conflict(let message):
            return message
        case .server:
            return "Something went wrong on our side."
        case .decoding:
            return "We got an unexpected response."
        }
    }

    /// Nur wiederholbare Fehler landen in der RetryQueue.
    public var isRetryable: Bool {
        switch self {
        case .offline, .server, .rateLimited: return true
        case .unauthorized, .notFound, .conflict, .decoding: return false
        }
    }
}
