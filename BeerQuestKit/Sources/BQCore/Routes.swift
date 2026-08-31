import Foundation

/// Die fuenf Tabs aus `docs/05-architecture.md` §9.
/// Der Add-Button ist bewusst kein Tab: Er hat keinen Zustand, den man
/// verlassen moechte, und oeffnet deshalb ein Sheet.
///
/// Praefix `BQ`, weil SwiftUI seit der neuen TabView-API selbst einen Typ
/// `Tab` mitbringt. Ohne Praefix ist die Typsuche in jeder Datei mehrdeutig,
/// die sowohl SwiftUI als auch BQCore importiert - also in praktisch jedem View.
public enum BQTab: String, Hashable, CaseIterable, Sendable {
    case home, map, quests, clan, profile
}

public enum HomeRoute: Hashable, Sendable {
    case quest(UUID)
    case history
}

public enum MapRoute: Hashable, Sendable {
    case venue(UUID)
}

public enum QuestRoute: Hashable, Sendable {
    case detail(UUID)
}

public enum ClanRoute: Hashable, Sendable {
    case create
    case join
    case detail(UUID)
}

public enum ProfileRoute: Hashable, Sendable {
    case passport(DiscoveryKind)
    case friends
    case addFriend
    case otherProfile(UUID)
    case history
    case settings
}
