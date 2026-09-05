import 'dart:convert';
import 'dart:io';

import 'utils.dart';

/// Репозиторий, из которого раздаются сборки.
const _releasesEndpoint =
    'https://api.github.com/repos/Sa1jer/gamifyed_todo_list/releases/latest';

/// Новая сборка, о которой стоит сказать.
class AppUpdate {
  final int buildNumber;
  final String versionName;
  final String url;

  const AppUpdate({
    required this.buildNumber,
    required this.versionName,
    required this.url,
  });
}

/// Номер сборки из тега релиза: `v1.3.64+3` → `3`.
///
/// Сравнивается именно он, а не видимое имя: `1.3.64` и `1.4.0` как строки не
/// упорядочены, а номер сборки монотонно растёт. Тег без `+` — это релиз,
/// сделанный руками мимо `tool/release.sh`, и сравнивать его не с чем.
int? buildNumberFromTag(String tag) {
  final plus = tag.lastIndexOf('+');
  if (plus == -1) return null;
  return int.tryParse(tag.substring(plus + 1).trim());
}

/// Решает, есть ли о чём сообщать, по ответу GitHub.
///
/// Возвращает `null`, если ответ непонятен, релиз черновой или установленная
/// версия не старше. Молчание здесь — норма, а не ошибка.
AppUpdate? updateFromRelease(
  Map<String, dynamic> release, {
  required int currentBuild,
}) {
  if (release['draft'] == true || release['prerelease'] == true) return null;
  final tag = release['tag_name'];
  if (tag is! String) return null;
  final build = buildNumberFromTag(tag);
  if (build == null || build <= currentBuild) return null;
  final url = release['html_url'];
  return AppUpdate(
    buildNumber: build,
    versionName: tag.startsWith('v') ? tag.substring(1) : tag,
    url: url is String
        ? url
        : 'https://github.com/Sa1jer/gamifyed_todo_list/releases',
  );
}

typedef ReleaseFetcher = Future<Map<String, dynamic>?> Function();

/// Проверяет, не отстала ли установленная сборка от последнего релиза.
///
/// Проверка идёт **один раз за запуск** и только по требованию. Этого хватает:
/// без авторизации GitHub отдаёт 60 запросов в час на адрес, а сборки выходят
/// куда реже. Любая ошибка — отсутствие сети, лимит, чужой формат ответа —
/// это тишина, а не сообщение: фоновая проверка не должна мозолить глаза.
class UpdateChecker {
  UpdateChecker({ReleaseFetcher? fetch, int? currentBuild})
    : _fetch = fetch ?? _fetchLatestRelease,
      _currentBuild = currentBuild ?? appBuildNumber;

  final ReleaseFetcher _fetch;
  final int? _currentBuild;

  bool _checked = false;
  AppUpdate? _found;

  /// Что нашлось в прошлый раз. Виджеты читают это, не вызывая сеть.
  AppUpdate? get available => _found;

  bool get hasChecked => _checked;

  Future<AppUpdate?> check() async {
    if (_checked) return _found;
    final current = _currentBuild;
    if (current == null) {
      _checked = true;
      return null;
    }
    try {
      final release = await _fetch();
      _found = release == null
          ? null
          : updateFromRelease(release, currentBuild: current);
    } catch (_) {
      _found = null;
    }
    _checked = true;
    return _found;
  }
}

Future<Map<String, dynamic>?> _fetchLatestRelease() async {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
  try {
    final request = await client.getUrl(Uri.parse(_releasesEndpoint));
    // GitHub отказывает запросам без User-Agent.
    request.headers.set(HttpHeaders.userAgentHeader, 'RPG-To-Do');
    request.headers.set(
      HttpHeaders.acceptHeader,
      'application/vnd.github+json',
    );
    final response = await request.close();
    if (response.statusCode != 200) return null;
    final body = await response.transform(utf8.decoder).join();
    final decoded = jsonDecode(body);
    return decoded is Map<String, dynamic> ? decoded : null;
  } finally {
    client.close(force: true);
  }
}
