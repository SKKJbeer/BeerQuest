import SwiftUI

/// Zentrale Design-Tokens. **Regel: Kein View definiert eigene Farben,
/// Abstaende, Radien oder Schriftgroessen.** Alles kommt von hier, damit die
/// visuelle Identitaet spaeter an einer Stelle geaendert werden kann
/// (docs/15-design-system.md).
///
/// Visuelle Richtung: "Dark Adventure" (docs/13-visual-direction.md).
/// Dark-first, ein warmer Akzent, Tiefe ueber Flaechenhelligkeit statt
/// ueber Schatten.
public enum BQColor {

    // MARK: Flaechen - nie reines Schwarz, immer leicht warm entsaettigt
    /// Grundflaeche der App.
    public static let base       = Color(red: 0.067, green: 0.071, blue: 0.086)
    /// Karten und Listenzeilen.
    public static let surface    = Color(red: 0.106, green: 0.114, blue: 0.133)
    /// Hervorgehobene Flaechen, Eingabefelder.
    public static let surfaceRaised = Color(red: 0.149, green: 0.161, blue: 0.184)
    /// Trennlinien - sehr dezent, Tiefe entsteht ueber Helligkeit.
    public static let separator  = Color(red: 0.204, green: 0.216, blue: 0.243)

    // MARK: Akzent - genau einer, gebranntes Bernstein
    public static let accent     = Color(red: 0.937, green: 0.647, blue: 0.235)
    public static let accentDeep = Color(red: 0.788, green: 0.463, blue: 0.153)
    /// Fuer Text auf Akzentflaechen.
    public static let onAccent   = Color(red: 0.067, green: 0.071, blue: 0.086)

    // MARK: Text
    public static let textPrimary   = Color(red: 0.957, green: 0.953, blue: 0.937)
    public static let textSecondary = Color(red: 0.647, green: 0.647, blue: 0.639)
    public static let textTertiary  = Color(red: 0.435, green: 0.443, blue: 0.463)

    // MARK: Semantik
    public static let success = Color(red: 0.404, green: 0.741, blue: 0.478)
    public static let danger  = Color(red: 0.859, green: 0.376, blue: 0.337)

    // MARK: Sammelzustaende
    /// Materialstufen statt Neonrahmen - siehe Visual Direction.
    public static let copper = Color(red: 0.722, green: 0.451, blue: 0.302)
    public static let brass  = Color(red: 0.831, green: 0.686, blue: 0.353)
    public static let silver = Color(red: 0.741, green: 0.769, blue: 0.796)

    public static func tint(for state: CollectionStateToken) -> Color {
        switch state {
        case .locked:     textTertiary
        case .discovered: copper
        case .completed:  brass
        case .mastered:   silver
        }
    }
}

/// Spiegel von `BQCore.CollectionState`, damit `BQDesign` keine
/// Feature-Abhaengigkeit braucht. Bewusst klein gehalten.
public enum CollectionStateToken: String, Sendable {
    case locked, discovered, completed, mastered
}

/// Die Schrift. **Offene Entscheidung** (docs/13-visual-direction.md):
/// Der Prototyp V2 nutzt **Archivo** — eine Grotesk mit Breitenachse, die
/// als Gestaltungsmittel dient: Ueberschriften und Zahlen breit, Fliesstext
/// normal. Archivo steht unter der SIL Open Font License und laesst sich
/// mitliefern.
///
/// Bis die Schrift beschafft und gebuendelt ist (P0.11), verwendet die App
/// die Systemschrift. Der Prototyp sieht deshalb heute anders aus als die
/// App — das ist bewusst und im Handoff benannt.
public enum BQFontFamily {
    /// Wird gesetzt, sobald die Schrift im Bundle liegt.
    public static let display: String? = nil
    public static let body: String? = nil
}

public enum BQFont {
    /// Grosse Zahlen: XP, Level, Zaehler. Tabular, damit nichts springt.
    public static let numberXL = Font.system(size: 44, weight: .heavy, design: .rounded)
        .monospacedDigit()
    public static let number   = Font.system(size: 28, weight: .bold, design: .rounded)
        .monospacedDigit()
    public static let display  = Font.system(size: 32, weight: .bold, design: .rounded)
    public static let title    = Font.system(size: 22, weight: .semibold, design: .rounded)
    public static let headline = Font.system(size: 17, weight: .semibold)
    public static let body     = Font.system(size: 16, weight: .regular)
    public static let caption  = Font.system(size: 13, weight: .medium)
    /// Fuer Label ueber Zahlen: klein, gesperrt, versal.
    public static let label    = Font.system(size: 11, weight: .semibold)
}

public enum BQSpacing {
    public static let xs: CGFloat = 4
    public static let s:  CGFloat = 8
    public static let m:  CGFloat = 16
    public static let l:  CGFloat = 24
    public static let xl: CGFloat = 32
    public static let xxl: CGFloat = 48
}

public enum BQRadius {
    public static let small:  CGFloat = 8
    public static let card:   CGFloat = 18
    public static let sheet:  CGFloat = 28
    public static let pill:   CGFloat = 999
}

public enum BQMotion {
    /// Ruhige Uebergaenge im Alltag.
    public static let standard = Animation.easeOut(duration: 0.22)
    /// Der Reward-Moment darf laut sein - die eine Stelle, an der sich
    /// Beer Quest wie ein Spiel anfuehlen muss.
    public static let reward   = Animation.spring(response: 0.55, dampingFraction: 0.68)
}

/// Icon-Namen an einer Stelle. Heute SF Symbols als Platzhalter; sobald das
/// eigene Set existiert, wird nur diese Datei getauscht.
/// **Keine Emoji als UI-Icons** (docs/14-product-dna.md §Keine Emoji-UI).
public enum BQIcon {
    public static let home       = "house.fill"
    public static let map        = "map.fill"
    public static let quests     = "flag.fill"
    public static let clan       = "shield.fill"
    public static let profile    = "person.fill"
    public static let addCheckIn = "plus"
    public static let beer       = "drop.fill"
    public static let venue      = "mappin.circle.fill"
    public static let city       = "building.2.fill"
    public static let country    = "globe"
    public static let xp         = "bolt.fill"
    public static let badge      = "rosette"
    public static let locked     = "lock.fill"
    public static let friends    = "person.2.fill"
    public static let leaderboard = "chart.bar.fill"
}
