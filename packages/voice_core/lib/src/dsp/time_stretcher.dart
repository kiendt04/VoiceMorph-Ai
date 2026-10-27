import 'dart:math' as math;
import 'dart:typed_data';

import '../audio_processor.dart';
import 'dsp_math.dart';
import 'sample_queue.dart';

/// Changes speed without changing pitch using WSOLA (waveform-similarity
/// overlap-add), the same scheme SoundTouch uses: the input is cut into ~40 ms
/// sequences, and each new sequence starts at the offset (within a 15 ms seek
/// window) whose waveform best matches the end of the previous one, so the
/// 8 ms crossfades don't smear the pitch period.
///
/// A tempo above 1 speeds up (shorter output), below 1 slows down.
class TimeStretcher extends AudioProcessor {
  TimeStretcher(int sampleRate, this._tempo)
      : _sequence = msToSamples(sampleRate, _sequenceMs),
        _seek = math.max(1, msToSamples(sampleRate, _seekMs)),
        _overlap = math.max(1, msToSamples(sampleRate, _overlapMs)) {
    if (_tempo <= 0) throw ArgumentError.value(_tempo, 'tempo', 'must be positive');
    _nominalSkip = _tempo * (_sequence - _overlap);
    _required = math.max(_nominalSkip.toInt() + _overlap, _sequence) + _seek;
    _previousTail = Float32List(_overlap);
  }

  static const _sequenceMs = 40.0;
  static const _seekMs = 15.0;
  static const _overlapMs = 8.0;
  static const _coarseStep = 4;

  final double _tempo;
  final int _sequence;
  final int _seek;
  final int _overlap;
  late final double _nominalSkip;
  late final int _required;
  late final Float32List _previousTail;

  final _input = SampleQueue();
  bool _started = false;
  double _skipFraction = 0;
  int _totalIn = 0;
  int _totalOut = 0;

  @override
  Float32List process(Float32List input, [int? frames]) {
    final count = frames ?? input.length;
    _input.addAll(input, 0, count);
    _totalIn += count;
    final output = SampleQueue();
    _stretch(output);
    _totalOut += output.length;
    return output.toFloat32List();
  }

  /// Pads with silence until the output covers all input, then trims to the
  /// exact length.
  @override
  Float32List flush() {
    final expected = (_totalIn / _tempo).round();
    final output = SampleQueue();
    final silence = Float32List(_required);
    while (_totalOut + output.length < expected) {
      _input.addAll(silence);
      _stretch(output);
    }
    final keep = (expected - _totalOut).clamp(0, output.length).toInt();
    _totalOut += keep;
    return output.toFloat32List().sublist(0, keep);
  }

  void _stretch(SampleQueue output) {
    while (_input.length >= _required) {
      final buffer = _input.buffer;
      final base = _input.offset;
      if (!_started) {
        // Nothing to match against yet: start exactly at the first sample.
        _previousTail.setRange(0, _overlap, buffer, base);
        _started = true;
      }
      final start = base + _bestOffset(buffer, base);

      for (var i = 0; i < _overlap; i++) {
        final t = i / _overlap;
        output.add(_previousTail[i] * (1 - t) + buffer[start + i] * t);
      }
      output.addAll(buffer, start + _overlap, _sequence - 2 * _overlap);
      _previousTail.setRange(0, _overlap, buffer, start + _sequence - _overlap);

      _skipFraction += _nominalSkip;
      final skip = _skipFraction.toInt();
      _skipFraction -= skip;
      _input.drop(skip);
    }
  }

  /// Coarse search on every 4th offset/sample, then a full-resolution search
  /// around the winner.
  int _bestOffset(Float32List buffer, int base) {
    var best = 0;
    var bestScore = double.negativeInfinity;
    for (var offset = 0; offset < _seek; offset += _coarseStep) {
      final score = _similarity(buffer, base + offset, _coarseStep);
      if (score > bestScore) {
        bestScore = score;
        best = offset;
      }
    }

    final from = math.max(0, best - _coarseStep + 1);
    final to = math.min(_seek - 1, best + _coarseStep - 1);
    bestScore = double.negativeInfinity;
    for (var candidate = from; candidate <= to; candidate++) {
      final score = _similarity(buffer, base + candidate, 1);
      if (score > bestScore) {
        bestScore = score;
        best = candidate;
      }
    }
    return best;
  }

  /// Cross-correlation with the previous tail, normalised by the candidate's
  /// energy.
  double _similarity(Float32List buffer, int position, int step) {
    var correlation = 0.0;
    var energy = 0.0;
    for (var i = 0; i < _overlap; i += step) {
      final value = buffer[position + i];
      correlation += _previousTail[i] * value;
      energy += value * value;
    }
    return energy > 1e-12 ? correlation / math.sqrt(energy) : 0;
  }
}
