# 3D Models Sorter — правила для Claude

Нативное macOS-приложение (SwiftUI, macOS 26), которое наводит порядок в папке с 3D-моделями.
Что строим — [SPEC.md](SPEC.md). Этапы и журнал — [ROADMAP.md](ROADMAP.md).
Архитектура, компоненты и «где живёт какое правило» — [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md). **Читай перед каждым этапом**; новый код кладём туда, куда указывает документ, а если структура меняется — обновляем документ в том же коммите.
Эталон интерфейса — интерактивный макет [design/window-mockup.html](design/window-mockup.html).

## Главные правила

- **Работаем только с `~/Sorter-testdata/`.** Реальную папку `~/3D models ` (с пробелом в конце) не читаем и не меняем до этапа 9, и даже там только по явной команде пользователя.
- **Перед каждым шагом коротко скажи, что делаешь** (одна строка): «Создаю модуль Notes», «Запускаю тесты».
- Ничего не удаляем навсегда (SPEC.md §4): мусор уезжает в `_to_delete/`, старые версии в Корзину.
- Каждый этап заканчивается рабочим состоянием, отметкой в ROADMAP.md, записью в «Журнал» и коммитом.
- **Этап = ветка = PR.** В начале этапа создай ветку от свежего `main` (`stage-<N>-<коротко>`, например `stage-1-naming`), коммить в неё, в конце открой PR в `main` (GitHub: SimkaDV/Sorter). Мержит пользователь. Напрямую в `main` не коммитим и не пушим без явной просьбы.

## Архитектура и слои

```
App (SwiftUI)  ──►  SorterCore (чистый Swift, без SwiftUI)  ──►  диск
```

- **SorterCore/** — локальный Swift Package. Здесь вся логика: домен, имена, txt, теги, сканер, файловые операции, превью. Импортировать SwiftUI/AppKit запрещено (для превью допустимы Model I/O / SceneKit / ImageIO).
  - `Domain` — типы узлов, статусы, версии, виды файлов.
  - `Naming` — сборка/разбор имён (§3.3), разделитель ` – ` (U+2013) — константа `Naming.separator`.
  - `Notes` — txt-файл (§3.6).
  - `Tags` — теги Finder.
  - `Scanner` — обход библиотеки, дерево узлов.
  - `FileOps` — план «было → станет», применение, журнал, undo.
  - `Previews` — превью 3MF/STL и кэш.
- **App/** — SwiftUI-приложение. Только отображение и пользовательский ввод.
  - `Theme` — палитра «Мастерская» (§5). Цвета берём только из `Theme`, никаких hex во View.
  - `Sidebar`, `Browser`, `Collection`, `Model`, `Inbox` — экраны.
- **Никакой логики файлов во View.** View не вызывает `FileManager`, не парсит имена и txt. Всё через API SorterCore; запись на диск — только через планы FileOps.
- Проект Xcode генерируется из `project.yml` (XcodeGen). `Sorter.xcodeproj` в git не храним — правим `project.yml`.
- App Sandbox выключен (личное приложение, нужен доступ к произвольным папкам).

## Сборка и запуск

```bash
xcodegen generate                       # после изменения project.yml или добавления файлов в App/
xcodebuild -project Sorter.xcodeproj -scheme Sorter -configuration Debug -derivedDataPath build build
open "build/Build/Products/Debug/3D Models Sorter.app"
```

Тесты ядра:

```bash
scripts/test.sh          # обёртка над `swift test` в SorterCore/
```

`scripts/test.sh` сам добавляет пути к Swift Testing, если выбраны только Command Line Tools. С полным Xcode достаточно `cd SorterCore && swift test`.

Тесты — Swift Testing (`import Testing`, `@Test`, `#expect`). Синтетические фикстуры — `SorterCore/Tests/SorterCoreTests/Fixtures/` (доступ через `Bundle.module`). Тесты, которые пишут на диск, работают во временной папке, а не в фикстурах и не в `~/Sorter-testdata`.

## Стиль кода

- Swift 6, строгая конкурентность. Асинхронщина — `async/await`, без Combine.
- Типы ядра — `struct`/`enum`, `Sendable`; классы только где нужна идентичность.
- Публичный API SorterCore помечен `public`; всё остальное `internal`/`private`.
- Комментарии и пользовательский текст — по-русски. Имена в коде — по-английски.
- Строки с кириллицей нормализуем в NFC перед сравнением.
- Скругления в UI — только `.continuous` (`Theme.shape`).
- Маленькие файлы, один тип — один файл. Без лишних абстракций «на будущее».
