# Code Review / Crash Audit

Дата: 2026-07-01

## Итог

Проведён полный статический, crash, lifecycle, storage, release и regression-аудит текущего Flutter-приложения. Критических воспроизводимых падений после исправлений не осталось: анализатор чистый, `dart fix --dry-run` не предлагает изменений, baseline из 260 тестов прошёл до батча, сфокусированный набор из 118 тестов и финальный полный набор из 263 тестов прошли после него.

Аудит нашёл дополнительные варианты исходного `UnsupportedError`: несколько изменяемых полей моделей всё ещё могли получить fixed-length список от вызывающего кода. Они исправлены без изменения persisted schema. Также добавлены нормализация повреждённого времени напоминания, fail-soft поведение optional notification plugin, защита file picker и отсутствовавший `dispose` контроллера.

Главный оставшийся риск — crash-consistency локального хранения. Полная запись нескольких Hive boxes не атомарна, а ошибка фонового сохранения или стартовой загрузки сейчас не превращается в понятное recovery-состояние. Это требует отдельного storage-батча с fault-injection тестами; простое подавление исключений может скрыть потерю данных.

## Среда

- Flutter `3.44.3`, stable, revision `e1fd963c6f`.
- Dart `3.12.2`, DevTools `2.57.0`.
- macOS `15.7.7`, arm64; Xcode `26.3`; CocoaPods `1.16.2`.
- Android SDK не обнаружен.
- Xcode не видит установленные Simulator runtimes.
- Проект использует Flutter/Material, локальный `AppState`, Hive, local notifications и desktop/mobile targets.

## Выполненные проверки

| Проверка | Результат |
|---|---|
| `dart format lib test` | Чисто, 100 файлов, 0 изменений |
| `flutter analyze` | Чисто |
| `flutter test -r expanded --timeout 30s` до нового батча | 260 тестов прошли |
| Сфокусированные тесты после исправлений | 118 тестов прошли |
| Финальный полный regression suite | 263 теста прошли |
| `dart fix --dry-run` | `Nothing to fix` |
| `flutter pub outdated` | 24 locked updates; 6 зависимостей требуют изменения constraints |
| `git diff --check` | Чисто |
| `flutter build apk --release` | Заблокирован отсутствующим Android SDK |
| `flutter build appbundle --release` | Runner не разрешил повторный build-вызов после исчерпания approval quota; тот же Android SDK blocker остаётся |
| macOS release | Успешно собирался в предыдущем hardening baseline; текущий повтор потребовал запись во внешний Flutter SDK cache и был заблокирован исчерпанной approval quota runner-а |
| Gitleaks | Конфигурация и статические тесты есть, binary локально не установлен |

## Исправлено

### Crash / data-shape safety

- `Task`, `Skill`, `SkillTreeNode`, `GoalSpec` и `WeeklyGoal` теперь копируют caller-owned изменяемые списки.
- `AppState.updateTask` и `AppState.updateSkill` больше не сохраняют внешние списки напрямую.
- Пустые `consumedBuffIds` остаются growable после нормализации и undo/completion flow.
- Некорректные `notificationHour` / `notificationMinute` из старых или повреждённых данных отключают напоминание и очищаются, не доходя до `TimeOfDay`/native scheduling.

### Optional platform services

- Ошибка инициализации notification plugin больше не блокирует запуск приложения.
- Permission/schedule flow до успешной инициализации становится безопасным no-op.
- Ошибка native scheduling не прерывает создание или изменение квеста.
- File picker cancellation, пустой результат или platform exception больше не падают из профиля.

### Lifecycle

- `_AddBossDialogState` теперь освобождает свой `TextEditingController`.
- Остальные найденные controllers, timers и animation controllers имеют корректные `dispose`/`mounted` guards.
- Проверены async-переходы AddTask, AddSkill, RoadMap next-goal, profile image picker и milestone animations.

## Оставшиеся находки

### P1 — Data loss / startup recovery

1. `AppState._saveAll()` запускает `_writeAll()` через `unawaited`, а `pauseBackgroundWork()` аналогично запускает `flushSaves()`. При I/O/Hive ошибке `Completer.completeError` может стать необработанной async-ошибкой без retry или UI-состояния.
2. `StorageService.saveSkills`, `saveTasks` и другие domain saves сначала очищают box, затем записывают элементы по одному. Завершение процесса или ошибка в середине оставляет частичный snapshot; последовательная запись разных boxes также может рассинхронизировать задачи, навыки, историю и награды.
3. `loadSavedData()` запускается из `initState` без наблюдения результата. Ошибка I/O при стартовой загрузке не имеет fallback/retry экрана. Декодирование отдельных повреждённых JSON payload уже защищено хорошо, но отказ самого хранилища — нет.

Рекомендация: отдельный storage-reliability батч с snapshot/temporary-box strategy, последним successful snapshot, явным `PersistenceStatus`, retry и fault-injection тестами. Не менять schema без migration/rollback плана.

### P2 — Architecture / performance

1. Корневой `_RPGAppState` вызывает `setState` на каждое уведомление `AppState`, пересобирая `MaterialApp`, provider и весь основной shell. Это не crash, но создаёт риск jank по мере роста данных.
2. `AppState` вырос примерно до 3200 строк и оркестрирует storage, notifications, XP, history, rewards, tutorial и RoadMap mutations. Высокорисковые completion/save части нельзя извлекать без characterization tests.
3. Несколько UI-файлов превышают 1000-2400 строк. Это повышает вероятность lifecycle/regression ошибок, хотя текущий controller/context audit новых падений не нашёл.
4. RoadMap depth/layout повторно сканирует списки и рекурсивно вычисляет depth. Для текущих ограничений и тестов `0/1/10` этапов это приемлемо; перед очень крупными multi-road картами нужен profile, а не преждевременная оптимизация.

Рекомендация: сначала сузить rebuild boundary через listenable selectors/presentational subtrees; затем по одному извлекать только pure evaluators. Completion/save orchestration пока оставить в `AppState`.

### P2 — Release / privacy

1. Android/iOS/macOS всё ещё используют `com.example...` identifiers; Android release требует private signing config.
2. Android SDK отсутствует, iOS runtime/signing не готовы, поэтому mobile release artifacts не подтверждены.
3. Android backup отключён. Политика iOS backup и необходимость encrypted-at-rest хранения пользовательских задач/целей ещё не решены.
4. `SCHEDULE_EXACT_ALARM` и `exactAllowWhileIdle` требуют отдельной store-policy проверки.
5. Notification payload не содержит названия квестов; debug logs не печатают пользовательский текст; debug admin и `__debug__` storage имеют runtime release guards.
6. Текущий tree не показал похожих на секреты строк. Полную историю нельзя считать проверенной до запуска Gitleaks.
7. Profile picker читает изображение целиком через `withData: true`; очень большой файл остаётся memory-pressure риском и требует отдельного size/downsampling решения.

### P3 — Dependencies / build tooling

- Без major migration доступны обновления `audioplayers`, `flutter_timezone`, `hugeicons`, `path_provider` и `timezone`.
- `file_picker 8 -> 11` и `flutter_local_notifications 21 -> 22` требуют migration review.
- Старый `build_runner` удерживает discontinued transitive packages `build_resolvers` и `build_runner_core`; обновлять отдельно от crash-fix батча.

## Проверенные области без новых дефектов

- Unsafe `first/single/reduce` usages имеют локальные guards или доказуемые инварианты; storage enum/index parsing проверяет границы.
- Storage decoder пропускает повреждённые entries, ограничивает JSON depth и валидирует image magic bytes.
- Dialog/provider audit не нашёл нового чтения `AppStateProvider` из context, потерявшего inherited provider; fullscreen RoadMap явно прокидывает provider.
- RoadMap graph mutations сохраняют ids и проверяют cycle/linear-path инварианты; goal progress clamps counts and percentages.
- XP, undo, milestone idempotency, task inbox isolation, skill/stage reorder и responsive `360dp` flows покрыты тестами.
- Debug UI недоступен в release через обычный entrypoint и не смешан с production storage.

## Test gaps

- Fault-injection для I/O failure, disk-full, interrupted multi-box save и startup recovery.
- Native integration tests для permissions, exact alarms, schedule/cancel/restart на Android/iOS/macOS/Windows.
- Реальный restart test для сохранения reorder, completed goal/RoadMap history и notification state.
- Profile image size/downsampling tests.
- Manual QHD Windows hover/pointer и real-device mobile keyboard/theme animation checks.
- CI workflow для analyze/tests/release probes/Gitleaks отсутствует.

## Безопасный порядок следующих батчей

1. Storage reliability characterization: failing fake storage, retry semantics, interrupted snapshot tests.
2. Startup recovery UX/state: loading/error/retry без изменения persisted schema.
3. Atomic or recoverable local snapshot implementation с миграцией и rollback notes.
4. Native notification integration tests и exact-alarm policy decision.
5. Rebuild/performance profiling; только затем узкая декомпозиция.
6. Dependency-only upgrade batch и повтор всех release builds.

## Использованные checklists

- Локальные: `flutter-bug-audit`, `widget-dialog-safety`, `release-mobile-hardening`, `flutter-architecture-testing`, `future-cloud-boundary`, `appstate-decomposition`, `refactor-batch-protocol`.
- Defensive security: `implementing-secret-scanning-with-gitleaks`, `performing-privacy-impact-assessment`.
- Указанные в задании `flutter-dart-current-stack`, `flutter-upgrade-audit`, `mobile-responsive-ux`, `roadmap-layout-audit`, `goal-progress-modeling`, `animation-performance-audit` отсутствуют в локальной skill-библиотеке; соответствующие области проверены напрямую.
