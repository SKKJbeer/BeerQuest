# Design System

**Regel: Kein View definiert eigene Farben, Abstände, Radien oder
Schriftgrößen.** Alles kommt aus `BQDesign/Tokens.swift`. Damit lässt sich
die visuelle Identität später an einer Stelle ändern, statt in 28 Screens.

Visuelle Richtung: **Dark Adventure** (`13-visual-direction.md`) — zur
Bestätigung durch den PM.

## Tokens (`BQDesign/Tokens.swift`)

| Gruppe | Inhalt |
|---|---|
| `BQColor` | Flächen (`base`, `surface`, `surfaceRaised`, `separator`), Akzent (`accent`, `accentDeep`, `onAccent`), Text (3 Stufen), Semantik (`success`, `danger`), Materialstufen (`copper`, `brass`, `silver`) |
| `BQFont` | `numberXL`, `number` (beide tabular), `display`, `title`, `headline`, `body`, `caption`, `label` |
| `BQSpacing` | `xs` 4 · `s` 8 · `m` 16 · `l` 24 · `xl` 32 · `xxl` 48 |
| `BQRadius` | `small` 8 · `card` 18 · `sheet` 28 · `pill` |
| `BQMotion` | `standard` (ruhig) · `reward` (der eine laute Moment) |
| `BQIcon` | **alle** Icon-Namen an einer Stelle — heute SF Symbols, später das eigene Set |

Kein reines Schwarz, keine Verläufe als Flächen, kein Glow. Tiefe entsteht
über Flächenhelligkeit, nicht über Schatten.

## Komponenten (`BQDesign/Components.swift`)

`ScreenBackground` · `Card` · `PrimaryButton` · `XPBar` · `NextGoalRow` ·
`CollectibleTile` · `AvatarView` · `EmptyState` · `ErrorCard`

`CollectibleTile` rendert die vier Sammelzustände aus
`BQCore.CollectionState` (`locked`/`discovered`/`completed`/`mastered`) als
Materialstufen — nicht als Neonrahmen.

## Noch offen (bewusst, keine Richtungsfragen)

Schriften (Lizenz prüfen, 0 € bevorzugt: Google Fonts oder OFL),
eigenes Icon-Set, Badge-Illustrationen, Clan-Embleme, Kartenstil.
Das sind Beschaffungsentscheidungen — sie kommen, sobald die Richtung
bestätigt ist.

## Prüfregel bei jedem neuen View

1. Hardcodierte Farbe, Zahl oder Symbolname im View? → gehört in die Tokens.
2. Emoji als UI-Element? → nicht zulässig (`14-product-dna.md`).
3. Neuer Zustand für ein Sammelobjekt? → gehört in `CollectionState`.
