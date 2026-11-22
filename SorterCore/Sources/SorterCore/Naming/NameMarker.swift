import Foundation

/// Хвост старого имени, который парсер узнал и отрезал от названия.
public enum NameMarker: String, Sendable, Hashable, CaseIterable {
    /// «копия», «copy».
    case copy
    /// «test», «Тест».
    case test
    /// «final».
    case final
    /// «Эталон» — подсказка для статуса «Готово» (сам статус не ставим).
    case reference
    /// Хвост слайсера: `_PLA_3m54s`.
    case slicerSettings

    /// Слова-хвосты в виде ключей `TextNormalizer.key`.
    static let words: [String: NameMarker] = [
        "копия": .copy, "copy": .copy,
        "test": .test, "тест": .test,
        "final": .final,
        "эталон": .reference,
    ]
}
