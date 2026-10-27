import 'dart:math' as math;
import 'dart:typed_data';

import '../audio_processor.dart';
import 'dsp_math.dart';

/// Look-ahead peak limiter: no output sample exceeds the ceiling.
///
/// The signal is delayed by the look-ahead so the gain can come down before a
/// peak arrives. That delay is compensated internally (the first look-ahead
/// outputs are dropped and [flush] releases the held samples), so output
/// length always equals input length.
class Limiter extends AudioProcessor {
  Limiter(
    int sampleRate, {
    double ceilingDb = -1,
    double lookaheadMs = 5,
    double releaseMs = 80,
  })  : _ceiling = dbToLinear(ceilingDb),
        _lookahead = math.max(1, msToSamples(sampleRate, lookaheadMs)),
        _release = 1 - math.exp(-1 / math.max(1, msToSamples(sampleRate, releaseMs))) {
    _attack = 1 - math.exp(-4 / _lookahead);
    _delay = Float32List(_lookahead);
    _window = _SlidingMax(_lookahead + 1);
  }

  final double _ceiling;
  final int _lookahead;
  final double _release;
  late final double _attack;
  late final Float32List _delay;
  late final _SlidingMax _window;
  int _delayIndex = 0;
  double _gain = 1;
  int _received = 0;

  @override
  Float32List process(Float32List input, [int? frames]) {
    final count = frames ?? input.length;
    final skip = (_lookahead - _received).clamp(0, count).toInt();
    final output = Float32List(count - skip);
    for (var i = 0; i < count; i++) {
      final y = _processSample(input[i]);
      if (i >= skip) output[i - skip] = y;
    }
    _received += count;
    return output;
  }

  @override
  Float32List flush() {
    final outputs = Float32List(_lookahead);
    for (var i = 0; i < _lookahead; i++) {
      outputs[i] = _processSample(0);
    }
    // Inputs shorter than the look-ahead have not yet skipped all the initial
    // delay padding.
    final held = math.min(_received, _lookahead);
    return outputs.sublist(_lookahead - held);
  }

  double _processSample(double x) {
    final peak = _window.push(x.abs());
    final target = peak > _ceiling ? _ceiling / peak : 1.0;
    _gain += (target - _gain) * (target < _gain ? _attack : _release);

    final delayed = _delay[_delayIndex];
    _delay[_delayIndex] = x;
    _delayIndex = (_delayIndex + 1) % _lookahead;

    // The smoothed gain can trail the target by a hair; never let that through.
    return (delayed * _gain).clamp(-_ceiling, _ceiling).toDouble();
  }
}

/// Maximum of the last [size] values in O(1) amortised time (monotonic deque).
class _SlidingMax {
  _SlidingMax(this._size)
      : _capacity = _size + 1,
        _values = Float64List(_size + 1),
        _positions = List<int>.filled(_size + 1, 0);

  final int _size;
  final int _capacity;
  final Float64List _values;
  final List<int> _positions;
  int _head = 0;
  int _count = 0;
  int _position = 0;

  double push(double value) {
    while (_count > 0 && _values[(_head + _count - 1) % _capacity] <= value) {
      _count--;
    }
    final slot = (_head + _count) % _capacity;
    _values[slot] = value;
    _positions[slot] = _position;
    _count++;
    while (_positions[_head] <= _position - _size) {
      _head = (_head + 1) % _capacity;
      _count--;
    }
    _position++;
    return _values[_head];
  }
}
