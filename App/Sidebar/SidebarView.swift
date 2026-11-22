import SwiftUI

/// Плавающая боковая панель (SPEC.md §5.1). Пока только заглушки.
struct SidebarView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 8) {
                Label("Избранное", systemImage: "star")
                Label("Разобрать", systemImage: "tray")
            }

            section("Библиотека") {
                Label("Мои модели", systemImage: "folder.fill").foregroundStyle(Theme.category)
                Label("Скачанные", systemImage: "folder.fill").foregroundStyle(Theme.category)
            }

            section("Теги") {
                tag("В работе", Theme.statusInWork)
                tag("Тестируется", Theme.statusTesting)
                tag("Готово", Theme.statusReady)
                tag("Брак", Theme.statusRejected)
            }

            Spacer()
        }
        .font(.callout)
        .lineLimit(1)
        .padding(.horizontal, 10)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Theme.panel, in: Theme.shape)
        .shadow(color: .black.opacity(0.35), radius: 12, y: 4)
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.textSecondary)
            content()
        }
    }

    private func tag(_ title: String, _ color: Color) -> some View {
        HStack(spacing: 8) {
            Circle().fill(color).frame(width: 9, height: 9)
            Text(title)
        }
    }
}
