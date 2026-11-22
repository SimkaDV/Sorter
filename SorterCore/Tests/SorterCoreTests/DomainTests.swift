import Foundation
import Testing
@testable import SorterCore

@Suite("Domain")
struct DomainTests {
    @Test func versionParsing() {
        #expect(Version("v2")?.components == [2])
        #expect(Version("V2")?.components == [2])
        #expect(Version("2.0")?.description == "v2")
        #expect(Version("v2.1.0")?.description == "v2.1")
        #expect(Version("v10")?.description == "v10")
        #expect(Version("v") == nil)
        #expect(Version("v2.") == nil)
        #expect(Version("v2a") == nil)
        #expect(Version("v²") == nil)
        #expect(Version(" v2") == nil)
    }

    @Test func versionOrdering() throws {
        let sorted = ["v10", "v2.1", "v1", "v2", "v2.10", "v2.2", "v9"].compactMap(Version.init).sorted()
        #expect(sorted.map(\.description) == ["v1", "v2", "v2.1", "v2.2", "v2.10", "v9", "v10"])
        #expect(Version("2.0") == Version("v2"))
    }

    @Test func versionIncrements() throws {
        let v3 = try #require(Version("v3"))
        #expect(v3.next().description == "v4")
        #expect(v3.nextMinor().description == "v3.1")
        #expect(try #require(Version("v3.1")).nextMinor().description == "v3.2")
        #expect(try #require(Version("v2.1")).next().description == "v3")
    }

    @Test func fileKindDetection() {
        #expect(FileKind(fileName: "Кейсы.f3d") == .f3d)
        #expect(FileKind(fileName: "a.STL") == .stl)
        #expect(FileKind(fileName: "a.3mf") == .threeMF)
        #expect(FileKind(fileName: "a.gcode.3mf") == .gcode3MF)
        #expect(FileKind(fileName: "Test 5X_PLA_1h24m.gcode.gcode.3mf") == .gcode3MF)
        #expect(FileKind(fileName: "Fox.blend") == .blend)
        #expect(FileKind(fileName: "Fox.blend1") == .blendBackup)
        #expect(FileKind(fileName: "Кейсы.txt") == .txt)
        #expect(FileKind(fileName: "Demo.mp4") == .other)
        #expect(FileKind(fileName: ".3mf") == .other)
        #expect(FileKind(url: URL(filePath: "/tmp/Кейсы/Крышка – v2.stl")) == .stl)
    }

    @Test func fileKindSplitKeepsOriginalCase() {
        let s = FileKind.split(fileName: "Лейбл Чае V4.STL")
        #expect(s.stem == "Лейбл Чае V4")
        #expect(s.ext == "STL")
        #expect(FileKind.split(fileName: "README").ext == "")
        #expect(FileKind.split(fileName: "photo.webp") == ("photo", "webp", .other))
    }

    @Test func statusTitles() {
        #expect(Status.allCases.map(\.title) == ["В работе", "Тестируется", "Готово", "Брак"])
        #expect(Status.ready.tagName == "Готово")
    }

    @Test func normalizer() {
        #expect(TextNormalizer.normalize("  Домашние   проекты \u{00A0}") == "Домашние проекты")
        let nfd = "Чаи\u{0306}ник"
        #expect(TextNormalizer.normalize(nfd) == "Чайник")
        #expect(TextNormalizer.normalize(nfd).unicodeScalars.count == 6)
        #expect(TextNormalizer.key("Держатель для Линзы") == TextNormalizer.key("держатель  для линзы "))
    }
}
