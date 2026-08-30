import XCTest
@testable import BQCore

final class ProgressionTests: XCTestCase {

    /// Product Vision §11 zeigt "LEVEL 7 - 2,840 / 3,500 XP".
    /// Die Kurve muss dieses Beispiel exakt treffen.
    func testLevelSevenNeeds3500() {
        XCTAssertEqual(Progression.xpNeeded(forLevel: 7), 3_500)
    }

    func testTotalXPToReachLevel() {
        XCTAssertEqual(Progression.totalXP(toReachLevel: 1), 0)
        XCTAssertEqual(Progression.totalXP(toReachLevel: 2), 500)
        XCTAssertEqual(Progression.totalXP(toReachLevel: 3), 1_500)
        XCTAssertEqual(Progression.totalXP(toReachLevel: 7), 10_500)
    }

    func testLevelBoundariesAreExact() {
        XCTAssertEqual(Progression.level(forTotalXP: 0), 1)
        XCTAssertEqual(Progression.level(forTotalXP: 499), 1)
        XCTAssertEqual(Progression.level(forTotalXP: 500), 2)
        XCTAssertEqual(Progression.level(forTotalXP: 1_499), 2)
        XCTAssertEqual(Progression.level(forTotalXP: 1_500), 3)
        XCTAssertEqual(Progression.level(forTotalXP: 10_500), 7)
        XCTAssertEqual(Progression.level(forTotalXP: 10_499), 6)
    }

    func testNegativeAndZeroXPStayAtLevelOne() {
        XCTAssertEqual(Progression.level(forTotalXP: -1), 1)
        XCTAssertEqual(Progression.level(forTotalXP: 0), 1)
    }

    /// Die geschlossene Form darf an keiner Level-Grenze um eins danebenliegen.
    /// Geprueft wird jeder Uebergang bis Level 200 - dort ist Gleitkomma-
    /// Ungenauigkeit am wahrscheinlichsten.
    func testClosedFormMatchesBoundariesUpToLevel200() {
        for level in 1...200 {
            let threshold = Progression.totalXP(toReachLevel: level)
            XCTAssertEqual(Progression.level(forTotalXP: threshold), level,
                           "Grenze fuer Level \(level)")
            if level > 1 {
                XCTAssertEqual(Progression.level(forTotalXP: threshold - 1), level - 1,
                               "Ein XP unter der Grenze fuer Level \(level)")
            }
        }
    }

    func testProgressWithinLevel() {
        // 10.500 XP = exakt Level 7, 2.840 XP weiter = das Beispiel aus §11.
        let p = Progression.progress(forTotalXP: 10_500 + 2_840)
        XCTAssertEqual(p.level, 7)
        XCTAssertEqual(p.inLevel, 2_840)
        XCTAssertEqual(p.needed, 3_500)
    }

    /// Product Vision §17: "+500 Personal XP / +300 Clan XP".
    func testClanXPMatchesVisionExample() {
        XCTAssertEqual(Progression.clanXP(forPersonalXP: 500), 300)
        XCTAssertEqual(Progression.clanXP(forPersonalXP: 200), 120)
        XCTAssertEqual(Progression.clanXP(forPersonalXP: 0), 0)
    }

    func testClanXPRounding() {
        // 50 * 0.6 = 30 exakt; 25 * 0.6 = 15 exakt; 5 * 0.6 = 3 exakt.
        XCTAssertEqual(Progression.clanXP(forPersonalXP: 50), 30)
        XCTAssertEqual(Progression.clanXP(forPersonalXP: 25), 15)
        XCTAssertEqual(Progression.clanXP(forPersonalXP: 10), 6)
    }

    /// Der Tages-Cap ist die technische Umsetzung von Product Vision §2.
    /// Wenn dieser Test faellt, belohnt die App wieder Trinkmenge.
    func testDailyCapIsBelowFourNewCountries() {
        XCTAssertLessThan(XPDefaults.dailyCap, 4 * XPDefaults.newCountry)
        XCTAssertEqual(XPDefaults.dailyCap, 500)
    }

    func testDiscoveryXPValues() {
        XCTAssertEqual(DiscoveryKind.beer.xpValue, 50)
        XCTAssertEqual(DiscoveryKind.venue.xpValue, 50)
        XCTAssertEqual(DiscoveryKind.city.xpValue, 150)
        XCTAssertEqual(DiscoveryKind.country.xpValue, 300)
    }
}
