import 'dart:typed_data';

import '../audio_processor.dart';
import 'biquad.dart';
import 'dsp_math.dart';
import 'sample_queue.dart';

/// Streaming linear-interpolation resampler. The rate is the number of input
/// samples consumed per output sample: 2.0 halves the length (and doubles the
/// pitch when played at the same rate).
///
/// It does not filter; put a low-pass in front when the rate is above 1 (see
/// [Resampler.antiAliased]).
class Resampler extends AudioProcessor {
  Resampler(this._rate) {
    if (_rate <= 0) throw ArgumentError.value(_rate, 'rate', 'must be positive');
  }

  /// Resampler preceded by a 4th-order low-pass when it decimates.
  static AudioProcessor antiAliased(int sampleRate, double rate) {
    if (rate <= 1) return Resampler(rate);
    final cutoff = 0.45 * sampleRate / rate;
    return ProcessorChain([
      Biquad.lowPass(sampleRate, cutoff),
      Biquad.lowPass(sampleRate, cutoff),
      Resampler(rate),
    ]);
  }

  /// Converts a whole buffer between sample rates (e.g. imported 48 kHz audio
  /// to 44.1 kHz).
  static Float32List convert(Float32List samples, int fromRate, int toRate) {
    if (fromRate == toRate) return Float32List.fromList(samples);
    final resampler = antiAliased(fromRate, fromRate / toRate);
    return concatSamples([resampler.process(samples), resampler.flush()]);
  }

  final double _rate;
  double _position = 0;
  int _blockStart = 0;
  double _previous = 0;
  int _produced = 0;

  @override
  Float32List process(Float32List input, [int? frames]) {
    final count = frames ?? input.length;
    final output = SampleQueue(count ~/ _rate + 2);
    final end = _blockStart + count;
    while (true) {
      final index = _position.floor();
      if (index + 1 >= end) break;
      final a = _sampleAt(input, index);
      final b = _sampleAt(input, index + 1);
      output.add(a + (b - a) * (_position - index));
      _position += _rate;
    }
    if (count > 0) _previous = input[count - 1];
    _blockStart = end;
    _produced += output.length;
    return output.toFloat32List();
  }

  /// Emits the last outputs by holding the final sample, so the length is
  /// ceil(input / rate).
  @override
  Float32List flush() {
    final expected = (_blockStart / _rate).ceil();
    final tail = process(Float32List.fromList([_previous]));
    final keep = (expected - (_produced - tail.length)).clamp(0, tail.length).toInt();
    return tail.sublist(0, keep);
  }

  /// Every index reaching here is >= blockStart - 1, which is the held
  /// previous sample.
  double _sampleAt(Float32List input, int index) =>
      index < _blockStart ? _previous : input[index - _blockStart];
}
