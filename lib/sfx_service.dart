import 'dart:math' as math;
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';

enum SfxCue { selection, light, success, milestone, reward, destructive }

class SfxService {
  SfxService._();

  static final SfxService instance = SfxService._();

  final List<AudioPlayer> _players = List.generate(3, (_) => AudioPlayer());
  int _nextPlayer = 0;
  DateTime _lastPlayedAt = DateTime.fromMillisecondsSinceEpoch(0);

  bool enabled = true;

  static final Map<SfxCue, Uint8List> _sounds = {
    SfxCue.selection: _tone(
      frequencies: const [720],
      durationMs: 28,
      volume: 0.22,
    ),
    SfxCue.light: _tone(
      frequencies: const [620, 930],
      durationMs: 52,
      volume: 0.24,
    ),
    SfxCue.success: _tone(
      frequencies: const [523.25, 659.25, 783.99],
      durationMs: 96,
      volume: 0.28,
    ),
    SfxCue.milestone: _tone(
      frequencies: const [523.25, 659.25, 987.77],
      durationMs: 150,
      volume: 0.34,
    ),
    SfxCue.reward: _tone(
      frequencies: const [659.25, 783.99, 1046.5],
      durationMs: 180,
      volume: 0.34,
    ),
    SfxCue.destructive: _tone(
      frequencies: const [220, 146.83],
      durationMs: 80,
      volume: 0.22,
    ),
  };

  Future<void> play(SfxCue cue) async {
    if (!enabled) return;

    final now = DateTime.now();
    final cooldown = cue == SfxCue.selection
        ? const Duration(milliseconds: 35)
        : const Duration(milliseconds: 70);
    if (now.difference(_lastPlayedAt) < cooldown) return;
    _lastPlayedAt = now;

    final sound = _sounds[cue];
    if (sound == null) return;

    final player = _players[_nextPlayer++ % _players.length];
    try {
      await player.stop();
      await player.play(
        BytesSource(sound, mimeType: 'audio/wav'),
        mode: PlayerMode.lowLatency,
        volume: _volumeFor(cue),
      );
    } catch (_) {
      // SFX should never block the core task flow if a platform plugin is absent.
    }
  }

  double _volumeFor(SfxCue cue) => switch (cue) {
    SfxCue.selection => 0.24,
    SfxCue.light => 0.28,
    SfxCue.success => 0.34,
    SfxCue.milestone => 0.42,
    SfxCue.reward => 0.42,
    SfxCue.destructive => 0.24,
  };

  static Uint8List _tone({
    required List<double> frequencies,
    required int durationMs,
    required double volume,
  }) {
    const sampleRate = 22050;
    final sampleCount = (sampleRate * durationMs / 1000).round();
    final data = ByteData(44 + sampleCount * 2);

    void writeString(int offset, String value) {
      for (var i = 0; i < value.length; i++) {
        data.setUint8(offset + i, value.codeUnitAt(i));
      }
    }

    writeString(0, 'RIFF');
    data.setUint32(4, 36 + sampleCount * 2, Endian.little);
    writeString(8, 'WAVE');
    writeString(12, 'fmt ');
    data.setUint32(16, 16, Endian.little);
    data.setUint16(20, 1, Endian.little);
    data.setUint16(22, 1, Endian.little);
    data.setUint32(24, sampleRate, Endian.little);
    data.setUint32(28, sampleRate * 2, Endian.little);
    data.setUint16(32, 2, Endian.little);
    data.setUint16(34, 16, Endian.little);
    writeString(36, 'data');
    data.setUint32(40, sampleCount * 2, Endian.little);

    final attackSamples = (sampleRate * 0.008).round();
    final releaseSamples = (sampleRate * 0.045).round();

    for (var i = 0; i < sampleCount; i++) {
      final attack = attackSamples == 0 ? 1.0 : (i / attackSamples).clamp(0, 1);
      final release = releaseSamples == 0
          ? 1.0
          : ((sampleCount - i) / releaseSamples).clamp(0, 1);
      final envelope = attack * release;
      var mixed = 0.0;
      for (final frequency in frequencies) {
        mixed += math.sin(2 * math.pi * frequency * i / sampleRate);
      }
      mixed = mixed / frequencies.length;
      final sample = (mixed * volume * envelope * 32767).round().clamp(
        -32768,
        32767,
      );
      data.setInt16(44 + i * 2, sample, Endian.little);
    }

    return data.buffer.asUint8List();
  }
}
