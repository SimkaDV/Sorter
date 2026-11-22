import Foundation

/// Тип узла дерева библиотеки (SPEC.md §3.2).
public enum NodeKind: String, Sendable, Hashable, CaseIterable {
    /// Фиксированный корень: «Мои модели», «Скачанные».
    case root
    /// Входящие: `_Разобрать/`.
    case inbox
    /// Тематическая папка без пометки в txt.
    case category
    /// Набор деталей с одним Fusion-файлом (`Тип: Коллекция`).
    case collection
    /// Подпапка внутри коллекции.
    case group
    /// Одиночная модель (`Тип: Модель`) — коллекция из одного элемента.
    case model
    /// Деталь коллекции: файлы одной модели и версии, без своей папки.
    case part
    /// Папка `Версии/` со старыми версиями, в дереве скрыта.
    case versionsFolder

    /// Имя папки со старыми версиями.
    public static let versionsFolderName = "Версии"
    /// Имя папки входящих.
    public static let inboxFolderName = "_Разобрать"
}
