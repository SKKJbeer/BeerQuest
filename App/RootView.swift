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
    @State private var selectedTab: Tab = .home
    @State private var isAddingCheckIn = false

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                BQPlayPlaceholder(title: "Home")
                    .tabItem { Label("Home", systemImage: "house.fill") }
                    .tag(Tab.home)

                BQWorldPlaceholder(title: "Map")
                    .tabItem { Label("Map", systemImage: "map.fill") }
                    .tag(Tab.map)

                BQPlayPlaceholder(title: "Quests")
                    .tabItem { Label("Quests", systemImage: "target") }
                    .tag(Tab.quests)

                BQPlayPlaceholder(title: "Clan")
                    .tabItem { Label("Clan", systemImage: "person.3.fill") }
                    .tag(Tab.clan)

                BQPlayPlaceholder(title: "Profile")
                    .tabItem { Label("Profile", systemImage: "person.crop.circle.fill") }
                    .tag(Tab.profile)
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
            Label("ADD BEER", systemImage: "plus")
                .font(BQFont.headline)
                .padding(.horizontal, BQSpacing.l)
                .padding(.vertical, BQSpacing.s + 2)
                .background(BQColor.accent, in: Capsule())
                .foregroundStyle(BQColor.background)
                .shadow(radius: 8, y: 4)
        }
        .accessibilityLabel("Add a beer check-in")
    }
}
