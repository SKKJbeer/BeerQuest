#!/usr/bin/env python3
"""
Haelt die Design-Tokens des Prototyps gegen die der App.

Anlass: Aus PulseMeter uebernommen, Abschnitt "Dieselbe Sache an zwei Orten
laeuft auseinander - jedes Mal". Dort kostete genau dieses Muster zwei Wochen
lang eine oeffentlich falsche Preisangabe.

Bei uns stehen die Farben zweimal: in BQDesign/Tokens.swift als RGB-Fliesskomma
und in docs/prototype/index.html als Hex. Der Prototyp ist die Vorlage fuer die
App - laufen beide auseinander, entscheidet der PM anhand von Farben, die es
in der App nie geben wird.

Ein Ort waere besser. Den gibt es hier nicht: Swift kann kein CSS lesen und
umgekehrt. Also die zweitbeste Bauart - eine Pruefung, die die Quelle liest
und den anderen Ort dagegenhaelt.
"""
import re, sys, pathlib

root = pathlib.Path(__file__).resolve().parent.parent
swift = (root / "BeerQuestKit/Sources/BQDesign/Tokens.swift").read_text(encoding="utf-8")
html  = (root / "docs/prototype/index.html").read_text(encoding="utf-8")

# Swift: public static let base = Color(red: 0.067, green: 0.071, blue: 0.086)
SWIFT = re.compile(
    r"static let (\w+)\s*=\s*Color\(red:\s*([\d.]+),\s*green:\s*([\d.]+),\s*blue:\s*([\d.]+)\)")
swift_tokens = {
    name: "#%02x%02x%02x" % tuple(round(float(v) * 255) for v in (r, g, b))
    for name, r, g, b in SWIFT.findall(swift)
}

# CSS: --base:#111216;
css_tokens = dict(re.findall(r"--([a-z0-9-]+):\s*(#[0-9a-fA-F]{6})", html))
css_tokens = {k: v.lower() for k, v in css_tokens.items()}

# Zuordnung. Nur was in beiden Welten dieselbe Rolle hat - Namen unterscheiden
# sich bewusst (Swift camelCase, CSS kebab-case und kuerzer).
PAARE = {
    "base": "base", "surface": "surface", "surfaceRaised": "raised",
    "separator": "separator", "accent": "accent", "accentDeep": "accent-deep",
    "onAccent": "on-accent", "textPrimary": "ink-1", "textSecondary": "ink-2",
    "textTertiary": "ink-3", "copper": "copper", "brass": "brass",
    "silver": "silver", "success": "success",
}

fehler = []
for swift_name, css_name in PAARE.items():
    a, b = swift_tokens.get(swift_name), css_tokens.get(css_name)
    if a is None:
        fehler.append(f"{swift_name} fehlt in Tokens.swift")
    elif b is None:
        fehler.append(f"--{css_name} fehlt im Prototyp")
    elif a != b:
        fehler.append(f"{swift_name} ist {a} in der App, --{css_name} aber {b} im Prototyp")
    else:
        print(f"  ok   {swift_name:15s} {a}")

if fehler:
    print("\nDie Tokens sind auseinandergelaufen:")
    for f in fehler:
        print("  FEHL " + f)
    print("\nEine der beiden Seiten ist falsch. Der Prototyp ist die Vorlage -")
    print("also im Zweifel Tokens.swift nachziehen, nicht umgekehrt.")
    sys.exit(1)

print(f"\n{len(PAARE)} Tokens stimmen in App und Prototyp ueberein.")
