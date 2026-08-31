import SwiftUI
import BQCore

// MARK: - Flaechen

public struct Card<Content: View>: View {
    private let content: Content
    public init(@ViewBuilder content: () -> Content) { self.content = content() }

    public var body: some View {
        content
            .padding(BQSpacing.m)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(BQColor.surface)
            .clipShape(RoundedRectangle(cornerRadius: BQRadius.card, style: .continuous))
    }
}

/// Hintergrund jeder Vollbildansicht. Nie direkt `Color.black`.
public struct ScreenBackground: View {
    public init() {}
    public var body: some View { BQColor.base.ignoresSafeArea() }
}

// MARK: - Aktionen

public struct PrimaryButton: View {
    private let title: String
    private let isLoading: Bool
    private let action: () -> Void

    public init(_ title: String, isLoading: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.isLoading = isLoading
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: BQSpacing.s) {
                if isLoading { ProgressView().tint(BQColor.onAccent) }
                Text(title).font(BQFont.headline)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, BQSpacing.m)
            .background(BQColor.accent)
            .foregroundStyle(BQColor.onAccent)
            .clipShape(RoundedRectangle(cornerRadius: BQRadius.card, style: .continuous))
        }
        .disabled(isLoading)
    }
}

// MARK: - Progression

/// Der Fortschrittsbalken. Prominent, nicht in einer Fusszeile -
/// der Nutzer soll jederzeit sehen, worauf er hinarbeitet.
public struct XPBar: View {
    private let level: Int
    private let inLevel: Int
    private let needed: Int

    public init(totalXP: Int) {
        let p = Progression.progress(forTotalXP: totalXP)
        self.level = p.level
        self.inLevel = p.inLevel
        self.needed = p.needed
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: BQSpacing.xs) {
            HStack(alignment: .firstTextBaseline) {
                Text("LEVEL").font(BQFont.label)
                    .foregroundStyle(BQColor.textTertiary)
                Text("\(level)").font(BQFont.number)
                Spacer()
                Text("\(inLevel.formatted()) / \(needed.formatted()) XP")
                    .font(BQFont.caption)
                    .foregroundStyle(BQColor.textSecondary)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(BQColor.surfaceRaised)
                    Capsule().fill(BQColor.accent)
                        .frame(width: max(0, geo.size.width * fraction))
                }
            }
            .frame(height: 8)
        }
        .foregroundStyle(BQColor.textPrimary)
    }

    private var fraction: Double {
        needed > 0 ? min(1, Double(inLevel) / Double(needed)) : 0
    }
}

/// Das sichtbare naechste Ziel. Ohne diese Anzeige arbeitet der Nutzer
/// auf nichts hin (docs/02-product-gate.md §1 E).
public struct NextGoalRow: View {
    private let label: String
    private let have: Int
    private let need: Int

    public init(label: String, have: Int, need: Int) {
        self.label = label
        self.have = have
        self.need = need
    }

    public var body: some View {
        HStack(spacing: BQSpacing.s) {
            Image(systemName: BQIcon.badge)
                .foregroundStyle(BQColor.accent)
            VStack(alignment: .leading, spacing: 2) {
                Text("NEXT").font(BQFont.label)
                    .foregroundStyle(BQColor.textTertiary)
                Text(label).font(BQFont.headline)
                    .foregroundStyle(BQColor.textPrimary)
            }
            Spacer()
            Text("\(have)/\(need)")
                .font(BQFont.number)
                .foregroundStyle(BQColor.accent)
        }
    }
}

// MARK: - Sammelobjekte

/// Ein Sammelobjekt im Passport. Die vier Zustaende sind zentral definiert,
/// damit sie ueberall gleich aussehen und spaeter an einer Stelle
/// aufgewertet werden koennen.
public struct CollectibleTile: View {
    private let icon: String
    private let title: String
    private let state: CollectionState

    public init(icon: String, title: String, state: CollectionState) {
        self.icon = icon
        self.title = title
        self.state = state
    }

    public var body: some View {
        VStack(spacing: BQSpacing.s) {
            ZStack {
                Circle()
                    .fill(BQColor.surfaceRaised)
                    .overlay(Circle().strokeBorder(tint.opacity(0.5), lineWidth: 1.5))
                Image(systemName: state == .locked ? BQIcon.locked : icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(tint)
            }
            .frame(width: 64, height: 64)

            Text(title)
                .font(BQFont.caption)
                .foregroundStyle(state == .locked ? BQColor.textTertiary : BQColor.textPrimary)
                .lineLimit(1)
        }
        .opacity(state == .locked ? 0.55 : 1)
    }

    private var tint: Color {
        BQColor.tint(for: CollectionStateToken(rawValue: state.rawValue) ?? .locked)
    }
}

// MARK: - Identitaet

/// Avatare kommen aus dem App-Bundle, nicht aus einem Upload - das spart
/// Storage, Egress und Bildmoderation (docs/04-cost-analysis.md §1).
///
/// Bis das Illustrations-Set vorliegt: Monogramm auf gefaerbter Flaeche.
/// **Bewusst kein Emoji** (docs/14-product-dna.md §Keine Emoji-UI).
public struct AvatarView: View {
    private let monogram: String
    private let color: String
    private let size: CGFloat

    public init(monogram: String, color: String, size: CGFloat = 44) {
        self.monogram = monogram
        self.color = color
        self.size = size
    }

    /// Bequemer Aufruf mit einem Profil.
    public init(username: String, color: String, size: CGFloat = 44) {
        self.init(monogram: String(username.prefix(1)).uppercased(),
                  color: color, size: size)
    }

    public var body: some View {
        Circle()
            .fill(Self.palette[color] ?? BQColor.accent)
            .frame(width: size, height: size)
            .overlay(
                Text(monogram)
                    .font(.system(size: size * 0.42, weight: .bold, design: .rounded))
                    .foregroundStyle(BQColor.onAccent)
            )
    }

    public static let palette: [String: Color] = [
        "amber":  BQColor.accent,
        "copper": BQColor.copper,
        "brass":  BQColor.brass,
        "forest": Color(red: 0.259, green: 0.494, blue: 0.353),
        "slate":  Color(red: 0.400, green: 0.447, blue: 0.514),
        "plum":   Color(red: 0.494, green: 0.318, blue: 0.514),
    ]
}

// MARK: - Zustaende

/// Empty States sind bei einer frisch installierten App der eigentliche
/// Onboarding-Inhalt. Regel: Symbol, ein Satz, genau eine Handlung.
public struct EmptyState: View {
    private let icon: String
    private let message: String
    private let actionTitle: String?
    private let action: (() -> Void)?

    public init(icon: String, message: String,
                actionTitle: String? = nil, action: (() -> Void)? = nil) {
        self.icon = icon
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }

    public var body: some View {
        VStack(spacing: BQSpacing.m) {
            Image(systemName: icon)
                .font(.system(size: 36, weight: .light))
                .foregroundStyle(BQColor.textTertiary)
            Text(message)
                .font(BQFont.body)
                .foregroundStyle(BQColor.textSecondary)
                .multilineTextAlignment(.center)
            if let actionTitle, let action {
                PrimaryButton(actionTitle, action: action).frame(maxWidth: 260)
            }
        }
        .padding(BQSpacing.l)
    }
}

public struct ErrorCard: View {
    private let message: String
    private let retry: () -> Void

    public init(message: String, retry: @escaping () -> Void) {
        self.message = message
        self.retry = retry
    }

    public var body: some View {
        Card {
            VStack(alignment: .leading, spacing: BQSpacing.s) {
                Text(message).font(BQFont.body)
                    .foregroundStyle(BQColor.textPrimary)
                Button("Try again", action: retry)
                    .font(BQFont.caption)
                    .foregroundStyle(BQColor.accent)
            }
        }
    }
}
