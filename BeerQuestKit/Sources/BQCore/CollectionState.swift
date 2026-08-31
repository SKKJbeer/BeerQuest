import Foundation

/// Zustaende eines Sammelobjekts im Passport und bei Badges.
///
/// Der Passport soll sich wie ein Sammelobjekt anfuehlen, nicht wie eine
/// Tabelle (docs/14-product-dna.md §Passport). Deshalb sind die Zustaende
/// ein zentraler Typ und keine ad-hoc-Booleans in einzelnen Views.
public enum CollectionState: String, Codable, Hashable, Sendable, CaseIterable {
    /// Bekannt, aber noch nicht erreicht. Nur fuer **endliche** Mengen -
    /// nie fuer den offenen Bierkatalog (siehe Doku).
    case locked
    /// Entdeckt.
    case discovered
    /// Ein zugehoeriges Ziel wurde erfuellt (z. B. eine Quest in dieser Stadt).
    case completed
    /// Besondere Leistung.
    case mastered
}
