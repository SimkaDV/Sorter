import SwiftUI
import SorterCore

@main
struct SorterApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
                .frame(minWidth: 900, minHeight: 600)
                .preferredColorScheme(.dark)
        }
        .windowStyle(.hiddenTitleBar)
    }
}

/// Главное окно: плавающая боковая панель слева, основная область справа.
struct RootView: View {
    var body: some View {
        HStack(alignment: .top, spacing: Theme.windowInset) {
            SidebarView()
                .frame(width: Theme.sidebarWidth)
            BrowserView()
        }
        .padding(.top, Theme.contentTop)
        .padding([.leading, .trailing, .bottom], Theme.windowInset)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.background)
        .foregroundStyle(Theme.textPrimary)
        .ignoresSafeArea()
    }
}
