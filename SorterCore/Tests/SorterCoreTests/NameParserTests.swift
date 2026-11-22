import Foundation
import Testing
@testable import SorterCore

/// Ожидаемый разбор одного имени.
struct NameCase: Sendable, CustomTestStringConvertible {
    let file: String
    let title: String
    var params = ""
    var collection = ""
    var version: String? = nil
    var markers: [NameMarker] = []
    var confidence: ParsedName.Confidence = .medium
    var context: String? = nil

    var testDescription: String { file }
}

@Suite("Разбор имён")
struct NameParserTests {
    /// Реальные имена из ~/Sorter-testdata (плюс несколько имён по новому правилу).
    static let cases: [NameCase] = [
        // Держатель для линзы *
        NameCase(file: "Держатель для линзы v2.1.stl", title: "Держатель для линзы", version: "v2.1"),
        NameCase(file: "Держатель для линзы v6.1.stl", title: "Держатель для линзы", version: "v6.1"),
        NameCase(file: "Держатель для линзы v5.stl", title: "Держатель для линзы", version: "v5"),
        NameCase(file: "Держатель для Линзы v2.stl", title: "Держатель для Линзы", version: "v2"),
        NameCase(file: "Держатель для линзы 17 1.5 left v3.stl", title: "Держатель для линзы 17 1.5 left", version: "v3"),
        NameCase(file: "Держатель для линзы 17 1 right  v4.stl", title: "Держатель для линзы 17 1 right", version: "v4"),
        NameCase(file: "Держатель для линзы 16.5 v5.stl", title: "Держатель для линзы 16.5", version: "v5"),
        NameCase(file: "Держатель для линзы 17 1 left.stl", title: "Держатель для линзы 17 1 left", confidence: .high),
        NameCase(file: "Держатель для Линзы v2_PLA_3m54s.gcode.3mf", title: "Держатель для Линзы", version: "v2", markers: [.slicerSettings]),
        NameCase(file: "Держатель линзы камеры.3mf", title: "Держатель линзы камеры", confidence: .high),
        // Крышка левая / правая *
        NameCase(file: "Крышка левая.stl", title: "Крышка левая", confidence: .high),
        NameCase(file: "Крышка левая v10.stl", title: "Крышка левая", version: "v10"),
        NameCase(file: "Крышка левая v2.4.stl", title: "Крышка левая", version: "v2.4"),
        NameCase(file: "Крышка левая Портсигар v1.stl", title: "Крышка левая Портсигар", version: "v1"),
        NameCase(file: "Крышка левая дабл ручки.stl", title: "Крышка левая дабл ручки", confidence: .high),
        NameCase(file: "Крышка правая с Рамкой v9.stl", title: "Крышка правая с Рамкой", version: "v9"),
        NameCase(file: "Крышка правая Целая v2.1.stl", title: "Крышка правая Целая", version: "v2.1"),
        NameCase(file: "Крышка правая 1.stl", title: "Крышка правая 1", confidence: .high),
        // GridfinityBox – Honeygrid *
        NameCase(file: "GridfinityBox – Honeygrid h4 1x2.stl", title: "GridfinityBox", params: "Honeygrid h4 1x2", confidence: .high),
        NameCase(file: "GridfinityBox – Honeygrid h5.stl", title: "GridfinityBox", params: "Honeygrid h5", confidence: .high),
        NameCase(file: "GridfinityBox – Сorner1x1 32mm.3mf", title: "GridfinityBox", params: "Сorner1x1 32mm", confidence: .high),
        NameCase(file: "GridfinityBox - Тест.stl", title: "GridfinityBox", markers: [.test]),
        NameCase(file: "GridfinityBox - Тест Grid.stl", title: "GridfinityBox", params: "Тест Grid"),
        NameCase(file: "h8 GridfinityBox – Honeygrid h8 .3mf", title: "h8 GridfinityBox", params: "Honeygrid h8", confidence: .high),
        NameCase(file: "GridfinityBoxes .3mf", title: "GridfinityBoxes", confidence: .high),
        NameCase(file: "Gridfinity Paint Box –Gex h6 4x3.stl", title: "Gridfinity Paint Box", params: "Gex h6 4x3"),
        NameCase(file: "Gridfinity Box Generator – 2.0.f3d", title: "Gridfinity Box Generator", version: "v2"),
        NameCase(file: "Gridfinity Box Generator 1.1 TEST.f3d", title: "Gridfinity Box Generator", version: "v1.1", markers: [.test]),
        // Лейбл Чае *
        NameCase(file: "Лейбл Чае.stl", title: "Лейбл Чае", confidence: .high),
        NameCase(file: "Лейбл Чае V4.3mf", title: "Лейбл Чае", version: "v4"),
        NameCase(file: "Лейбл Чае v2.1.3mf", title: "Лейбл Чае", version: "v2.1"),
        NameCase(file: "Лейбл Чае Тест.3mf", title: "Лейбл Чае", markers: [.test]),
        NameCase(file: "Лейбл Чае Рамка.stl", title: "Лейбл Чае Рамка", confidence: .high),
        // Хвосты и разделители
        NameCase(file: "Пластинка разделитель v1 — копия.stl", title: "Пластинка разделитель", version: "v1", markers: [.copy]),
        NameCase(file: "Ручка для шкафа волна - Эталон.3mf", title: "Ручка для шкафа волна", markers: [.reference]),
        NameCase(file: "Крепление блок монитор – эталон.stl", title: "Крепление блок монитор", markers: [.reference]),
        NameCase(file: "Grid Alex 295 525 – Эталон.3mf", title: "Grid Alex 295 525", markers: [.reference]),
        NameCase(file: "Вставка целая test.stl", title: "Вставка целая", markers: [.test]),
        NameCase(file: "YACS Test.3mf", title: "YACS", markers: [.test]),
        NameCase(file: "Крышка левая v2 final.stl", title: "Крышка левая", version: "v2", markers: [.final]),
        NameCase(file: "Разделитель листов блок a4 v3 – full.stl", title: "Разделитель листов блок a4", params: "full", version: "v3"),
        NameCase(file: "PaperSeporator А5 - full v3.stl", title: "PaperSeporator А5", params: "full", version: "v3"),
        NameCase(file: "Стул - Урок 2.f3d", title: "Стул", params: "Урок 2"),
        NameCase(file: "Крепление к потолку – Звезда4.stl", title: "Крепление к потолку", params: "Звезда4", confidence: .high),
        // Версии в разных записях
        NameCase(file: "Ручка шкафа волна 2.0.stl", title: "Ручка шкафа волна", version: "v2"),
        NameCase(file: "Подставка 67.5 V2.stl", title: "Подставка 67.5", version: "v2"),
        NameCase(file: "Подставка 67.5.stl", title: "Подставка 67.5", confidence: .high),
        NameCase(file: "Рамка V2.1.stl", title: "Рамка", version: "v2.1"),
        NameCase(file: "круг 40v1.stl", title: "круг 40", version: "v1"),
        NameCase(file: "Короб 40 10–11.3mf", title: "Короб 40 10–11", confidence: .high),
        // Не понято: честно всё в названии
        NameCase(file: "v1.stl", title: "v1", confidence: .low),
        NameCase(file: "Hex+Keys+Holder.3mf", title: "Hex+Keys+Holder", confidence: .low),
        NameCase(file: "k3d_accuracy_test_v8.stl", title: "k3d_accuracy_test", version: "v8", confidence: .low),
        // Новое правило
        NameCase(file: "Держатель досок – v3.stl", title: "Держатель досок", version: "v3", confidence: .high),
        NameCase(file: "Крышка левая – впуклая 2мм – Кейсы – v3.stl", title: "Крышка левая", params: "впуклая 2мм", collection: "Кейсы", version: "v3", confidence: .high),
        NameCase(file: "Крышка правая – Кейсы – v2.stl", title: "Крышка правая", collection: "Кейсы", version: "v2", confidence: .high, context: "Кейсы"),
        NameCase(file: "Крышка правая – Кейсы – v2.stl", title: "Крышка правая", params: "Кейсы", version: "v2", confidence: .high),
    ]

    @Test(arguments: cases)
    func parsesRealName(_ c: NameCase) {
        let p = NameParser.parse(fileName: c.file, collection: c.context)
        #expect(p.name.title == c.title)
        #expect(p.name.params == c.params)
        #expect(p.name.collection == c.collection)
        #expect(p.name.version?.description == c.version)
        #expect(p.markers == c.markers)
        #expect(p.confidence == c.confidence)
    }

    @Test func tableIsLargeEnough() {
        #expect(Self.cases.count >= 40)
    }

    @Test func extensionAndKind() {
        let p = NameParser.parse(fileName: "Держатель для Линзы v2_PLA_3m54s.gcode.3mf")
        #expect(p.kind == .gcode3MF)
        #expect(p.ext == "gcode.3mf")
        #expect(NameParser.parse(fileName: "Лейбл Чае V4.STL").kind == .stl)
    }

    @Test func nfdAndNfcGiveSameResult() {
        let nfc = "Hölass_Final6.3mf".precomposedStringWithCanonicalMapping
        let nfd = "Hölass_Final6.3mf".decomposedStringWithCanonicalMapping
        #expect(nfc.unicodeScalars.count != nfd.unicodeScalars.count)
        #expect(NameParser.parse(fileName: nfd).name == NameParser.parse(fileName: nfc).name)
    }

    @Test func groupingKeyIgnoresVersionTailsAndCase() {
        let key = NameParser.groupingKey(fileName: "Держатель для линзы v2.1.stl")
        #expect(NameParser.groupingKey(fileName: "Держатель для Линзы v2_PLA_3m54s.gcode.3mf") == key)
        #expect(NameParser.groupingKey(fileName: "Держатель для линзы v6.1.stl") == key)
        #expect(NameParser.groupingKey(fileName: "Держатель для линзы – Кейсы – v7.3mf", collection: "Кейсы") == key)
        #expect(NameParser.groupingKey(fileName: "Лейбл Чае Тест.3mf") == NameParser.groupingKey(fileName: "Лейбл Чае V4.stl"))
        #expect(NameParser.groupingKey(fileName: "Держатель для линзы 17 v2.stl") != key)
    }

    @Test func groupingKeyTreatsPlusAndUnderscoreAsSpaces() {
        #expect(NameParser.groupingKey(fileName: "Hex+Keys+Holder.3mf") == NameParser.groupingKey(fileName: "Hex_Keys_Holder.stl"))
    }
}
