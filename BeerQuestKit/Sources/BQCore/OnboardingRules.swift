import Foundation

/// Die Regeln des Onboardings, **gespiegelt** von
/// `supabase/migrations/20260830000010_onboarding.sql`.
///
/// Warum ueberhaupt zweimal: Der Server entscheidet, die App darf nur
/// vorwegnehmen. Wer erst nach dem Tippen erfaehrt, dass ein Name nicht
/// geht, tippt zweimal — und wer einen Geburtsjahrgang eintippt, den der
/// Server ablehnt, verliert den letzten Schritt des Onboardings an eine
/// Fehlermeldung.
///
/// Weil damit etwas zweimal steht — und was zweimal steht, steht frueher
/// oder spaeter verschieden —, gilt hier eine harte Regel:
///
/// > **Diese Datei ist eine Kopie, keine zweite Quelle.** Aendert sich
/// > `check_username` oder die Alterspruefung im SQL, aendert sich diese
/// > Datei mit, im selben Commit. Die Tests in `OnboardingRulesTests`
/// > halten die Faelle fest, die im SQL stehen.
///
/// Der Server bleibt die Instanz, die entscheidet: Diese Pruefung ist
/// Bequemlichkeit, kein Schutz. `complete_onboarding` prueft alles noch
/// einmal, und nur dessen Urteil zaehlt.
public enum OnboardingRules {

    // MARK: - Username

    /// Warum ein Name nicht geht. Die Faelle heissen wie im SQL, damit
    /// sich beide Seiten ohne Uebersetzungstabelle vergleichen lassen.
    public enum UsernameProblem: String, Equatable, Sendable {
        /// Entspricht nicht `^[a-z0-9_]{3,20}$`.
        case format
        /// Enthaelt einen gesperrten Begriff.
        case notAllowed = "not_allowed"
        /// Schon vergeben. **Kann nur der Server wissen** - hier nie erzeugt.
        case taken
    }

    /// Der Grundstock aus `banned_terms`.
    ///
    /// Die vollstaendige Liste (~200 Begriffe, mehrsprachig) liegt bewusst
    /// als **Tabelle** auf dem Server: Sie ist Redaktionsarbeit und muss
    /// ohne App-Update pflegbar sein. Deshalb faengt die App hier nur das
    /// Offensichtliche ab und laesst den Rest den Server entscheiden - eine
    /// mitgelieferte Liste waere nach dem ersten Redaktionsschritt falsch.
    public static let bannedTermsSample: Set<String> = [
        "admin", "administrator", "moderator", "support",
        "beerquest", "beer_quest", "official", "staff",
        "system", "null", "undefined", "anonymous"
    ]

    /// `norm_name` aus `functions_core.sql`: klein, alles Nicht-Alphanumerische
    /// zu Leerzeichen, aussen getrimmt.
    public static func normalized(_ text: String) -> String {
        let lowered = text.lowercased()
        var out = ""
        var lastWasSpace = false
        for ch in lowered {
            if ch.isASCII && (ch.isLetter || ch.isNumber) {
                out.append(ch); lastWasSpace = false
            } else if !lastWasSpace {
                out.append(" "); lastWasSpace = true
            }
        }
        return out.trimmingCharacters(in: .whitespaces)
    }

    /// Was der Nutzer tippt, ist selten schon ein Handle. Statt ihn zu
    /// korrigieren, wird vorgeschlagen: "Steffen M." wird zu "steffen_m".
    public static func suggestedUsername(from typed: String) -> String {
        var out = ""
        for ch in typed.lowercased() {
            if ch.isASCII && (ch.isLetter || ch.isNumber) { out.append(ch) }
            else if !out.isEmpty && out.last != "_" { out.append("_") }
        }
        while out.last == "_" { out.removeLast() }
        return String(out.prefix(20))
    }

    /// Spiegel von `check_username`, ohne den Fall `taken` - der braucht
    /// die Datenbank, und ein Fehlschlag auf unserer Seite waere keine
    /// Auskunft ueber die Gegenseite.
    public static func problem(withUsername raw: String) -> UsernameProblem? {
        let candidate = raw.trimmingCharacters(in: .whitespaces).lowercased()
        guard candidate.count >= 3, candidate.count <= 20,
              candidate.allSatisfy({ $0.isASCII && ($0.isLowercase || $0.isNumber || $0 == "_") })
        else { return .format }

        let norm = normalized(candidate)
        for term in bannedTermsSample where norm == term || norm.contains(term) {
            return .notAllowed
        }
        return nil
    }

    // MARK: - Alter

    public enum AgeProblem: String, Equatable, Sendable {
        case required = "birth_year_required"
        case underage = "underage"
        case implausible = "birth_year_implausible"
    }

    public static let minimumAge = 18

    /// Spiegel der Alterspruefung: Jahresdifferenz, nicht volles Datum.
    ///
    /// Die Rechnung ist damit um bis zu ein Jahr **konservativ** - wer im
    /// Dezember geboren ist, gilt schon ab Januar als ein Jahr aelter. Beim
    /// Mindestalter ist das die falsche Richtung, aber es ist die Richtung,
    /// die der Server nimmt, und zwei Rechnungen waeren schlimmer als eine
    /// grosszuegige. Datenminimierung schlaegt hier Genauigkeit
    /// (docs/05-architecture.md §11).
    public static func problem(withBirthYear year: Int?, now: Date = Date(),
                               calendar: Calendar = .current) -> AgeProblem? {
        guard let year else { return .required }
        let currentYear = calendar.component(.year, from: now)
        let age = currentYear - year
        if age < minimumAge { return .underage }
        if age > 120 { return .implausible }
        return nil
    }

    /// Womit die Auswahl aufgeht. Nicht am Rand ("genau 18"), sondern in
    /// der Mitte des Erwartbaren - sonst muss fast jeder scrollen. Der
    /// Prototyp nimmt denselben Wert; zwei Vorgaben waeren zwei Produkte.
    public static func defaultBirthYear(now: Date = Date(),
                                        calendar: Calendar = .current) -> Int {
        calendar.component(.year, from: now) - 25
    }

    /// Das aelteste und juengste Jahr, das die Auswahl anbieten darf.
    /// Ausserhalb davon lehnt der Server ab - also gar nicht erst zeigen.
    public static func selectableBirthYears(now: Date = Date(),
                                            calendar: Calendar = .current) -> ClosedRange<Int> {
        let currentYear = calendar.component(.year, from: now)
        return (currentYear - 120)...(currentYear - minimumAge)
    }
}
