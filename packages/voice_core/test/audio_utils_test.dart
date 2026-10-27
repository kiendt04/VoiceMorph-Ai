import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:voice_core/voice_core.dart';

void main() {
  test('computePeaks reports one peak per bucket', () {
    final samples = Float32List.fromList([0.1, -0.5, 0.2, 0.9, -0.3, 0.0]);
    final peaks = computePeaks(samples, 3);
    // Float32 storage: 0.9 comes back as 0.8999999761...
    expect(peaks, [for (final v in [0.5, 0.9, 0.3]) closeTo(v, 1e-6)]);
    expect(computePeaks(Float32List(0), 4), isEmpty);
    expect(() => computePeaks(samples, 0), throwsArgumentError);
  });

  test('peakLevel ignores sign and empty input', () {
    expect(peakLevel(Float32List.fromList([-0.25, 0.5, -0.75])), 0.75);
    expect(peakLevel(Float32List(0)), 0);
  });

  test('applyFade silences both ends without touching the middle', () {
    final samples = Float32List.fromList(List.filled(100, 1.0));
    final faded = applyFade(samples, sampleRate: 1000, fadeInMs: 10, fadeOutMs: 10);
    expect(faded.first, 0);
    expect(faded.last, 0);
    expect(faded[50], 1.0);
    expect(faded[5], closeTo(0.5, 1e-6));
    expect(faded[94], closeTo(0.5, 1e-6));
    expect(() => applyFade(samples, sampleRate: 0), throwsArgumentError);
  });

  test('trimSilence keeps a margin around the loud part', () {
    final samples = Float32List.fromList([
      0.0, 0.0, 0.0, 0.5, -0.5, 0.5, 0.0, 0.0,
    ]);
    // 1000 Hz sample rate, 0 ms margin: exactly the loud slice remains.
    final trimmed = trimSilence(samples, sampleRate: 1000, marginMs: 0);
    expect(trimmed, [0.5, -0.5, 0.5]);
    expect(trimSilence(Float32List.fromList([0.0, 0.0]), sampleRate: 1000), isEmpty);
  });
}
