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
        HStack(spacing: 0) {
            SidebarView()
                .frame(width: 240)
                .padding(10)
            BrowserView()
        }
        .background(Theme.background)
        .foregroundStyle(Theme.textPrimary)
    }
}
