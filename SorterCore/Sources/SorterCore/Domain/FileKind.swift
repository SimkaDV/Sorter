import Foundation

/// Вид файла. Определяется только здесь, включая двойное расширение `.gcode.3mf`.
public enum FileKind: String, Sendable, Hashable, CaseIterable {
    case stl
    case threeMF
    case gcode3MF
    case f3d
    case blend
    case blendBackup
    case txt
    case other

    /// Расширение в нижнем регистре без точки. У `other` — пустое.
    public var fileExtension: String {
        switch self {
        case .stl: "stl"
        case .threeMF: "3mf"
        case .gcode3MF: "gcode.3mf"
        case .f3d: "f3d"
        case .blend: "blend"
        case .blendBackup: "blend1"
        case .txt: "txt"
        case .other: ""
        }
    }

    /// Файл с геометрией для печати (то, из чего складывается деталь).
    public var isPrintable: Bool { self == .stl || self == .threeMF }

    public init(url: URL) {
        self = FileKind.split(fileName: url.lastPathComponent).kind
    }

    public init(fileName: String) {
        self = FileKind.split(fileName: fileName).kind
    }

    /// Делит имя файла на основу и расширение. Расширение возвращается как в исходном имени.
    /// `Деталь – v2.gcode.3mf` → (`Деталь – v2`, `gcode.3mf`, .gcode3MF).
    /// У файла без расширения или с неизвестным — `other`, расширение отрезается последнее (если есть).
    public static func split(fileName: String) -> (stem: String, ext: String, kind: FileKind) {
        let lower = fileName.lowercased()
        // Сначала длинные расширения, чтобы `.gcode.3mf` не стал просто `.3mf`.
        let known: [FileKind] = [.gcode3MF, .threeMF, .stl, .f3d, .blendBackup, .blend, .txt]
        for kind in known {
            let suffix = "." + kind.fileExtension
            if lower.hasSuffix(suffix), lower.count > suffix.count {
                let cut = fileName.index(fileName.endIndex, offsetBy: -suffix.count)
                return (String(fileName[..<cut]), String(fileName[fileName.index(after: cut)...]), kind)
            }
        }
        if let dot = fileName.lastIndex(of: "."), dot != fileName.startIndex {
            return (String(fileName[..<dot]), String(fileName[fileName.index(after: dot)...]), .other)
        }
        return (fileName, "", .other)
    }
}
