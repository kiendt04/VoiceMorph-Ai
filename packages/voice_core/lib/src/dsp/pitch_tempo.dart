import 'dart:math' as math;
import 'dart:typed_data';

import '../audio_processor.dart';
import 'resampler.dart';
import 'time_stretcher.dart';

/// Independent pitch and speed change.
///
/// Pitch is shifted by time-stretching by the pitch ratio and then resampling
/// back to the original duration. Formants move together with the pitch (the
/// "chipmunk" character at large shifts); formant-preserving shifting needs a
/// vocoder and is not part of this engine yet.
class PitchTempo extends AudioProcessor {
  PitchTempo(int sampleRate, double semitones, this._tempo) {
    if (_tempo <= 0) throw ArgumentError.value(_tempo, 'tempo', 'must be positive');
    final pitchRatio = math.pow(2, semitones / 12).toDouble();
    final stretchTempo = _tempo / pitchRatio;
    _chain = ProcessorChain([
      if (stretchTempo != 1) TimeStretcher(sampleRate, stretchTempo),
      if (pitchRatio != 1) Resampler.antiAliased(sampleRate, pitchRatio),
    ]);
  }

  final double _tempo;
  late final AudioProcessor _chain;
  int _totalIn = 0;
  int _produced = 0;

  @override
  Float32List process(Float32List input, [int? frames]) {
    final count = frames ?? input.length;
    _totalIn += count;
    final output = _chain.process(input, count);
    _produced += output.length;
    return output;
  }

  /// Stretching and resampling each round once; settle the total at exactly
  /// input / tempo.
  @override
  Float32List flush() {
    final tail = _chain.flush();
    final keep = math.max(0, (_totalIn / _tempo).round() - _produced);
    if (keep <= tail.length) return tail.sublist(0, keep);
    return Float32List(keep)..setRange(0, tail.length, tail);
  }
}
