import SwiftUI

/// Палитра «Мастерская» (SPEC.md §5). Единственное место, где задаются цвета.
/// Во View цвета берём только отсюда: `Theme.background`, `Theme.status(.ready)` и т. д.
enum Theme {
    // MARK: Поверхности и текст
    static let background = Color(hex: 0x1C1D1F)
    static let panel = Color(hex: 0x2B2D31)
    /// Поля ввода на фоне окна (поиск).
    static let field = Color(hex: 0x26272B)
    static let textPrimary = Color(hex: 0xECE9E4)
    static let textSecondary = Color(hex: 0x8B8E92)

    // MARK: Типы папок
    static let collection = Color(hex: 0xE8743B)
    static let group = Color(hex: 0xF0A272)
    static let category = Color(hex: 0x5B8DB8)
    static let model = Color(hex: 0xD9CDB6)

    // MARK: Статусы
    static let statusInWork = Color(hex: 0x5B8DB8)
    static let statusTesting = Color(hex: 0xF5C451)
    static let statusReady = Color(hex: 0x3DDC97)
    static let statusRejected = Color(hex: 0xE5534B)

    // MARK: Геометрия
    static let cornerRadius: CGFloat = 14
    static let cardSize: CGFloat = 124
    static let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
    static let fieldShape = RoundedRectangle(cornerRadius: 10, style: .continuous)

    // MARK: Раскладка окна (design/window-mockup.html)
    /// Отступ контента от краёв окна и между панелью и основной областью.
    static let windowInset: CGFloat = 8
    /// Верх контента: сразу под кнопками окна.
    static let contentTop: CGFloat = 32
    static let sidebarWidth: CGFloat = 120
}

extension Color {
    /// Цвет из 0xRRGGBB.
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}
