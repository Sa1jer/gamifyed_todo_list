import 'package:audioplayers/audioplayers.dart';

enum SfxCue { selection, light, success, milestone, reward, destructive }

class SfxService {
  SfxService._();

  static final SfxService instance = SfxService._();

  final List<AudioPlayer> _players = List.generate(3, (_) => AudioPlayer());
  int _nextPlayer = 0;
  DateTime _lastPlayedAt = DateTime.fromMillisecondsSinceEpoch(0);

  bool enabled = true;

  static const Map<SfxCue, String> _assets = {
    SfxCue.selection: 'sfx/selection.wav',
    SfxCue.light: 'sfx/light.wav',
    SfxCue.success: 'sfx/success.wav',
    SfxCue.milestone: 'sfx/milestone.wav',
    SfxCue.reward: 'sfx/reward.wav',
    SfxCue.destructive: 'sfx/destructive.wav',
  };

  Future<void> play(SfxCue cue) async {
    if (!enabled) return;

    final now = DateTime.now();
    final cooldown = cue == SfxCue.selection
        ? const Duration(milliseconds: 35)
        : const Duration(milliseconds: 70);
    if (now.difference(_lastPlayedAt) < cooldown) return;
    _lastPlayedAt = now;

    final asset = _assets[cue];
    if (asset == null) return;

    final player = _players[_nextPlayer++ % _players.length];
    try {
      await player.stop();
      await player.play(
        AssetSource(asset, mimeType: 'audio/wav'),
        mode: PlayerMode.mediaPlayer,
        volume: _volumeFor(cue),
      );
    } catch (_) {
      // SFX should never block the core task flow if a platform plugin is absent.
    }
  }

  double _volumeFor(SfxCue cue) => switch (cue) {
    SfxCue.selection => 0.45,
    SfxCue.light => 0.48,
    SfxCue.success => 0.56,
    SfxCue.milestone => 0.62,
    SfxCue.reward => 0.62,
    SfxCue.destructive => 0.42,
  };
}
