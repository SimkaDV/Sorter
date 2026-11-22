import Foundation

/// Имя модели по правилу SPEC.md §3.3:
/// `<Название> – <Параметры> – <Коллекция> – <Версия>.<ext>`. Пустые части пропускаются.
public struct ModelName: Sendable, Hashable {
    public var title: String
    public var params: String
    public var collection: String
    public var version: Version?

    /// Все строки нормализуются сразу (`TextNormalizer`).
    public init(title: String, params: String = "", collection: String = "", version: Version? = nil) {
        self.title = TextNormalizer.normalize(title)
        self.params = TextNormalizer.normalize(params)
        self.collection = TextNormalizer.normalize(collection)
        self.version = version
    }

    /// Имя без расширения: `Крышка левая – впуклая 2мм – Кейсы – v3`.
    public var stem: String {
        [title, params, collection, version?.description ?? ""]
            .map(TextNormalizer.normalize)
            .filter { !$0.isEmpty }
            .joined(separator: Naming.separator)
    }

    /// Полное имя файла. `ext` — без точки, пустое — без расширения.
    public func build(ext: String = "") -> String {
        ext.isEmpty ? stem : stem + "." + ext
    }

    /// Полное имя файла для вида файла.
    public func build(kind: FileKind) -> String {
        build(ext: kind.fileExtension)
    }
}
