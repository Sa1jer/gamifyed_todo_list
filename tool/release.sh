#!/usr/bin/env bash
#
# Собирает подписанный релиз и выкладывает его в GitHub Releases.
#
# Ключ подписи намеренно не уезжает в CI: он невосстановим, и его смена
# заставит всех тестировщиков переустановить приложение с потерей данных.
# Поэтому сборка идёт здесь, на машине владельца, а наружу уходит только APK.
#
#   tool/release.sh              — поднять номер сборки и выложить
#   tool/release.sh --dry-run    — собрать и проверить, но не публиковать
#
set -euo pipefail

cd "$(dirname "$0")/.."

DRY_RUN=false
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=true

fail() { echo "✗ $1" >&2; exit 1; }

# ── Проверки до того, как что-то менять ──────────────────────────────────────

[[ -f android/key.properties ]] ||
  fail "android/key.properties не найден. См. docs/BETA_DISTRIBUTION.md"

if ! $DRY_RUN; then
  command -v gh >/dev/null || fail "нужен gh: brew install gh"
  gh auth status >/dev/null 2>&1 || fail "gh не авторизован: gh auth login"
fi

[[ -z "$(git status --porcelain)" ]] ||
  fail "рабочее дерево грязное — закоммитьте изменения перед релизом"

# ── Номер сборки ─────────────────────────────────────────────────────────────
# Android ставит обновление поверх установленного, только если versionCode
# строго больше. Одинаковый номер — установщик молча откажет.
#
# Проверка правит файлы, поэтому при --dry-run и при любом обрыве они
# возвращаются как были: иначе следующий запуск упрётся в грязное дерево,
# которое сам же и создал.
restore_version() {
  git checkout -- pubspec.yaml lib/utils.dart 2>/dev/null || true
}

CURRENT=$(grep '^version:' pubspec.yaml | sed 's/version: *//')
NAME="${CURRENT%%+*}"
BUILD="${CURRENT##*+}"
NEXT=$((BUILD + 1))
VERSION="$NAME+$NEXT"

echo "Версия: $CURRENT → $VERSION"

# Ярлык в приложении и pubspec обязаны совпадать: по номеру сборки проверка
# обновлений решает, отстала ли установленная версия. Разошлись — приложение
# соврёт, что оно последнее.
perl -pi -e "s/^version: .*/version: $VERSION/" pubspec.yaml
perl -pi -e "s/^const String kAppVersionLabel = .*/const String kAppVersionLabel = 'v$VERSION';/" lib/utils.dart

trap restore_version EXIT

flutter test test/app_version_test.dart >/dev/null ||
  fail "версия в приложении разошлась с pubspec"

# ── Сборка ───────────────────────────────────────────────────────────────────

echo "Сборка релиза…"
flutter build apk --release >/dev/null || fail "сборка не удалась"

APK=build/app/outputs/flutter-apk/app-release.apk
[[ -f "$APK" ]] || fail "APK не найден: $APK"

# ── Подпись ──────────────────────────────────────────────────────────────────
# Спрашиваем у самого артефакта, а не у конфигурации: собралось — не значит
# подписалось тем ключом, которым нужно.

BUILD_TOOLS=$(ls -d "${ANDROID_HOME:-$HOME/Library/Android/sdk}"/build-tools/* | sort -V | tail -1)

# Вывод забираем целиком и фильтруем уже в переменной. `| head -1` закрывал бы
# канал раньше, чем apksigner договорил, тот получал SIGPIPE, и `pipefail`
# ронял весь скрипт с кодом 141 вместо того, чтобы напечатать сертификат.
SIGNER_OUTPUT=$("$BUILD_TOOLS/apksigner" verify --print-certs "$APK" 2>/dev/null || true)
CERT=$(printf '%s\n' "$SIGNER_OUTPUT" | awk '/certificate DN/ {print; exit}')

[[ -n "$CERT" ]] || fail "APK не подписан"
case "$CERT" in
  *"CN=Android Debug"*)
    fail "APK подписан отладочным ключом — обновления не встанут поверх" ;;
esac

BADGING=$("$BUILD_TOOLS/aapt2" dump badging "$APK" 2>/dev/null || true)
PACKAGE=$(printf '%s\n' "$BADGING" | awk 'NR == 1')

echo
echo "  $PACKAGE"
echo "  $CERT"
echo "  $(du -h "$APK" | cut -f1)"
echo

# ── Публикация ───────────────────────────────────────────────────────────────

TAG="v$VERSION"

if $DRY_RUN; then
  echo "--dry-run: не публикую. Тег был бы $TAG"
  echo "Версия в файлах вернётся к $CURRENT — проверка ничего за собой не оставляет."
  exit 0
fi

# Дальше изменения нужны: снимаем восстановление.
trap - EXIT

git add pubspec.yaml lib/utils.dart
git commit -m "chore: release $VERSION"
git push

# Тег несёт номер сборки: приложение читает его, чтобы понять, отстало ли оно.
gh release create "$TAG" "$APK" \
  --title "$NAME ($NEXT)" \
  --notes "Сборка $NEXT. Обновление встанет поверх предыдущей, данные сохранятся."

echo
echo "✓ Опубликовано: $TAG"
echo "  Тестировщикам с версией до io.github.sa1jer.rpgtodo нужен перенос —"
echo "  см. docs/BETA_DISTRIBUTION.md"
