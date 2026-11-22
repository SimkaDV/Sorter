import SwiftUI

/// Основная область: поиск сверху, под ним стопка папок пути и сетка карточек (этап 4). Пока заглушка.
struct BrowserView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SearchFieldPlaceholder()
            VStack(spacing: 8) {
                Image(systemName: "cube.transparent")
                    .font(.system(size: 44, weight: .light))
                    .foregroundStyle(Theme.collection)
                Text("3D Models Sorter")
                    .font(.title2.weight(.semibold))
                Text("Библиотека появится на этапе 4")
                    .foregroundStyle(Theme.textSecondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

/// Капсула поиска моделей. Пока без логики.
private struct SearchFieldPlaceholder: View {
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 10, weight: .medium))
            Text("Поиск моделей")
                .font(.system(size: 11))
        }
        .foregroundStyle(Theme.textSecondary)
        .padding(.horizontal, 8)
        .frame(width: 150, height: 20, alignment: .leading)
        .background(Theme.field, in: Theme.fieldShape)
    }
}
