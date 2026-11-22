# Архитектура 3D Models Sorter

> Карта кода: какие есть компоненты, за что каждый отвечает, как они связаны и куда класть новый код.
> Что строим, описано в [SPEC.md](../SPEC.md), порядок работ — в [ROADMAP.md](../ROADMAP.md), правила для Claude — в [CLAUDE.md](../CLAUDE.md).
> Принято 22.11.2026. Имена типов — план. Если в ходе этапа что-то меняется, документ обновляется в том же коммите.

---

## 1. Принципы

1. **Диск — единственный источник правды.** Структура папок, txt и теги Finder — это и есть данные. Индекс и кэш превью можно удалить в любой момент: они пересобираются из диска.
2. **Чтение отдельно от записи.** Сканер только читает. Всё, что меняет диск, проходит один путь: намерение → план → предпросмотр → выполнение → журнал (§5.3). Других способов записи нет.
3. **Ядро чистое.** `SorterCore` не знает про SwiftUI и AppKit. Его можно целиком гонять тестами из терминала.
4. **Одно правило — одно место.** Нормализация строк, сборка и разбор имён, цвета, определение типа папки, разрешение конфликтов имён: у каждого правила один владелец (§7). Повтор логики в двух местах считается багом.
5. **Значения вместо общих изменяемых объектов.** Снимок библиотеки, план, txt-документ — неизменяемые `Sendable`-структуры. Изменение = новая копия.
6. **Зависимости через протоколы только там, где их нужно подменять в тестах:** файловая система, теги, часы. Остальное — конкретные типы, без абстракций «на будущее».

---

## 2. Слои

```
┌─────────────────────────────── App (SwiftUI, @MainActor) ───────────────────────────────┐
│  Views (Sidebar, Browser, Collection, Model, Inbox, Plan, Journal)                      │
│        │ читают состояние, шлют намерения                                               │
│  Stores (@Observable): LibraryStore · NavigationModel · PlanStore · PreviewLoader       │
│  Services (AppKit): ExternalApps (слайсер, Fusion, Finder) · SettingsStore              │
└────────────────────────────────────────┬────────────────────────────────────────────────┘
                                         │ только публичный API
┌────────────────────────────────────────▼──── SorterCore (чистый Swift) ─────────────────┐
│  Scanner ──► Notes · Tags · Naming ──► Domain                                           │
│  FileOps ──► Naming · Notes · Tags ──► Domain                                           │
│  Previews ─► Domain                                                                     │
│  Support: FileSystem · TagStore · Clock (протоколы + живые реализации)                   │
└────────────────────────────────────────┬────────────────────────────────────────────────┘
                                         ▼
                              диск (папки, txt, теги Finder)
```

### Кто кого может импортировать (внутри SorterCore)

| Модуль | Может использовать | Не может |
|---|---|---|
| `Domain` | только Foundation | всё остальное |
| `Naming` | Domain | Notes, Tags, Scanner, FileOps |
| `Notes` | Domain, Naming | Scanner, FileOps |
| `Tags` | Domain, Support | Scanner, FileOps |
| `Scanner` | Domain, Naming, Notes, Tags, Support | FileOps, Previews |
| `FileOps` | Domain, Naming, Notes, Tags, Support | Scanner (получает снимок готовым), Previews |
| `Previews` | Domain, Support | Scanner, FileOps |
| `Support` | Foundation | всё остальное |

Это один Swift-модуль `SorterCore`, поэтому компилятор границы не проверяет. Держим их ревью: при нарушении — переносим код. Если со временем будет нужна жёсткая проверка, каждую папку можно сделать отдельным таргетом пакета без изменения API.

---

## 3. SorterCore по модулям

### 3.1 Domain — словарь проекта

Только типы и чистые функции над ними. Без доступа к диску.

| Тип | Что это |
|---|---|
| `NodeID` | Путь узла относительно корня библиотеки, нормализованный в NFC. Стабильный ключ для навигации, кэша и журнала. |
| `NodeKind` | `root`, `inbox`, `category`, `collection`, `group`, `model`, `part`, `versionsFolder`. |
| `Node` | Узел дерева: `id`, `kind`, `name`, `url`, даты, размер, `status`, `isFavorite`, `children: [NodeID]`, `files` (актуальная версия), `oldVersions`. |
| `Part` | Деталь коллекции: `ModelName` + файлы одной версии (STL / 3MF) + ссылка на F3D коллекции. |
| `ModelFile` | Файл: `url`, `FileKind`, `ModelName?`, размер, даты. |
| `FileKind` | `stl`, `threeMF`, `gcode3MF`, `f3d`, `blend`, `blendBackup`, `txt`, `other`. Определяется только здесь (`FileKind(url:)`), включая двойное расширение `.gcode.3mf`. |
| `Status` | `inWork`, `testing`, `ready`, `rejected`. Знает свою подпись («В работе»…) и имя тега Finder. Цвет не знает: это UI (§4.3). |
| `Version` | `v1`, `v2.1`, `v10`: компоненты-числа, `Comparable`, `next()`, `nextMinor()`. |
| `Completeness` | Признаки заполненности (SPEC §3.7) и `missing: [Item]` для подсказки. |
| `SortKey` / `SortOrder` | Имя, дата добавления, дата изменения, размер, тип; по возрастанию или убыванию. |
| `LibrarySnapshot` | Неизменяемый снимок: `root`, словарь `[NodeID: Node]`, счётчики (inbox, статусы). Всё, что видит UI, берётся отсюда. |
| `SorterError` | Общие ошибки ядра (нет доступа, конфликт, файл исчез…). Тексты для человека пишет App. |

### 3.2 Naming — имена файлов (SPEC §3.3)

- `TextNormalizer` — **единственное место** нормализации: обрезка пробелов, двойные пробелы, NFC. Используют все: сканер, парсер имён, txt, FileOps. Сравнение имён — только через `normalized` ключи.
- `ModelName { title, params, collection, version }` — значение. `build(ext:)` собирает имя. Разделитель — `Naming.separator`.
- `NameParser.parse(_:)` — разбор новых и старых «грязных» имён. Возвращает `ParsedName` с полем `confidence`. Нераспознанное — честно: всё в `title`, версии нет.
- `NameParser.groupingKey(_:)` — ключ «название без версии и хвостов». Его используют и сканер (склейка STL + 3MF в деталь), и экран «Разобрать» (автогруппировка). Один ключ — одинаковое поведение в обоих местах.

### 3.3 Notes — txt-файл (SPEC §3.6)

- `NotesDocument` — модель **без потерь**: список строк с разметкой (шапка, раздел детали, запись журнала, неизвестная строка). `render()` возвращает исходный текст байт в байт, если документ не меняли.
- `NotesParser.parse(String) -> NotesDocument`.
- Правки — чистые функции, возвращают новый документ: `setHeader(_:_:)`, `setStatus(_:part:)`, `prependEntry(_:part:)`, `ensureSection(_:)`. Неизвестные строки не трогаются.
- `NotesDocument.kind` (`Тип: Коллекция / Модель`) — сканер берёт тип папки отсюда.
- Диск модуль не трогает. Чтение — у сканера, запись — у FileOps (операция `writeFile`), обе через `FileSystem`.

### 3.4 Tags — теги Finder (SPEC §3.5)

- `TagStore` (протокол): `tags(at:)`, `setTags(_:at:)`. Живая реализация — `URLResourceValues.tagNames`. В тестах — `InMemoryTagStore`.
- `TagMapping` — **единственное место** соответствия «статус ↔ имя тега» и «Избранное», включая старое «Эталон» → `ready` (чистая функция, без автоприменения).
- Статус узла = txt, если там есть строка `Статус`, иначе тег. Если они расходятся, сканер помечает это в `Node.statusConflict`, UI может показать предупреждение. Правило в одном месте: `StatusResolver`.

### 3.5 Scanner — чтение библиотеки (SPEC §3.2)

```
LibraryScanner (actor)
  scan(root) async throws -> LibrarySnapshot
  rescan(subtree: NodeID, in: LibrarySnapshot) async throws -> LibrarySnapshot
     │
     ├─ DirectoryWalker      обходит папки через FileSystem, пропускает скрытые
     ├─ FolderClassifier     тип папки: имя (_Разобрать, Версии) + шапка txt + родитель
     ├─ PartGrouper          склеивает файлы детали по NameParser.groupingKey + версии
     ├─ VersionResolver      актуальная версия в папке, старые — из Версии/
     ├─ StatusResolver       txt + теги → статус
     └─ CompletenessCalculator  SPEC §3.7
```

- Сортировка — отдельная чистая функция `NodeSorter.sort(_:by:order:)` над снимком. UI её вызывает, сканер про сортировку не знает.
- `rescan(subtree:)` пересканирует только поддерево после операции, чтобы не обходить всю библиотеку.
- Цель скорости: ~300 файлов меньше чем за секунду.

### 3.6 FileOps — все записи на диск (SPEC §4)

Главный модуль переиспользования: **любое действие пользователя, меняющее диск, — это `Intent`, превращённый в `Plan`**.

```
Intent ──Planner──► Plan ──PlanValidator──► Plan(+конфликты) ──UI предпросмотр──► PlanExecutor ──► Journal
                                                                                     │
                                                                          при ошибке: откат сделанного
```

| Компонент | Ответственность |
|---|---|
| `Operation` | Атомарный шаг: `createFolder`, `move`, `rename`, `writeFile` (атомарно: временный файл + replace), `setTags`, `moveToTrash`. У каждого есть `inverse` для отката и undo. **Удаления навсегда нет как типа.** |
| `Plan` | Упорядоченный список операций + `title` («Новая версия: Держатель досок v4») + `changes: [Change]` для таблицы «было → станет». |
| `Intent` | Что хочет пользователь: `newFolder`, `move`, `rename`, `renameByRule`, `makeCollection`, `makeModel`, `setStatus`, `appendNote`, `editDescription`, `addVersion`, `cleanupOldVersions`, `sortInbox`, `moveDuplicatesToDelete`. |
| `Planner` | `plan(for: Intent, in: LibrarySnapshot) throws -> Plan`. Вся бизнес-логика действий живёт здесь, по одному файлу на намерение (`Planner+AddVersion.swift`…). Чистая функция: диск не трогает. |
| `ConflictResolver` | **Единственное место** правила «не затираем, добавляем суффикс». Используют Planner и Validator. |
| `PlanValidator` | Проверяет план против текущего диска прямо перед выполнением: файл исчез, имя занято, нет прав. |
| `PlanExecutor` (actor) | Выполняет операции по порядку через `FileSystem` и `TagStore`. При ошибке откатывает уже сделанное в обратном порядке. |
| `OperationJournal` | JSON в Application Support: пакеты операций с инверсиями. `undoLast()` = выполнить инверсный план тем же исполнителем. |

Почему так:
- новый сценарий = новый `Intent` + один метод `Planner`. Предпросмотр, конфликты, откат, журнал и undo он получает бесплатно;
- Planner — чистая функция, поэтому сценарии тестируются без диска: «на входе снимок, на выходе такой-то план»;
- Executor тестируется отдельно на временной папке и с `FaultyFileSystem` (ошибка на N-м шаге → проверка отката).

### 3.7 Previews — превью и кэш (SPEC §6)

```
PreviewService (actor, ограничение параллельности)
  image(for: ModelFile, size:) async -> PreviewImage?
     ├─ PreviewCache      PNG в Application Support, ключ = путь + дата изменения + размер
     └─ PreviewProvider   протокол, по реализации на формат:
          ThreeMFPreviewProvider   Metadata/plate_1.png из zip, без распаковки на диск
          STLPreviewRenderer       Model I/O + SceneKit, офскрин
          FormatIconProvider       F3D, Blend: иконка формата
```

- `PreviewImage` — PNG-данные / `CGImage`. Без `NSImage`, чтобы ядро не тянуло AppKit.
- Превью коллекции и группы выбирает `PreviewSourcePicker` (общий 3MF → первая деталь → первая модель внутри). Это правило, а не код во View.
- Индекс кэша: по SPEC — SwiftData. Решение отложено до этапа 5 (возможно, хватит имени файла-ключа без базы).

### 3.8 Support — подменяемые зависимости

- `FileSystem` (протокол): список папки, атрибуты, чтение и атомарная запись, move, createDirectory, trashItem. Живая реализация `LocalFileSystem` поверх `FileManager`. В тестах — реальная временная папка, а для откатов — `FaultyFileSystem`, обёртка с ошибкой на заданном шаге.
- `Clock` — текущая дата для записей журнала в txt, чтобы тесты были детерминированными.
- Корень библиотеки всегда передаётся явно. Глобальных путей в ядре нет.

---

## 4. App

### 4.1 Состояние

| Store (`@Observable`, `@MainActor`) | Отвечает за |
|---|---|
| `LibraryStore` | Текущий `LibrarySnapshot`, запуск сканирования, приём `Plan` → выполнение → `rescan`. Единственный, кто зовёт `LibraryScanner` и `PlanExecutor`. |
| `NavigationModel` | Путь (стопка папок), история назад/вперёд, текущий экран (папка / коллекция / модель / «Разобрать»). Знает только `NodeID`. |
| `BrowserState` | Сортировка, сетка или список, выделение. |
| `PlanStore` | Активный план на подтверждении. Показывает лист «План изменений», по «Применить» передаёт в `LibraryStore`. |
| `PreviewLoader` | Мост к `PreviewService`: отдаёт карточкам картинки по мере готовности, отменяет ушедшие с экрана. |
| `SettingsStore` | Корневая папка (security-scoped bookmark не нужен: sandbox выключен), слайсер по умолчанию. `UserDefaults`. |

Stores создаются один раз в `SorterApp` и попадают во View через `.environment(...)`. View не создают сторы сами.

### 4.2 Сценарий записи из UI (общий для всех действий)

```swift
// Любая кнопка, меняющая диск, делает ровно это:
planStore.propose(.addVersion(file: url, to: modelID))
// PlanStore → Planner.plan(...) → лист «было → станет» → «Применить»
// → LibraryStore.apply(plan) → PlanExecutor → Journal → rescan(subtree)
```

View никогда не вызывает `FileManager`, `Planner` или `PlanExecutor` напрямую.

### 4.3 Компоненты интерфейса и переиспользование

Папки фич: `Sidebar`, `Browser`, `Collection`, `Model`, `Inbox`, `Plan`, `Journal`. Общие кусочки — в **`App/Components`**, если используются хотя бы в двух фичах:

| Компонент | Где используется |
|---|---|
| `FolderTabShape`, `FolderLayerView` | стопка папок пути (Browser), карточки папок |
| `PathStackView` | Browser, Collection, Model (одна стопка для всех экранов) |
| `FolderCard`, `CollectionCard`, `ModelCard` | сетка Browser, группы в Collection |
| `PreviewView` | карточки, шапка коллекции, экран модели |
| `StatusBadge`, `StatusPicker` | карточки, экран модели, теги в Sidebar |
| `VersionBadge` | карточки, экран модели, таймлайн |
| `CompletenessChips` | шапка коллекции, экран модели |
| `CapsuleButton`, `ToolbarCapsules` | тулбар, кнопки «В слайсер / Fusion / Finder» |
| `SearchField` | основная область (место уточним) |

- `Theme` — **единственное место** цветов, радиусов, размеров и правил затемнения папок по глубине. Цвет статуса и типа узла: `Theme.color(for: Status)`, `Theme.color(for: NodeKind)`. Hex и «магические» числа во View запрещены.
- Скругления — только `.continuous` через формы из `Theme`.
- Тексты для пользователя рядом с View. Если появится локализация — String Catalog.

### 4.4 Внешние приложения

`ExternalApps` в `App/Services`: открыть файл в слайсере (OrcaSlicer / Orca-Flashforge / Flash Studio), в Fusion, показать в Finder. Это `NSWorkspace`, поэтому живёт в App, а не в ядре.

---

## 5. Основные потоки

### 5.1 Запуск
`SettingsStore.root` → `LibraryStore.load()` → `LibraryScanner.scan` (фоном) → снимок → Sidebar и Browser рисуются из снимка → `PreviewLoader` догружает превью видимых карточек.

### 5.2 Навигация
Клик по папке или корешку → `NavigationModel.push / popTo(NodeID)` → View берут узел из снимка. Диск не читается.

### 5.3 Изменение
Действие → `Intent` → `Planner` → `Plan` → лист предпросмотра → «Применить» → `PlanValidator` → `PlanExecutor` → `OperationJournal` → `rescan(subtree)` → новый снимок → UI обновился.

### 5.4 Undo
⌘Z → `OperationJournal.undoLast()` → инверсный план → тот же `PlanExecutor` → `rescan`.

### 5.5 Внешние изменения
До FSEvents (v0.2): пересканирование по кнопке и при активации окна. Потом — `LibraryWatcher` в Scanner, который вызывает `rescan(subtree:)`.

---

## 6. Конкурентность и ошибки

- Ядро: `LibraryScanner`, `PlanExecutor`, `PreviewService` — акторы. Снимки, планы, документы — `Sendable`-значения.
- App: сторы на `@MainActor`, тяжёлая работа уходит в акторы через `async`.
- Одновременно выполняется не больше одного плана (очередь в `LibraryStore`).
- Ошибки ядра — `SorterError` с контекстом (путь, операция). App превращает их в понятный текст: что случилось и что делать.

---

## 7. Где живёт правило (чтобы не дублировать)

| Нужно… | Используй | Не пиши заново |
|---|---|---|
| сравнить или почистить имя | `TextNormalizer` | `trimmingCharacters`, NFC руками |
| собрать или разобрать имя файла | `ModelName`, `NameParser` | регулярки во View или в Planner |
| сгруппировать файлы одной модели | `NameParser.groupingKey` | свою эвристику похожести |
| узнать вид файла | `FileKind(url:)` | проверку `pathExtension` |
| сравнить или поднять версию | `Version` | парсинг «v2.1» строкой |
| статус ↔ тег | `TagMapping`, `StatusResolver` | строки «Зелёный» в коде |
| тип папки | `FolderClassifier` | проверку имени во View |
| не затереть файл | `ConflictResolver` | `fileExists` + суффикс руками |
| что-то записать на диск | `Intent` → `Planner` | `FileManager` где угодно, кроме `LocalFileSystem` |
| отсортировать узлы | `NodeSorter` | `sorted` во View |
| превью для узла | `PreviewSourcePicker` + `PreviewService` | загрузку zip в карточке |
| цвет, радиус, размер | `Theme` | hex и числа во View |
| общий кусок UI в двух местах | `App/Components` | копию View |

---

## 8. Тесты

| Модуль | Как тестируем |
|---|---|
| Naming | Таблица реальных имён из тестовой копии + round-trip `build → parse`. |
| Notes | Round-trip байт в байт, правки на файлах с ручным текстом и мусором, кириллица, пустой файл. |
| Tags | `InMemoryTagStore` для логики, живой `TagStore` на временных файлах. |
| Scanner | Синтетическая библиотека в фикстурах + `FixtureBuilder` (DSL для временной папки: `folder("Кейсы", type: .collection) { file("Крышка – v2.stl") }`). Отдельно — сводка по `~/Sorter-testdata` только на чтение. |
| FileOps | Planner — на снимках без диска. Executor — на временной папке, откат через `FaultyFileSystem`, undo, конфликты, NFC. |
| Previews | Маленькие 3MF и STL в фикстурах, проверка размера и непустоты PNG. |
| App | Логика в сторах тестируется через ядро. UI проверяем глазами и скриншотами по этапам. |

Тесты, которые пишут на диск, работают только во временной папке.

---

## 9. Как это ложится на этапы

| Этап | Что появляется |
|---|---|
| 1 | Domain (типы), Naming (`TextNormalizer`, `ModelName`, `NameParser`, `Version`, `FileKind`) |
| 2 | Notes (`NotesDocument`, парсер, правки), Tags (`TagStore`, `TagMapping`), Support (`FileSystem`, `Clock`) |
| 3 | Scanner целиком, `LibrarySnapshot`, `NodeSorter`, `CompletenessCalculator`, `FixtureBuilder` |
| 4 | App: `LibraryStore`, `NavigationModel`, `BrowserState`, `SettingsStore`, `PathStackView`, карточки, Theme-правила глубины |
| 5 | Previews: провайдеры, кэш, `PreviewService`, `PreviewLoader` |
| 6 | FileOps: `Operation`, `Plan`, `Planner` (папка, перемещение, переименование, коллекция/модель), Validator, Executor, Journal; App: `PlanStore`, лист плана, журнал |
| 7 | Экраны коллекции и модели; Planner: статус, заметка, описание; `ExternalApps` |
| 8 | Planner: `addVersion`, `cleanupOldVersions` |
| 9 | Planner: `sortInbox`, дубли; экран «Разобрать» |

---

## 10. Открытые вопросы

1. Индекс кэша превью: SwiftData, как в SPEC, или достаточно файлов-ключей. Решаем на этапе 5.
2. Делить ли `SorterCore` на отдельные таргеты по модулям, чтобы компилятор проверял границы из §2. Пока нет: один таргет проще. Вернёмся, если границы начнут нарушаться.
