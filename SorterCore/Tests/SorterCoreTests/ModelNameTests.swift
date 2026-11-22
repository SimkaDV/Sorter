import Foundation
import Testing
@testable import SorterCore

@Suite("Сборка имён и round-trip")
struct ModelNameTests {
    @Test func buildSkipsEmptyParts() {
        #expect(ModelName(title: "Держатель досок", version: Version("v3")).build(ext: "stl") == "Держатель досок – v3.stl")
        #expect(ModelName(title: "Крышка правая", collection: "Кейсы", version: Version("v2")).build(kind: .stl) == "Крышка правая – Кейсы – v2.stl")
        #expect(ModelName(title: "Кейсы").build(kind: .f3d) == "Кейсы.f3d")
        #expect(ModelName(title: "Деталь", version: Version("v1")).build(kind: .gcode3MF) == "Деталь – v1.gcode.3mf")
        #expect(ModelName(title: "Без расширения").build() == "Без расширения")
    }

    @Test func buildUsesEnDashSeparator() {
        let name = ModelName(title: "A", params: "B", collection: "C", version: Version("2.0")).build()
        #expect(name == "A\u{0020}\u{2013}\u{0020}B – C – v2")
        #expect(name.components(separatedBy: Naming.separator).count == 4)
    }

    @Test func buildNormalizesParts() {
        let name = ModelName(title: "  Крышка   левая ", params: "впуклая\u{00A0}2мм")
        #expect(name.title == "Крышка левая")
        #expect(name.build() == "Крышка левая – впуклая 2мм")
    }

    static let roundTrip: [ModelName] = [
        ModelName(title: "Держатель досок", version: Version("v3")),
        ModelName(title: "Крышка левая", params: "впуклая 2мм", collection: "Кейсы", version: Version("v3")),
        ModelName(title: "Крышка правая", collection: "Кейсы", version: Version("v2")),
        ModelName(title: "Держатель для линзы", params: "17 1.5 left", version: Version("v2.1")),
        ModelName(title: "Короб 40", params: "10–11"),
        ModelName(title: "Лейбл Чае", params: "Рамка", collection: "Чай", version: Version("v10")),
        ModelName(title: "Кейсы"),
        ModelName(title: "GridfinityBox", params: "Honeygrid h4 2x2", collection: "Gridfinity", version: Version("v1")),
        ModelName(title: "Чаи\u{0306}ник", version: Version("v4.2")),  // «й» в NFD
    ]

    @Test(arguments: roundTrip)
    func buildThenParseGivesSameName(_ name: ModelName) {
        for kind in [FileKind.stl, .threeMF, .gcode3MF] {
            let parsed = NameParser.parse(fileName: name.build(kind: kind), collection: name.collection.isEmpty ? nil : name.collection)
            #expect(parsed.name == name)
            #expect(parsed.kind == kind)
            #expect(parsed.confidence == .high)
            #expect(parsed.markers.isEmpty)
        }
    }
}
