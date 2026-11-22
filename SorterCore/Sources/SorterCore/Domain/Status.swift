import Foundation

/// Статус модели или детали (SPEC.md §3.5). Ровно один на узел.
/// Цвет статуса знает только UI (`Theme`), здесь его нет.
public enum Status: String, Sendable, Hashable, CaseIterable {
    case inWork
    case testing
    case ready
    case rejected

    /// Подпись для человека и строка `Статус:` в txt.
    public var title: String {
        switch self {
        case .inWork: "В работе"
        case .testing: "Тестируется"
        case .ready: "Готово"
        case .rejected: "Брак"
        }
    }

    /// Имя тега Finder. Совпадает с подписью; соответствие старым тегам — в `TagMapping` (этап 2).
    public var tagName: String { title }
}
