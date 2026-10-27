import 'dart:math' as math;

import '../audio_processor.dart';
import 'dsp_math.dart';

/// Second-order IIR filter (transposed direct form II) with coefficients from
/// the RBJ Audio EQ Cookbook.
class Biquad extends SampleProcessor {
  Biquad._(this._b0, this._b1, this._b2, this._a1, this._a2);

  factory Biquad._normalized(
    double b0, double b1, double b2, double a0, double a1, double a2) =>
      Biquad._(b0 / a0, b1 / a0, b2 / a0, a1 / a0, a2 / a0);

  factory Biquad.lowPass(int sampleRate, double freq, [double q = butterworthQ]) {
    final (cosW, alpha) = _shape(sampleRate, freq, q);
    return Biquad._normalized(
      (1 - cosW) / 2, 1 - cosW, (1 - cosW) / 2,
      1 + alpha, -2 * cosW, 1 - alpha,
    );
  }

  factory Biquad.highPass(int sampleRate, double freq, [double q = butterworthQ]) {
    final (cosW, alpha) = _shape(sampleRate, freq, q);
    return Biquad._normalized(
      (1 + cosW) / 2, -(1 + cosW), (1 + cosW) / 2,
      1 + alpha, -2 * cosW, 1 - alpha,
    );
  }

  /// Band-pass with 0 dB gain at the centre frequency.
  factory Biquad.bandPass(int sampleRate, double freq, double q) {
    final (cosW, alpha) = _shape(sampleRate, freq, q);
    return Biquad._normalized(alpha, 0, -alpha, 1 + alpha, -2 * cosW, 1 - alpha);
  }

  factory Biquad.peaking(int sampleRate, double freq, double gainDb, double q) {
    final (cosW, alpha) = _shape(sampleRate, freq, q);
    final a = math.pow(10, gainDb / 40).toDouble();
    return Biquad._normalized(
      1 + alpha * a, -2 * cosW, 1 - alpha * a,
      1 + alpha / a, -2 * cosW, 1 - alpha / a,
    );
  }

  factory Biquad.lowShelf(int sampleRate, double freq, double gainDb) {
    final (cosW, alpha) = _shape(sampleRate, freq, butterworthQ);
    final a = math.pow(10, gainDb / 40).toDouble();
    final k = 2 * math.sqrt(a) * alpha;
    return Biquad._normalized(
      a * ((a + 1) - (a - 1) * cosW + k),
      2 * a * ((a - 1) - (a + 1) * cosW),
      a * ((a + 1) - (a - 1) * cosW - k),
      (a + 1) + (a - 1) * cosW + k,
      -2 * ((a - 1) + (a + 1) * cosW),
      (a + 1) + (a - 1) * cosW - k,
    );
  }

  factory Biquad.highShelf(int sampleRate, double freq, double gainDb) {
    final (cosW, alpha) = _shape(sampleRate, freq, butterworthQ);
    final a = math.pow(10, gainDb / 40).toDouble();
    final k = 2 * math.sqrt(a) * alpha;
    return Biquad._normalized(
      a * ((a + 1) + (a - 1) * cosW + k),
      -2 * a * ((a - 1) + (a + 1) * cosW),
      a * ((a + 1) + (a - 1) * cosW - k),
      (a + 1) - (a - 1) * cosW + k,
      2 * ((a - 1) - (a + 1) * cosW),
      (a + 1) - (a - 1) * cosW - k,
    );
  }

  final double _b0, _b1, _b2, _a1, _a2;
  double _z1 = 0;
  double _z2 = 0;

  @override
  double processSample(double x) {
    final y = _b0 * x + _z1;
    _z1 = _b1 * x - _a1 * y + _z2;
    _z2 = _b2 * x - _a2 * y;
    return y;
  }

  /// Returns cos(w0) and alpha; the frequency is kept below Nyquist.
  static (double, double) _shape(int sampleRate, double freq, double q) {
    final safeFreq = freq.clamp(1.0, sampleRate * 0.49).toDouble();
    final w0 = 2 * math.pi * safeFreq / sampleRate;
    return (math.cos(w0), math.sin(w0) / (2 * q));
  }
}
