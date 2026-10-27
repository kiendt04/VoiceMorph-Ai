import 'package:test/test.dart';
import 'package:voice_core/src/dsp/pitch_tempo.dart';
import 'package:voice_core/voice_core.dart';

import 'test_signals.dart';

void main() {
  test('octave up doubles frequency and keeps duration', () {
    final input = sine(220, 2);
    final output = runThrough(PitchTempo(sampleRate, 12, 1), input);

    expect(output.length, input.length);
    expect(estimateFrequency(output), closeTo(440, 440 * 0.02));
  });

  test('octave down halves frequency and keeps duration', () {
    final input = sine(440, 2);
    final output = runThrough(PitchTempo(sampleRate, -12, 1), input);

    expect(output.length, input.length);
    expect(estimateFrequency(output), closeTo(220, 220 * 0.02));
  });

  test('faster tempo shortens without changing pitch', () {
    final input = sine(300, 3);
    final output = runThrough(PitchTempo(sampleRate, 0, 1.5), input);

    expect(output.length, closeTo(input.length / 1.5, 1));
    expect(estimateFrequency(output), closeTo(300, 300 * 0.02));
  });

  test('slower tempo combines with a pitch shift', () {
    final input = sine(200, 2);
    final output = runThrough(PitchTempo(sampleRate, 7, 0.75), input);

    expect(output.length, closeTo(input.length / 0.75, 1));
    expect(estimateFrequency(output), closeTo(200 * 1.4983, 6));
  });

  test('resampler converts sample rate preserving frequency', () {
    final input = sine(1000, 1, rate: 48000);
    final output = Resampler.convert(input, 48000, 44100);

    expect(output.length, closeTo(44100, 1));
    expect(estimateFrequency(output, rate: 44100), closeTo(1000, 5));
  });
}
