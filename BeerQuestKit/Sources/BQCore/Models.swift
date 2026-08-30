import Foundation

public struct UserProfile: Identifiable, Codable, Hashable, Sendable {
    public let id: UUID
    public var username: String
    public var displayName: String?
    public var avatarKey: String
    public var avatarColor: String
    public var level: Int
    public var xp: Int

    public init(id: UUID, username: String, displayName: String? = nil,
                avatarKey: String, avatarColor: String, level: Int, xp: Int) {
        self.id = id
        self.username = username
        self.displayName = displayName
        self.avatarKey = avatarKey
        self.avatarColor = avatarColor
        self.level = level
        self.xp = xp
    }
}

public enum DiscoveryKind: String, Codable, Sendable, CaseIterable {
    case beer, venue, city, country

    public var xpValue: Int {
        switch self {
        case .beer: XPDefaults.newBeer
        case .venue: XPDefaults.newVenue
        case .city: XPDefaults.newCity
        case .country: XPDefaults.newCountry
        }
    }
}

public struct Discovery: Codable, Hashable, Sendable {
    public let kind: DiscoveryKind
    public let name: String
}

/// Das Reward-Paket, das `create_check_in` zurueckgibt. Der Reward-Screen
/// rendert ausschliesslich dieses Objekt - kein Nachladen, keine Berechnung.
public struct CheckInReward: Codable, Hashable, Sendable {
    public let checkInID: UUID
    public let xpAwarded: Int
    public let xpCapped: Bool
    public let discoveries: [Discovery]
    public let levelBefore: Int
    public let levelAfter: Int
    public let clanXPAwarded: Int

    public var didLevelUp: Bool { levelAfter > levelBefore }
}

/// Das sichtbare naechste Ziel auf dem Home-Screen. Ohne diese Anzeige
/// arbeitet der Nutzer auf nichts hin - siehe `docs/02-product-gate.md` §1 E.
public struct NextGoal: Codable, Hashable, Sendable {
    public let label: String
    public let have: Int
    public let need: Int

    public var fraction: Double {
        need > 0 ? min(1, Double(have) / Double(need)) : 0
    }
}
