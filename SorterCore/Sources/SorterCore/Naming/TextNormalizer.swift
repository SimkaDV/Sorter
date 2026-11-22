import Foundation

/// Единственное место нормализации строк (docs/ARCHITECTURE.md §7).
/// Сравнивать имена — только через `key(_:)`.
public enum TextNormalizer {
    /// NFC, любые пробельные символы (включая неразрывный пробел) → один пробел, обрезка по краям.
    public static func normalize(_ string: String) -> String {
        var result = ""
        var pendingSpace = false
        for character in string.precomposedStringWithCanonicalMapping {
            if character.isWhitespace {
                pendingSpace = !result.isEmpty
            } else {
                if pendingSpace { result.append(" ") }
                pendingSpace = false
                result.append(character)
            }
        }
        return result
    }

    /// Ключ для сравнения: нормализованная строка в нижнем регистре.
    /// `й` в двух формах Unicode и «Линзы» / «линзы» дают один ключ.
    public static func key(_ string: String) -> String {
        normalize(string).lowercased()
    }
}
