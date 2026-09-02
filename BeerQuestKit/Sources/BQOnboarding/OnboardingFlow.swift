import SwiftUI
import BQCore
import BQDesign

/// Der Weg in die App. Drei Schritte, nicht mehr.
///
/// Er bildet nach, was der Server kann (`complete_onboarding`): Alter,
/// Username, erste Quest. **Was der Server nicht kann, steht hier auch
/// nicht** - sonst verspricht das Onboarding etwas, das danach niemand
/// einloest.
///
/// Validiert am klickbaren Prototyp (`docs/prototype/index.html`). Wie
/// viele Pruefungen dort laufen, sagt der Lauf selbst - eine Zahl an
/// dieser Stelle waere beim naechsten Commit falsch.
public struct OnboardingFlow: View {

    public enum Step: Int, CaseIterable { case promise, age, name }

    /// Was am Ende an `complete_onboarding` geht.
    public struct Result: Equatable, Sendable {
        public let username: String
        public let birthYear: Int
        public init(username: String, birthYear: Int) {
            self.username = username
            self.birthYear = birthYear
        }
    }

    private let onFinish: (Result) -> Void

    @State private var step: Step = .promise
    @State private var birthYear: Int?
    @State private var typedName = ""

    public init(onFinish: @escaping (Result) -> Void) {
        self.onFinish = onFinish
    }

    public var body: some View {
        ZStack {
            ScreenBackground()
            VStack(spacing: 0) {
                content
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .padding(.horizontal, BQSpacing.m)
                footer
            }
        }
        .animation(BQMotion.standard, value: step)
    }

    @ViewBuilder
    private var content: some View {
        switch step {
        case .promise: PromiseStep()
        case .age:     AgeStep(birthYear: $birthYear)
        // Das Urteil ueber den Namen faellt an EINER Stelle und wird
        // hineingereicht. Als der Schritt es selbst berechnete, sagte er
        // bei leerem Feld "in Ordnung", waehrend der Knopf daneben aus
        // war - zwei Antworten auf dieselbe Frage.
        case .name:    NameStep(typed: $typedName,
                                suggestion: suggestion,
                                problem: nameProblem)
        }
    }

    // MARK: - Fuss

    private var footer: some View {
        VStack(spacing: BQSpacing.s + 2) {
            StepDots(current: step.rawValue, total: Step.allCases.count)
            primaryAction
        }
        .padding(BQSpacing.m)
    }

    @ViewBuilder
    private var primaryAction: some View {
        switch step {
        case .promise:
            PrimaryButton("Start your quest") { step = .age }

        case .age:
            PrimaryButton("Continue") { step = .name }
                .disabled(!ageIsAccepted)
                .opacity(ageIsAccepted ? 1 : 0.45)

        case .name:
            PrimaryButton("Enter the world") {
                guard let year = birthYear, nameProblem == nil else { return }
                onFinish(Result(username: suggestion, birthYear: year))
            }
            .disabled(nameProblem != nil)
            .opacity(nameProblem == nil ? 1 : 0.45)
        }
    }

    // MARK: - Regeln

    /// Die Entscheidung faellt in `BQCore`, nicht im View. Ein View, der
    /// selbst rechnet, laesst sich nicht ohne Simulator pruefen.
    private var ageIsAccepted: Bool {
        OnboardingRules.problem(withBirthYear: birthYear) == nil
    }

    private var suggestion: String {
        OnboardingRules.suggestedUsername(from: typedName)
    }

    private var nameProblem: OnboardingRules.UsernameProblem? {
        typedName.isEmpty ? .format : OnboardingRules.problem(withUsername: suggestion)
    }
}

// MARK: - Schritt 1: das Versprechen

private struct PromiseStep: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            StepHeader(label: "Beer Quest",
                       title: "Discover\nthe world.",
                       subtitle: "One beer at a time.")

            // Vier Zeilen, kein Fliesstext. Wer sie nicht in drei Sekunden
            // liest, liest sie nicht.
            Card {
                VStack(spacing: 0) {
                    Promise(icon: BQIcon.country, title: "Discover",
                            text: "Every new beer, place, city and country is a first.")
                    PromiseDivider()
                    Promise(icon: BQIcon.quests, title: "Collect",
                            text: "Your passport fills with stamps you actually earned.")
                    PromiseDivider()
                    Promise(icon: BQIcon.leaderboard, title: "Progress",
                            text: "Quests, levels and badges — for exploring, not for drinking more.")
                    PromiseDivider()
                    Promise(icon: BQIcon.clan, title: "Compete",
                            text: "Join a clan and explore a country together.")
                }
            }
            Spacer(minLength: 0)
        }
    }
}

private struct Promise: View {
    let icon: String
    let title: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: BQSpacing.s + 5) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(BQColor.accent)
                .frame(width: 34, height: 34)
                .background(Circle().stroke(BQColor.accentDeep.opacity(0.5), lineWidth: 1))
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(BQFont.headline).foregroundStyle(BQColor.textPrimary)
                Text(text).font(BQFont.caption).foregroundStyle(BQColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, BQSpacing.s + 5)
        .accessibilityElement(children: .combine)
    }
}

private struct PromiseDivider: View {
    var body: some View {
        Rectangle().fill(BQColor.separator).frame(height: 1)
    }
}

// MARK: - Schritt 2: das Alter

private struct AgeStep: View {
    @Binding var birthYear: Int?

    private var years: [Int] {
        Array(OnboardingRules.selectableBirthYears().reversed())
    }

    private var defaultYear: Int {
        OnboardingRules.defaultBirthYear()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            StepHeader(label: "Before we start",
                       title: "What year were\nyou born?",
                       subtitle: "Beer Quest is for adults. We ask for the year only, never the full date.")

            // Ein Rad statt eines Ja/Nein: Der Server verlangt ein
            // Geburtsjahr (`complete_onboarding`), kein Haekchen. Ein
            // Haekchen haette hier etwas gefragt, das danach niemand
            // verwendet - und die Absage waere erst nach dem letzten
            // Schritt gekommen.
            Picker("Year of birth", selection: Binding(
                get: { birthYear ?? years.first ?? 2000 },
                set: { birthYear = $0 }
            )) {
                ForEach(years, id: \.self) { year in
                    Text(String(year)).font(BQFont.number).tag(year)
                }
            }
            .pickerStyle(.wheel)
            .frame(maxWidth: .infinity)
            .padding(.top, BQSpacing.s)

            // Die Auswahl bietet nur an, was der Server annimmt. Trotzdem
            // steht hier, was passiert - eine Grenze, die man nur durch
            // Ausprobieren findet, ist keine.
            Text("You need to be \(OnboardingRules.minimumAge) or older.")
                .font(BQFont.caption)
                .foregroundStyle(BQColor.textTertiary)
                .padding(.top, BQSpacing.s)

            Spacer(minLength: 0)
        }
        // Vorauswahl in der Mitte des Erwartbaren, nicht am Rand: Wer
        // "genau 18" vorgesetzt bekommt, muss in fast jedem Fall scrollen.
        // Derselbe Wert wie im Prototyp - zwei Vorgaben waeren zwei
        // Produkte.
        .onAppear { if birthYear == nil { birthYear = defaultYear } }
    }
}

// MARK: - Schritt 3: der Name

private struct NameStep: View {
    @Binding var typed: String
    let suggestion: String
    let problem: OnboardingRules.UsernameProblem?
    @FocusState private var focused: Bool

    /// Solange nichts getippt ist, ist das Feld nicht falsch - es ist leer.
    /// Rot faerben, bevor jemand etwas getan hat, ist eine Ruege ohne Anlass.
    private var showsError: Bool { !typed.isEmpty && problem != nil }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            StepHeader(label: "Almost there",
                       title: "Pick your\nexplorer name.",
                       subtitle: "Your clan will see it. You can change it later.")

            TextField("", text: $typed, prompt: Text("steffen").foregroundStyle(BQColor.textTertiary))
                .font(BQFont.title)
                .foregroundStyle(BQColor.textPrimary)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .focused($focused)
                .padding(BQSpacing.m)
                .background(BQColor.surfaceRaised,
                            in: RoundedRectangle(cornerRadius: BQRadius.card, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: BQRadius.card, style: .continuous)
                        .stroke(showsError ? BQColor.accentDeep : BQColor.accent, lineWidth: 1)
                )
                .accessibilityLabel("Your explorer name")

            // Der Hinweis kommt beim Tippen, nicht nach "weiter". Wer erst
            // danach erfaehrt, dass ein Name nicht geht, tippt zweimal.
            Text(hint)
                .font(BQFont.caption)
                .foregroundStyle(showsError ? BQColor.accentDeep : BQColor.textTertiary)
                .padding(.top, BQSpacing.s)
                .frame(minHeight: 20, alignment: .leading)
                .accessibilityLabel(hint)

            Spacer(minLength: 0)
        }
        .onAppear { focused = true }
    }

    private var hint: String {
        guard !typed.isEmpty else { return " " }
        switch problem {
        case .format:     return "Three to twenty letters, digits or underscores."
        case .notAllowed: return "That name is taken by the house rules. Try another."
        case .taken:      return "Someone got there first."
        case nil:         return suggestion == typed ? "Looks good." : "You will be @\(suggestion)."
        }
    }
}

// MARK: - Gemeinsame Teile

private struct StepHeader: View {
    let label: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(label.uppercased())
                .font(BQFont.label)
                .kerning(1.2)
                .foregroundStyle(BQColor.textTertiary)
            Text(title)
                .font(BQFont.display)
                .foregroundStyle(BQColor.textPrimary)
                .padding(.top, BQSpacing.s)
            Text(subtitle)
                .font(BQFont.caption)
                .foregroundStyle(BQColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, BQSpacing.s)
        }
        .padding(.top, BQSpacing.xl)
        .padding(.bottom, BQSpacing.m)
        .accessibilityElement(children: .combine)
    }
}

/// Wie weit bin ich? Drei Punkte, der aktuelle laenger - dieselbe Sprache
/// wie im Prototyp.
private struct StepDots: View {
    let current: Int
    let total: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<total, id: \.self) { i in
                Capsule()
                    .fill(i == current ? BQColor.accent : BQColor.separator)
                    .frame(width: i == current ? 18 : 6, height: 6)
            }
        }
        .animation(BQMotion.standard, value: current)
        .accessibilityElement()
        .accessibilityLabel("Step \(current + 1) of \(total)")
    }
}

#Preview("Onboarding") {
    OnboardingFlow { result in
        print("username=\(result.username) year=\(result.birthYear)")
    }
}
