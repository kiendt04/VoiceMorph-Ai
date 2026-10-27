import 'dart:math' as math;
import 'dart:typed_data';

import '../audio_processor.dart';
import 'dsp_math.dart';

/// Feedback delay line. The dry signal is kept at full level; mix sets the
/// echo level.
class Echo extends SampleProcessor {
  Echo(int sampleRate, double delayMs, this._feedback, this._mix)
      : _buffer = Float32List(math.max(1, msToSamples(sampleRate, delayMs))),
        _maxTail = sampleRate * 10;

  final double _feedback;
  final double _mix;
  final Float32List _buffer;
  final int _maxTail;
  int _index = 0;

  /// Repeats needed for the echo to fall below -80 dB, capped at 10 seconds.
  @override
  int get tailSamples {
    final repeats =
        _feedback <= 0 ? 1 : (math.log(1e-4) / math.log(_feedback)).ceil() + 1;
    return math.min(_buffer.length * repeats, _maxTail);
  }

  @override
  double processSample(double x) {
    final delayed = _buffer[_index];
    _buffer[_index] = x + delayed * _feedback;
    _index = (_index + 1) % _buffer.length;
    return x + delayed * _mix;
  }
}
