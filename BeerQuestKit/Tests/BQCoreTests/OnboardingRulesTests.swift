import XCTest
@testable import BQCore

/// Diese Tests halten die Swift-Kopie gegen die Faelle, die im SQL stehen
/// (`supabase/migrations/20260830000010_onboarding.sql`, geprueft von
/// `supabase/tests/07_onboarding.sql`).
///
/// Sie sind der Grund, warum die Doppelung ertraeglich ist: Wo etwas
/// zweimal steht, steht es frueher oder spaeter verschieden - es sei denn,
/// eine Pruefung haelt die Kopie gegen die Quelle.
final class OnboardingRulesTests: XCTestCase {

    // MARK: - Username, Format

    /// `^[a-z0-9_]{3,20}$` - woertlich aus `check_username`.
    func testUsernameFormatMatchesServerRegex() {
        XCTAssertNil(OnboardingRules.problem(withUsername: "steffen"))
        XCTAssertNil(OnboardingRules.problem(withUsername: "abc"))
        XCTAssertNil(OnboardingRules.problem(withUsername: "a_1"))
        XCTAssertNil(OnboardingRules.problem(withUsername: String(repeating: "a", count: 20)))

        XCTAssertEqual(OnboardingRules.problem(withUsername: "ab"), .format, "zwei Zeichen")
        XCTAssertEqual(OnboardingRules.problem(withUsername: ""), .format, "leer")
        XCTAssertEqual(OnboardingRules.problem(withUsername: String(repeating: "a", count: 21)),
                       .format, "21 Zeichen")
        XCTAssertEqual(OnboardingRules.problem(withUsername: "hat leerzeichen"), .format)
        XCTAssertEqual(OnboardingRules.problem(withUsername: "punkt.punkt"), .format)
        XCTAssertEqual(OnboardingRules.problem(withUsername: "bindestrich-nein"), .format)
        XCTAssertEqual(OnboardingRules.problem(withUsername: "umlautä"), .format)
        XCTAssertEqual(OnboardingRules.problem(withUsername: "emoji🍺"), .format)
    }

    /// Der Server kleinschreibt vor dem Vergleich. Grossbuchstaben sind
    /// also kein Formatfehler, sondern werden normalisiert.
    func testUppercaseIsNormalisedNotRejected() {
        XCTAssertNil(OnboardingRules.problem(withUsername: "Steffen"))
        XCTAssertNil(OnboardingRules.problem(withUsername: "  steffen  "), "aussen getrimmt")
    }

    // MARK: - Username, Wortfilter

    /// `is_term_allowed` prueft auf Gleichheit **und** auf Enthaltensein.
    /// Ein "admin" mitten im Namen genuegt.
    func testBannedTermsAreBlockedAlsoAsSubstring() {
        XCTAssertEqual(OnboardingRules.problem(withUsername: "admin"), .notAllowed)
        XCTAssertEqual(OnboardingRules.problem(withUsername: "xadminx"), .notAllowed)
        XCTAssertEqual(OnboardingRules.problem(withUsername: "beerquest"), .notAllowed)
        XCTAssertEqual(OnboardingRules.problem(withUsername: "the_moderator"), .notAllowed)
        XCTAssertEqual(OnboardingRules.problem(withUsername: "null"), .notAllowed)
    }

    /// `taken` braucht die Datenbank. Die App darf es nie behaupten - ein
    /// Fehlschlag auf der eigenen Seite ist keine Auskunft ueber die
    /// Gegenseite.
    func testClientNeverClaimsTaken() {
        for name in ["steffen", "lisa", "max", "anna"] {
            XCTAssertNotEqual(OnboardingRules.problem(withUsername: name), .taken)
        }
    }

    // MARK: - norm_name

    /// Spiegel von `norm_name`: klein, Nicht-Alphanumerisches zu einem
    /// Leerzeichen, aussen getrimmt.
    func testNormalizedMatchesSQL() {
        XCTAssertEqual(OnboardingRules.normalized("Steffen"), "steffen")
        XCTAssertEqual(OnboardingRules.normalized("  Bar   Aurora! "), "bar aurora")
        XCTAssertEqual(OnboardingRules.normalized("Café-Belge"), "caf belge")
        XCTAssertEqual(OnboardingRules.normalized(""), "")
        XCTAssertEqual(OnboardingRules.normalized("---"), "")
    }

    // MARK: - Vorschlag

    /// Was jemand tippt, ist selten schon ein Handle. Korrigiert wird nicht,
    /// vorgeschlagen wird.
    func testSuggestionProducesAValidUsername() {
        XCTAssertEqual(OnboardingRules.suggestedUsername(from: "Steffen M."), "steffen_m")
        XCTAssertEqual(OnboardingRules.suggestedUsername(from: "  Anna   Lena  "), "anna_lena")
        XCTAssertEqual(OnboardingRules.suggestedUsername(from: "Café Belge"), "caf_belge")
        XCTAssertEqual(OnboardingRules.suggestedUsername(from: "---"), "")
    }

    /// Der Vorschlag muss die Formatpruefung bestehen, sonst schlaegt die
    /// App etwas vor, das sie selbst ablehnt.
    func testSuggestionAlwaysPassesFormatWhenLongEnough() {
        for input in ["Steffen M.", "Anna-Lena", "der lange name mit vielen woertern hier",
                      "ÜBERRASCHUNG 99", "a b c"] {
            let s = OnboardingRules.suggestedUsername(from: input)
            guard s.count >= 3 else { continue }
            XCTAssertNotEqual(OnboardingRules.problem(withUsername: s), .format,
                              "Vorschlag \"\(s)\" aus \"\(input)\"")
        }
    }

    // MARK: - Alter

    private func date(year: Int) -> Date {
        var c = DateComponents(); c.year = year; c.month = 6; c.day = 15
        return Calendar(identifier: .gregorian).date(from: c)!
    }

    /// Jahresdifferenz, genau wie `extract(year from now()) - p_birth_year`.
    func testAgeUsesYearDifferenceLikeServer() {
        let heute = date(year: 2026)
        XCTAssertNil(OnboardingRules.problem(withBirthYear: 2008, now: heute), "genau 18")
        XCTAssertNil(OnboardingRules.problem(withBirthYear: 1990, now: heute))
        XCTAssertEqual(OnboardingRules.problem(withBirthYear: 2009, now: heute), .underage,
                       "17 - ein Jahr zu jung")
        XCTAssertEqual(OnboardingRules.problem(withBirthYear: nil, now: heute), .required)
        XCTAssertEqual(OnboardingRules.problem(withBirthYear: 1900, now: heute), .implausible,
                       "126 Jahre")
        XCTAssertNil(OnboardingRules.problem(withBirthYear: 1906, now: heute), "genau 120")
    }

    /// Das Mindestalter ist eine Produktentscheidung, keine Zufallszahl -
    /// faellt dieser Test, wurde an einer Regel gedreht, die Apple prueft.
    func testMinimumAgeIsEighteen() {
        XCTAssertEqual(OnboardingRules.minimumAge, 18)
    }

    /// Eine Vorauswahl, die der Server ablehnt, waere eine Falle: Der
    /// Knopf saehe aktiv aus und der letzte Schritt endete in einer Absage.
    func testDefaultYearIsAlwaysAccepted() {
        for jahr in [2026, 2030, 2100] {
            let heute = date(year: jahr)
            let vorgabe = OnboardingRules.defaultBirthYear(now: heute)
            XCTAssertNil(OnboardingRules.problem(withBirthYear: vorgabe, now: heute))
            XCTAssertTrue(OnboardingRules.selectableBirthYears(now: heute).contains(vorgabe),
                          "Vorgabe \(vorgabe) muss in der Auswahl stehen")
        }
    }

    /// Derselbe Wert wie im Prototyp (`docs/prototype/index.html`,
    /// `obJahreFuellen`). Zwei Vorgaben waeren zwei Produkte.
    func testDefaultYearIsTwentyFiveYearsBack() {
        XCTAssertEqual(OnboardingRules.defaultBirthYear(now: date(year: 2026)), 2001)
    }

    /// Die Auswahl darf nur Jahre anbieten, die der Server auch annimmt.
    /// Sonst tippt jemand etwas ein und bekommt danach eine Absage.
    func testSelectableYearsAreExactlyTheAcceptedOnes() {
        let heute = date(year: 2026)
        let range = OnboardingRules.selectableBirthYears(now: heute)
        XCTAssertEqual(range, 1906...2008)
        for jahr in [range.lowerBound, 1950, range.upperBound] {
            XCTAssertNil(OnboardingRules.problem(withBirthYear: jahr, now: heute),
                         "Jahr \(jahr) wird angeboten, muss also angenommen werden")
        }
        XCTAssertNotNil(OnboardingRules.problem(withBirthYear: range.upperBound + 1, now: heute))
        XCTAssertNotNil(OnboardingRules.problem(withBirthYear: range.lowerBound - 1, now: heute))
    }
}
