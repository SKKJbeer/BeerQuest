import SwiftUI
import BQCore
import BQDesign
import BQSession
import BQCheckIn
import BQWorld
import BQPlay

/// Die Navigationsstruktur aus docs/05-architecture.md §9.
/// Fuenf Tabs; der Add-Button ist bewusst kein Tab, sondern oeffnet ein Sheet -
/// er hat keinen Zustand, den man verlassen moechte.
struct RootView: View {
    @Environment(SessionStore.self) private var session
    @State private var selectedTab: BQTab = .home
    @State private var isAddingCheckIn = false

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                BQPlayPlaceholder(title: "Home")
                    .tabItem { Label("Home", systemImage: BQIcon.home) }
                    .tag(BQTab.home)

                BQWorldPlaceholder(title: "Map")
                    .tabItem { Label("Map", systemImage: BQIcon.map) }
                    .tag(BQTab.map)

                BQPlayPlaceholder(title: "Quests")
                    .tabItem { Label("Quests", systemImage: BQIcon.quests) }
                    .tag(BQTab.quests)

                BQPlayPlaceholder(title: "Clan")
                    .tabItem { Label("Clan", systemImage: BQIcon.clan) }
                    .tag(BQTab.clan)

                BQPlayPlaceholder(title: "Profile")
                    .tabItem { Label("Profile", systemImage: BQIcon.profile) }
                    .tag(BQTab.profile)
            }

            addButton
                .padding(.bottom, 52)
        }
        .sheet(isPresented: $isAddingCheckIn) {
            BQCheckInPlaceholder(title: "Add beer")
        }
    }

    private var addButton: some View {
        Button {
            isAddingCheckIn = true
        } label: {
            Label("ADD BEER", systemImage: BQIcon.addCheckIn)
                .font(BQFont.headline)
                .padding(.horizontal, BQSpacing.l)
                .padding(.vertical, BQSpacing.s + 2)
                .background(BQColor.accent, in: Capsule())
                .foregroundStyle(BQColor.onAccent)
                .shadow(radius: 8, y: 4)
        }
        .accessibilityLabel("Add a beer check-in")
    }
}
