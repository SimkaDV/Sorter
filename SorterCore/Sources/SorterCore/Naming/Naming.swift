import Foundation

/// Правило имён (SPEC.md §3.3). Сборка — `ModelName`, разбор — `NameParser`, чистка строк — `TextNormalizer`.
public enum Naming {
    /// Разделитель частей имени: среднее тире U+2013 с пробелами.
    public static let separator = " \u{2013} "
}
