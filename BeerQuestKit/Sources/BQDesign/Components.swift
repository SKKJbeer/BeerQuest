import SwiftUI
import BQCore

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
                if isLoading { ProgressView().tint(BQColor.background) }
                Text(title).font(BQFont.headline)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, BQSpacing.m)
            .background(BQColor.accent)
            .foregroundStyle(BQColor.background)
            .clipShape(RoundedRectangle(cornerRadius: BQSpacing.corner))
        }
        .disabled(isLoading)
    }
}

public struct Card<Content: View>: View {
    private let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        content
            .padding(BQSpacing.m)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(BQColor.surface)
            .clipShape(RoundedRectangle(cornerRadius: BQSpacing.corner))
    }
}

/// Der Fortschrittsbalken aus Product Vision §11.
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
            HStack {
                Text("LEVEL \(level)").font(BQFont.headline)
                Spacer()
                Text("\(inLevel.formatted()) / \(needed.formatted()) XP")
                    .font(BQFont.caption)
                    .foregroundStyle(BQColor.textSecondary)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(BQColor.surfaceAlt)
                    Capsule().fill(BQColor.accent)
                        .frame(width: geo.size.width * fraction)
                }
            }
            .frame(height: 10)
        }
        .foregroundStyle(BQColor.textPrimary)
    }

    private var fraction: Double {
        needed > 0 ? min(1, Double(inLevel) / Double(needed)) : 0
    }
}

/// Empty States sind bei einer frisch installierten App der eigentliche
/// Onboarding-Inhalt. Regel: Icon, ein Satz, genau eine Handlungsaufforderung.
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
            Text(icon).font(.system(size: 44))
            Text(message)
                .font(BQFont.body)
                .foregroundStyle(BQColor.textSecondary)
                .multilineTextAlignment(.center)
            if let actionTitle, let action {
                PrimaryButton(actionTitle, action: action)
                    .frame(maxWidth: 260)
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
                Text(message)
                    .font(BQFont.body)
                    .foregroundStyle(BQColor.textPrimary)
                Button("Try again", action: retry)
                    .font(BQFont.caption)
                    .foregroundStyle(BQColor.accent)
            }
        }
    }
}

/// Avatare kommen aus dem App-Bundle, nicht aus einem Upload.
/// Das spart Storage, Egress und Bildmoderation - siehe
/// `docs/04-cost-analysis.md` §1.
public struct AvatarView: View {
    private let key: String
    private let color: String
    private let size: CGFloat

    public init(key: String, color: String, size: CGFloat = 44) {
        self.key = key
        self.color = color
        self.size = size
    }

    public var body: some View {
        Circle()
            .fill(Self.palette[color] ?? BQColor.accent)
            .frame(width: size, height: size)
            .overlay(
                Text(Self.glyphs[key] ?? "\u{1F37A}")
                    .font(.system(size: size * 0.5))
            )
    }

    // Platzhalter bis zum Illustrations-Set (P0.11). Bewusst Bundle-Assets
    // statt Uploads - siehe docs/04-cost-analysis.md §1.
    static let glyphs: [String: String] = [
        "mug_01": "\u{1F37A}", "mug_02": "\u{1F37B}", "mug_03": "\u{1F942}",
        "mug_04": "\u{1F30D}", "mug_05": "\u{1F5FA}", "mug_06": "\u{2B50}",
    ]

    static let palette: [String: Color] = [
        "amber": BQColor.accent,
        "copper": BQColor.accentDeep,
        "forest": Color(red: 0.24, green: 0.50, blue: 0.35),
        "slate": Color(red: 0.35, green: 0.40, blue: 0.48),
        "plum": Color(red: 0.49, green: 0.30, blue: 0.50),
        "clay": Color(red: 0.72, green: 0.42, blue: 0.33),
    ]
}
