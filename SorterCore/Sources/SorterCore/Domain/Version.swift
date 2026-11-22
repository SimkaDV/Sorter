import Foundation

/// Номер версии: `v1`, `v2.1`, `v10` (SPEC.md §3.3).
/// Хвостовые нули отбрасываются: `2.0` == `v2`. Сравнение покомпонентное: `v2.1 < v10`.
public struct Version: Sendable, Hashable, Comparable, CustomStringConvertible {
    /// Компоненты-числа, минимум один, без хвостовых нулей (кроме единственного).
    public let components: [Int]

    public init?(components: [Int]) {
        guard !components.isEmpty, components.allSatisfy({ $0 >= 0 }) else { return nil }
        var trimmed = components
        while trimmed.count > 1, trimmed.last == 0 { trimmed.removeLast() }
        self.components = trimmed
    }

    /// Разбор строки: `v2`, `V2`, `2.0`, `v2.1`, `2`. Пробелы и мусор — `nil`.
    /// Решение, считать ли голое число версией в имени файла, принимает `NameParser`.
    public init?(_ string: String) {
        var body = Substring(string)
        if let first = body.first, first == "v" || first == "V" { body = body.dropFirst() }
        let pieces = body.split(separator: ".", omittingEmptySubsequences: false)
        guard !pieces.isEmpty else { return nil }
        var numbers: [Int] = []
        for piece in pieces {
            guard !piece.isEmpty, piece.allSatisfy(\.isASCIIDigitCharacter), let n = Int(piece) else {
                return nil
            }
            numbers.append(n)
        }
        self.init(components: numbers)
    }

    /// Каноническая запись: `v2.1`.
    public var description: String {
        "v" + components.map(String.init).joined(separator: ".")
    }

    /// Следующая основная версия: `v3` → `v4`, `v2.1` → `v3`.
    public func next() -> Version {
        Version(components: [components[0] + 1])!
    }

    /// Следующая промежуточная: `v3` → `v3.1`, `v3.1` → `v3.2`.
    public func nextMinor() -> Version {
        if components.count == 1 { return Version(components: components + [1])! }
        var c = components
        c[c.count - 1] += 1
        return Version(components: c)!
    }

    public static func < (lhs: Version, rhs: Version) -> Bool {
        let count = max(lhs.components.count, rhs.components.count)
        for i in 0..<count {
            let l = i < lhs.components.count ? lhs.components[i] : 0
            let r = i < rhs.components.count ? rhs.components[i] : 0
            if l != r { return l < r }
        }
        return false
    }
}

extension Character {
    /// Только ASCII-цифры 0–9 (`isNumber` пропускает ещё и «²», «٣» и прочее).
    var isASCIIDigitCharacter: Bool { isASCII && isNumber }
}
