import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:voice_core/src/dsp/biquad.dart';
import 'package:voice_core/src/dsp/dsp_math.dart';
import 'package:voice_core/src/dsp/echo.dart';
import 'package:voice_core/src/dsp/limiter.dart';
import 'package:voice_core/src/dsp/reverb.dart';
import 'package:voice_core/src/dsp/simple_effects.dart';

import 'test_signals.dart';

void main() {
  test('low-pass keeps low and cuts high frequencies', () {
    final low = runThrough(Biquad.lowPass(sampleRate, 1000), sine(200, 0.5));
    final high = runThrough(Biquad.lowPass(sampleRate, 1000), sine(10000, 0.5));

    expect(peak(low.sublist(2000)), closeTo(0.5, 0.02));
    expect(peak(high.sublist(2000)), lessThan(0.01), reason: '10 kHz should be ~40 dB down');
  });

  test('echo repeats an impulse after the delay and keeps a tail', () {
    final impulse = Float32List(1000)..[0] = 1;
    final output = runThrough(Echo(sampleRate, 100, 0.5, 0.5), impulse);
    const delay = sampleRate ~/ 10;

    expect(output[0], closeTo(1, 1e-6));
    expect(output[delay], closeTo(0.5, 1e-6));
    expect(output[2 * delay], closeTo(0.25, 1e-6));
    expect(output.length, greaterThan(3 * delay));
  });

  test('reverb tail is finite and decays', () {
    final impulse = Float32List(1000)..[0] = 1;
    final output = runThrough(Reverb(sampleRate, 0.8, 0.3, 0.5), impulse);

    expect(output.every((s) => s.isFinite), isTrue);
    expect(output.length, greaterThan(sampleRate ~/ 2));
    expect(peak(output.sublist(output.length - 1000)), lessThan(1e-3));
  });

  test('limiter never exceeds the ceiling and keeps length', () {
    final loud = sine(440, 1, amplitude: 3);
    final output = runThrough(Limiter(sampleRate, ceilingDb: -1), loud, blockSize: 777);

    expect(output.length, loud.length);
    expect(peak(output), lessThanOrEqualTo(dbToLinear(-1) + 1e-6));
  });

  test('limiter leaves a quiet signal untouched', () {
    final quiet = sine(440, 0.5, amplitude: 0.2);
    final output = runThrough(Limiter(sampleRate), quiet);

    expect(output.length, quiet.length);
    for (var i = 0; i < quiet.length; i++) {
      expect(output[i], closeTo(quiet[i], 1e-6));
    }
  });

  test('limiter handles input shorter than its look-ahead', () {
    final input = Float32List.fromList([0.1, -0.2, 0.3]);
    expect(runThrough(Limiter(sampleRate), input), input);
  });

  test('distortion stays within full scale', () {
    final output = runThrough(Distortion(20, 1), sine(200, 0.2, amplitude: 1));
    expect(output.every((s) => s.abs() <= 1 + 1e-6), isTrue);
  });
}
