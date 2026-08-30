import Foundation

/// Die XP- und Level-Regeln aus `docs/06-data-model.md` §3.
///
/// Wichtig: Diese Werte sind eine *Spiegelung* der serverseitigen Wahrheit.
/// Der Server rechnet verbindlich; der Client nutzt sie ausschliesslich zum
/// Rendern von Fortschrittsbalken und Vorschauen. Es wird nie ein XP-Wert
/// lokal geschaetzt und spaeter korrigiert.
public enum Progression {

    /// XP, die innerhalb von `level` gesammelt werden muessen, um aufzusteigen.
    /// Level 7 -> 3.500 XP, identisch zum Beispiel in Product Vision §11.
    public static func xpNeeded(forLevel level: Int) -> Int {
        precondition(level >= 1, "Level beginnt bei 1")
        return 500 * level
    }

    /// Gesamte XP, die noetig sind, um `level` ueberhaupt zu erreichen.
    /// Summe von 500*1 + 500*2 + ... + 500*(level-1) = 250 * level * (level-1).
    public static func totalXP(toReachLevel level: Int) -> Int {
        precondition(level >= 1, "Level beginnt bei 1")
        return 250 * level * (level - 1)
    }

    /// Level fuer eine gegebene Gesamt-XP-Zahl.
    ///
    /// Geschlossene Form: groesstes n mit 250n(n-1) <= xp, also
    /// n = floor((250 + sqrt(62500 + 1000*xp)) / 500).
    /// Die Korrekturschleife faengt Gleitkomma-Ungenauigkeit an den
    /// Level-Grenzen ab - dort ist ein Off-by-one am sichtbarsten.
    public static func level(forTotalXP xp: Int) -> Int {
        guard xp > 0 else { return 1 }
        let approx = (250.0 + (62_500.0 + 1_000.0 * Double(xp)).squareRoot()) / 500.0
        var level = max(1, Int(approx))
        while totalXP(toReachLevel: level + 1) <= xp { level += 1 }
        while level > 1 && totalXP(toReachLevel: level) > xp { level -= 1 }
        return level
    }

    /// Fortschritt innerhalb des aktuellen Levels - genau das, was die
    /// XP-Bar anzeigt ("2,840 / 3,500").
    public static func progress(forTotalXP xp: Int) -> (level: Int, inLevel: Int, needed: Int) {
        let level = self.level(forTotalXP: xp)
        return (level, xp - totalXP(toReachLevel: level), xpNeeded(forLevel: level))
    }

    /// Anteil der persoenlichen XP, der zusaetzlich dem Clan gutgeschrieben wird.
    /// 500 persoenlich -> 300 Clan, exakt wie in Product Vision §17.
    public static let clanXPRatio = 0.6

    public static func clanXP(forPersonalXP amount: Int) -> Int {
        Int((Double(amount) * clanXPRatio).rounded())
    }
}

/// Werte, die serverseitig in `app_config` liegen und ohne App-Update
/// aenderbar sind. Die Konstanten hier sind nur Anzeige-Defaults, damit die
/// UI vor dem ersten Serverkontakt etwas Sinnvolles rendern kann.
public enum XPDefaults {
    public static let newBeer = 50
    public static let newVenue = 50
    public static let newCity = 150
    public static let newCountry = 300
    public static let repeatCheckIn = 10
    public static let friendship = 25

    /// Taegliches Maximum aus Check-ins und Entdeckungen. Quest- und Sozial-XP
    /// sind ausgenommen. Setzt Product Vision §2 technisch um: Menge zahlt sich
    /// nicht aus.
    ///
    /// **Eine Ausnahme:** Der allererste Check-in eines Nutzers ist vom Cap
    /// ausgenommen und kann bis zu 550 XP geben (Bier + Ort + Stadt + Land).
    /// Der wichtigste Moment der App soll nicht mit "XP capped today" enden.
    /// Die Regel wird ausschliesslich serverseitig durchgesetzt
    /// (`create_check_in`); der Client zeigt nur an, was der Server liefert.
    public static let dailyCap = 500

    /// Nur so viele Wiederholungs-Check-ins pro Tag geben ueberhaupt XP.
    public static let maxScoringRepeatsPerDay = 6
}
