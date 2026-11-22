import Foundation

/// Результат разбора имени файла.
public struct ParsedName: Sendable, Hashable {
    /// Насколько парсер уверен в разборе.
    public enum Confidence: Int, Sendable, Hashable, Comparable {
        /// Ничего не понятно (мусорные символы, голая версия, слишком много частей). Всё лежит в `title`.
        case low
        /// Старое имя, но версия, хвосты или части распознаны.
        case medium
        /// Имя уже по правилу: `build` вернёт ту же строку.
        case high

        public static func < (lhs: Confidence, rhs: Confidence) -> Bool { lhs.rawValue < rhs.rawValue }
    }

    public var name: ModelName
    /// Расширение как в исходном имени, без точки.
    public var ext: String
    public var kind: FileKind
    /// Узнанные и отрезанные хвосты, в порядке появления в имени.
    public var markers: [NameMarker]
    public var confidence: Confidence

    /// Ключ «название без версии и хвостов» — см. `NameParser.groupingKey`.
    public var groupingKey: String { NameParser.groupingKey(for: name) }
}
