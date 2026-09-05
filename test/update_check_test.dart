import 'package:flutter_test/flutter_test.dart';
import 'package:todo_list_app/update_check.dart';

void main() {
  Map<String, dynamic> release(
    String tag, {
    bool draft = false,
    bool prerelease = false,
  }) => {
    'tag_name': tag,
    'draft': draft,
    'prerelease': prerelease,
    'html_url': 'https://example.invalid/$tag',
  };

  group('reading a build number out of a tag', () {
    test('takes the number after the plus', () {
      expect(buildNumberFromTag('v1.3.64+3'), 3);
      expect(buildNumberFromTag('v2.0.0+128'), 128);
    });

    test('a tag without a build number is not comparable', () {
      // Такой тег сделан руками мимо tool/release.sh, и сравнивать его не с
      // чем: имена версий как строки не упорядочены.
      expect(buildNumberFromTag('v1.3.64'), isNull);
      expect(buildNumberFromTag('latest'), isNull);
      expect(buildNumberFromTag('v1.3.64+хвост'), isNull);
    });
  });

  group('deciding whether to say anything', () {
    test('a newer build is worth reporting', () {
      final update = updateFromRelease(release('v1.4.0+7'), currentBuild: 3);
      expect(update, isNotNull);
      expect(update!.buildNumber, 7);
      expect(update.versionName, '1.4.0+7');
    });

    test('the same build is not an update', () {
      expect(updateFromRelease(release('v1.3.64+3'), currentBuild: 3), isNull);
    });

    test('an older release does not roll the user backwards', () {
      // Релиз могли удалить и перевыпустить; предлагать откат нельзя.
      expect(updateFromRelease(release('v1.3.0+1'), currentBuild: 3), isNull);
    });

    test('drafts and prereleases stay invisible', () {
      expect(
        updateFromRelease(release('v9.9.9+99', draft: true), currentBuild: 3),
        isNull,
      );
      expect(
        updateFromRelease(
          release('v9.9.9+99', prerelease: true),
          currentBuild: 3,
        ),
        isNull,
      );
    });

    test('an answer in an unexpected shape is silence, not a crash', () {
      expect(updateFromRelease(const {}, currentBuild: 3), isNull);
      expect(updateFromRelease(const {'tag_name': 7}, currentBuild: 3), isNull);
    });
  });

  group('the checker', () {
    test('asks the network once per session', () async {
      var calls = 0;
      final checker = UpdateChecker(
        currentBuild: 1,
        fetch: () async {
          calls++;
          return release('v1.3.64+9');
        },
      );

      expect((await checker.check())!.buildNumber, 9);
      expect((await checker.check())!.buildNumber, 9);
      expect(calls, 1, reason: 'повторный вызов должен брать уже найденное');
      expect(checker.available!.buildNumber, 9);
    });

    test('a failed request is silence', () async {
      final checker = UpdateChecker(
        currentBuild: 1,
        fetch: () async => throw const SocketExceptionStub(),
      );

      expect(await checker.check(), isNull);
      expect(checker.hasChecked, isTrue);
      expect(checker.available, isNull);
    });

    test('being offline is not an error to show', () async {
      final checker = UpdateChecker(currentBuild: 1, fetch: () async => null);
      expect(await checker.check(), isNull);
    });
  });
}

class SocketExceptionStub implements Exception {
  const SocketExceptionStub();
}
