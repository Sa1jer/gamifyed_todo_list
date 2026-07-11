# RPG ToDo List

Flutter-приложение для развития навыков через маленькие квесты.

Главная продуктовая ось:

```text
Навык -> Цель -> Roadmap -> Этап -> Квест -> Минимальный шаг -> XP -> Рост
```

Приложение не пытается быть обычным ToDo-list. Его core loop проще:

1. Выбрать следующий полезный квест.
2. Сделать минимальный шаг или закрыть квест полностью.
3. Получить XP и feedback.
4. Увидеть, какой навык и этап продвинулись.
5. Раз в неделю мягко пересмотреть цель и следующий фокус.

## Основные режимы

- `Сейчас` - ежедневное действие: следующий квест, минимальный шаг, XP.
- `План` - мастерская настройки навыка: активные квесты и одно главное улучшение.
- `Карта` - Roadmap мастерства: навыки, этапы, связи и практика этапов.
- `Рост` - история прогресса: победы, цели, недельный обзор, трофеи и сопротивление.

## SMARTER Foundation

SMARTER в проекте не является обязательным wizard-ом. Это мягкий слой:

- `GoalSpec` хранит цель навыка, метрику, дедлайн и review history.
- `GoalEngine` даёт тихие подсказки при формулировке цели.
- `RoadmapEngine` определяет текущий и следующий этап навыка.
- `RecurringEngine` группирует повторяющиеся квесты без новой видимой системы.
- `ReviewEngine` помогает сделать короткий weekly review.
- `ProgressEngine` показывает прогресс по цели, этапам и недавним победам.

## UX Guardrails

- Advanced-поля не должны возвращаться в основной UI без причины.
- `Приоритет` остаётся лёгким tie-breaker-ом, а не главным смыслом дня.
- Roadmap - это путь, а не freeform mindmap/editor.
- Трофеи, эффекты и сопротивление - feedback после действия, а не работа на сегодня.
- Android/narrow UX проектируется action-first, а не как сжатый desktop.

## Development

Требуемый toolchain:

- Flutter `3.44.3` stable или новее в пределах Flutter `3.x`;
- Dart `3.12.2` (поставляется с Flutter `3.44.3`).

Ограничение также зафиксировано в `pubspec.yaml`. Это важно для API
`ReorderableListView.onReorderItem`, которого нет в старых Flutter SDK.

```bash
dart format lib test
flutter analyze
flutter test -r expanded --timeout 30s
```

The repository workflow, task templates, review process, and cross-platform
local verifier live in [AGENTS.md](AGENTS.md) and
[docs/development/TASK_WORKFLOW.md](docs/development/TASK_WORKFLOW.md). Run the
non-mutating full local gate with:

```bash
dart run tool/verify.dart
```

Если VSCode на Windows показывает ошибки про `onReorderItem`, хотя Git чистый,
сначала проверьте SDK, который использует именно расширение Flutter:

```powershell
flutter --version
dart --version
where.exe flutter
git rev-parse HEAD
flutter pub get
```

Для этого репозитория Flutter должен быть не старее `3.44.3`. В VSCode
выберите тот же путь через `Flutter: Change SDK`, затем выполните
`Dart: Restart Analysis Server`. `pubspec.lock` фиксирует пакеты, но не может
сам обновить Flutter SDK на другой машине.

Перед release-pass дополнительно стоит пройти fresh-state flow:

```text
создать навык -> получить первый этап и первый квест -> сделать минимальный шаг -> увидеть рост
```
