import Foundation

/// Разбор имён файлов: и новых (по правилу), и старых «грязных» (SPEC.md §3.3).
///
/// Что понимает:
/// - разделители ` – `, ` - `, ` — ` и тире, прижатое к слову с одной стороны (`Box –Gex`);
/// - версии `v2`, `V2`, `v2.1`, `2.0`, приклеенные `40v1`, `test_v8`, версию не в конце (`a4 v3 – full`);
/// - хвосты «копия», «test», «Тест», «final», «Эталон» и хвост слайсера `_PLA_3m54s`.
///
/// Чего не делает: не угадывает параметры внутри названия без разделителей
/// (`Держатель для линзы 17 1.5 left` целиком остаётся названием).
public enum NameParser {
    /// Разбор полного имени файла. `collection` — имя коллекции, в которой лежит файл, если известно:
    /// тогда `Крышка правая – Кейсы` понимается как название + коллекция, а не название + параметры.
    public static func parse(fileName: String, collection: String? = nil) -> ParsedName {
        let split = FileKind.split(fileName: TextNormalizer.normalize(fileName))
        var result = parse(stem: split.stem, collection: collection)
        result.ext = split.ext
        result.kind = split.kind
        return result
    }

    /// Разбор имени без расширения (или имени папки).
    public static func parse(stem: String, collection: String? = nil) -> ParsedName {
        let original = TextNormalizer.normalize(stem)
        var markers: [NameMarker] = []
        var text = original

        if let match = text.firstMatch(of: slicerSuffix) {
            text = String(text[..<match.range.lowerBound])
            markers.append(.slicerSettings)
        }

        var parts = splitParts(text)
        stripTails(&parts, markers: &markers)
        let version = extractVersion(&parts)
        if version != nil { stripTails(&parts, markers: &markers) }

        let name = assemble(parts, version: version, collection: collection)
        let confidence = rate(name, partCount: parts.count, markers: markers, original: original)
        return ParsedName(name: name, ext: "", kind: .other, markers: markers.reversed(), confidence: confidence)
    }

    /// Ключ группировки: название и параметры без версии, хвостов и коллекции,
    /// в нижнем регистре, `_` и `+` считаются пробелами.
    /// Один ключ для склейки STL + 3MF в сканере и для автогруппировки в «Разобрать».
    public static func groupingKey(fileName: String, collection: String? = nil) -> String {
        parse(fileName: fileName, collection: collection).groupingKey
    }

    static func groupingKey(for name: ModelName) -> String {
        let joined = [name.title, name.params].filter { !$0.isEmpty }.joined(separator: Naming.separator)
        return TextNormalizer.key(joined.replacingOccurrences(of: "_", with: " ").replacingOccurrences(of: "+", with: " "))
    }

    // MARK: - Шаги разбора

    /// `_PLA_3m54s`, `_PETG_1h24m.gcode` в конце имени.
    private nonisolated(unsafe) static let slicerSuffix =
        /(?i)_(?:PLA|PETG|ABS|TPU|ASA|PC|PA|HIPS)(?:_\S*)?$/

    /// Делит строку по разделителям. Дефис — разделитель только с пробелами с обеих сторон
    /// (`trash-bag` — одно слово), тире — если пробел хотя бы с одной стороны (`10–11` — диапазон).
    static func splitParts(_ text: String) -> [String] {
        let chars = Array(text)
        var parts: [String] = []
        var current = ""
        for i in chars.indices {
            let c = chars[i]
            let spaceBefore = i > 0 && chars[i - 1] == " "
            let spaceAfter = i + 1 < chars.count && chars[i + 1] == " "
            let isSeparator = switch c {
            case "-": spaceBefore && spaceAfter
            case "\u{2013}", "\u{2014}": spaceBefore || spaceAfter
            default: false
            }
            if isSeparator {
                parts.append(current)
                current = ""
            } else {
                current.append(c)
            }
        }
        parts.append(current)
        return parts.map(TextNormalizer.normalize).filter { !$0.isEmpty }
    }

    /// Отрезает хвосты-слова с конца: целую часть («– Эталон») или последнее слово («Лейбл Чае Тест»).
    /// Единственное слово названия не трогаем.
    private static func stripTails(_ parts: inout [String], markers: inout [NameMarker]) {
        while let last = parts.last {
            if parts.count > 1, let marker = NameMarker.words[TextNormalizer.key(last)] {
                parts.removeLast()
                markers.append(marker)
                continue
            }
            var tokens = words(last)
            if tokens.count > 1, let marker = NameMarker.words[TextNormalizer.key(tokens.last!)] {
                tokens.removeLast()
                parts[parts.count - 1] = tokens.joined(separator: " ")
                markers.append(marker)
                continue
            }
            break
        }
    }

    /// Ищет версию: отдельная часть, последнее слово, приклеенная к слову, последнее слово более ранней части.
    private static func extractVersion(_ parts: inout [String]) -> Version? {
        guard let last = parts.last else { return nil }

        if parts.count > 1, let v = prefixedVersion(last) ?? bareVersion(last) {
            parts.removeLast()
            return v
        }

        var tokens = words(last)
        if tokens.count > 1, let v = prefixedVersion(tokens.last!) ?? bareVersion(tokens.last!) {
            tokens.removeLast()
            parts[parts.count - 1] = tokens.joined(separator: " ")
            return v
        }

        if let (rest, v) = gluedVersion(tokens.last!) {
            tokens[tokens.count - 1] = rest
            parts[parts.count - 1] = tokens.joined(separator: " ")
            return v
        }

        for i in stride(from: parts.count - 2, through: 0, by: -1) {
            var earlier = words(parts[i])
            if earlier.count > 1, let v = prefixedVersion(earlier.last!) {
                earlier.removeLast()
                parts[i] = earlier.joined(separator: " ")
                return v
            }
        }
        return nil
    }

    /// Раскладывает части по полям имени.
    private static func assemble(_ parts: [String], version: Version?, collection: String?) -> ModelName {
        switch parts.count {
        case 0:
            return ModelName(title: "", version: version)
        case 1:
            return ModelName(title: parts[0], version: version)
        case 2:
            if let collection, TextNormalizer.key(collection) == TextNormalizer.key(parts[1]) {
                return ModelName(title: parts[0], collection: parts[1], version: version)
            }
            return ModelName(title: parts[0], params: parts[1], version: version)
        case 3:
            return ModelName(title: parts[0], params: parts[1], collection: parts[2], version: version)
        default:
            let middle = parts[1..<(parts.count - 1)].joined(separator: ", ")
            return ModelName(title: parts[0], params: middle, collection: parts[parts.count - 1], version: version)
        }
    }

    private static func rate(_ name: ModelName, partCount: Int, markers: [NameMarker], original: String) -> ParsedName.Confidence {
        let junk = name.title.isEmpty
            || name.title.contains("+") || name.title.contains("_")
            || Version(name.title) != nil
            || partCount > 3
        if junk { return .low }
        if markers.isEmpty, name.stem == original { return .high }
        return .medium
    }

    // MARK: - Версии

    /// `v2`, `V2.1` — с буквой.
    private static func prefixedVersion(_ token: String) -> Version? {
        guard let first = token.first, first == "v" || first == "V" else { return nil }
        return Version(token)
    }

    /// Голое `2.0`, `1.1`: две однозначные части. `67.5` и `16.5` — размеры, а не версии.
    private static func bareVersion(_ token: String) -> Version? {
        let chars = Array(token)
        guard chars.count == 3, chars[1] == ".", chars[0].isASCIIDigitCharacter, chars[2].isASCIIDigitCharacter else {
            return nil
        }
        return Version(token)
    }

    /// Версия, приклеенная к слову после цифры или `_`: `40v1` → (`40`, v1), `test_v8` → (`test`, v8).
    private static func gluedVersion(_ token: String) -> (String, Version)? {
        guard let vIndex = token.lastIndex(where: { $0 == "v" || $0 == "V" }), vIndex != token.startIndex else {
            return nil
        }
        let before = token[token.index(before: vIndex)]
        guard before.isASCIIDigitCharacter || before == "_",
              let version = Version(String(token[vIndex...])) else { return nil }
        var rest = String(token[..<vIndex])
        while rest.hasSuffix("_") { rest.removeLast() }
        return rest.isEmpty ? nil : (rest, version)
    }

    private static func words(_ part: String) -> [String] {
        part.split(separator: " ").map(String.init)
    }
}
