import SwiftUI

/// Основная область: стопка вкладок пути и сетка карточек (этап 4). Пока пусто.
struct BrowserView: View {
    var body: some View {
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
