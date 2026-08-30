# Release-Gates

**Verbindliche Regel. Sie steht über Terminwünschen und über jedem
Feature-Vorschlag.**

Beer Quest kennt zwei Freigabestufen mit unterschiedlichem Pflichtenumfang.
Der Unterschied ist keine Auslegungssache: Interne TestFlight-Verteilung
durchläuft **kein Beta App Review**, jede externe Verteilung schon.

---

## Stufe 1 — Interner TestFlight

**Reduzierter P0-Scope ist zulässig.**

| | |
|---|---|
| Empfänger | Bis zu 100 Mitglieder des **eigenen** Entwicklungsteams (App Store Connect-Rollen) |
| Beta App Review | **Nicht erforderlich** |
| Freigabe durch | Uns selbst |
| Umfang | P0 nach `03-feature-matrix.md`, also ohne Social/City Quests, ohne Clan- und City-Leaderboard, ohne Universal Links, ohne Moderationswerkzeuge |

Erfüllt sein muss: die **Definition of Done P0** (16 Kriterien,
`02-product-gate.md` §3). Enthalten ist dort bereits das **Age Gate** — eine
Alkohol-App verteilen wir auch intern nicht ohne Altersabfrage.

---

## Stufe 2 — Externer Beta-Test oder App-Store-Release

**Kein reduzierter Scope. Diese Liste ist vollständig abzuarbeiten und zu
prüfen, bevor ein Build extern verteilt oder eingereicht wird.**

| # | Anforderung | Grundlage | Status |
|---|---|---|---|
| 1 | **Privacy Policy** öffentlich erreichbar, verlinkt in App und App Store Connect | App Review Guideline 5.1.1 | offen (P1) |
| 2 | **Terms / EULA** öffentlich erreichbar | Guideline 1.2 (UGC) | offen (P1) |
| 3 | **Account-Löschung in der App** — kein „Mail an den Support" | Guideline 5.1.1 (v) | offen (P1) |
| 4 | **Datenexport** (DSGVO-Auskunft) | DSGVO Art. 15/20 | offen (P1) |
| 5 | **Melden** von Nutzern, Clans und Orten | Guideline 1.2 | offen (P1) |
| 6 | **Blockieren** von Nutzern, wirksam in Suche, Listen und Leaderboards | Guideline 1.2 | offen (P1) |
| 7 | **Wortfilter** auf Username, Clan-Name und Clan-Beschreibung | Guideline 1.2 | Basis in P0, vollständig P1 |
| 8 | **Reaktion auf Meldungen binnen 24 Stunden** — ein tatsächlich gelebter Prozess, nicht nur ein Formular | Guideline 1.2 | offen (P1) |
| 9 | **Age Gate** und korrektes **Age Rating** (Alkoholbezug ⇒ 17+/18+) | Guideline 1.1.6, Ratings-Fragebogen | Age Gate ✅ P0, Rating offen |
| 10 | **Privacy Manifest** (`PrivacyInfo.xcprivacy`) und **App-Privacy-Labels** | Apple-Pflicht | offen (P1) |
| 11 | **Purpose Strings** für Standort, App funktioniert auch ohne Berechtigung | Guideline 5.1.1 | ✅ P0 |
| 12 | **Sign in with Apple** als einziger Login (oder zusätzlich, falls weitere hinzukommen) | Guideline 4.8 | ✅ P0 |
| 13 | **Review-Notes** mit Erklärung des XP-Systems: keine Belohnung von Trinkmenge, Tages-Cap, Age Gate | Guideline 1.1.6 / 1.4 | offen (P1) |
| 14 | **Responsible-Drinking-Hinweis** in der App | Sorgfalt, kein Guideline-Zwang | ✅ P0 (Settings) |
| 15 | **Attribution** GeoNames (CC BY 4.0) in den Credits | Lizenzpflicht | offen (P0.11) |
| 16 | **Demo-Account** für das Review-Team | Guideline 2.1 | offen (P1) |
| 17 | **Rechtliche Prüfung** der Apple-Maps-Nutzung, falls bis dahin POI-Daten genutzt werden | Apple Maps ToS §1.3 | entfällt aktuell — `MKLocalSearch` ist gestrichen (`10-risks.md` R2) |

Punkte 1–8, 10, 13 und 16 entsprechen dem P1-Paket ⚖️ im
Implementierungsplan (`09-implementation-plan.md`, P1-Reihenfolge 1–3,
zusammen ~5 Tage).

---

## Wie diese Regel angewendet wird

1. **Ein Build wird nicht extern verteilt**, solange auch nur eine Zeile aus
   Stufe 2 offen ist. „Wir reichen schon mal ein und liefern nach" ist keine
   Option — eine Ablehnung kostet mehr Zeit als die Umsetzung.
2. **Die Liste wird abgehakt, nicht erinnert.** Vor der ersten externen
   Verteilung wird diese Tabelle Zeile für Zeile im Handoff dokumentiert,
   mit Datum und Nachweis.
3. **Die Free-Tier-Zahlen werden vor Stufe 2 erneut verifiziert**
   (`04-cost-analysis.md` §8) — bis dahin sind Monate vergangen.
4. **Der Übergang von Stufe 1 zu Stufe 2 ist eine PM-Entscheidung**, keine
   technische. Sobald der Testkreis über das eigene Team hinausgeht, gilt
   Stufe 2 sofort und vollständig.
