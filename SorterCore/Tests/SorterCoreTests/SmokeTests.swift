import Foundation
import Testing
@testable import SorterCore

@Suite("Каркас")
struct SmokeTests {
    @Test func version() {
        #expect(!SorterCore.version.isEmpty)
    }

    @Test func separatorIsEnDash() {
        #expect(Naming.separator == " \u{2013} ")
    }

    @Test func fixturesAreBundled() throws {
        let root = try #require(Bundle.module.url(forResource: "Fixtures", withExtension: nil))
        let model = root.appending(path: "Library/Мои модели/Для дома/Держатель досок/Держатель досок.txt")
        #expect(FileManager.default.fileExists(atPath: model.path))
    }
}
