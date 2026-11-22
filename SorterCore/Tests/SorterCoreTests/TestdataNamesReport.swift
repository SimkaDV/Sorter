import Foundation
import Testing
@testable import SorterCore

/// Прогон парсера по всем именам тестовой копии `~/Sorter-testdata` — только чтение.
/// Печатает сводку и список имён, которые парсер не понял. Без тестовой копии тест пропускается.
@Suite("Сводка по ~/Sorter-testdata")
struct TestdataNamesReport {
    static let root = FileManager.default.homeDirectoryForCurrentUser.appending(path: "Sorter-testdata")

    @Test(.enabled(if: FileManager.default.fileExists(atPath: root.path)))
    func report() throws {
        let enumerator = try #require(FileManager.default.enumerator(at: Self.root, includingPropertiesForKeys: [.isRegularFileKey]))
        var names = Set<String>()
        for case let url as URL in enumerator where url.lastPathComponent != ".DS_Store" {
            if (try? url.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile) == true {
                names.insert(TextNormalizer.normalize(url.lastPathComponent))
            }
        }
        let parsed = names.sorted().map { ($0, NameParser.parse(fileName: $0)) }
        let count = { (c: ParsedName.Confidence) in parsed.filter { $0.1.confidence == c }.count }
        print("Имён: \(parsed.count). По правилу: \(count(.high)), разобрано: \(count(.medium)), не понято: \(count(.low)).")

        let verbose = ProcessInfo.processInfo.environment["SORTER_NAMES_VERBOSE"] != nil
        for (fileName, p) in parsed where verbose || p.confidence == .low {
            let n = p.name
            print("[\(p.confidence)] \(fileName)  →  «\(n.title)» | «\(n.params)» | «\(n.collection)» | \(n.version?.description ?? "-") \(p.markers.map(\.rawValue)) [\(p.kind.rawValue)]")
        }
        #expect(parsed.count > 0)
    }
}
