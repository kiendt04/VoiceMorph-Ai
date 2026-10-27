import 'dart:math' as math;
import 'dart:typed_data';

import '../audio_processor.dart';

/// Mono Freeverb (Schroeder/Moorer): 8 parallel damped comb filters followed
/// by 4 series all-pass filters. Delay lengths are the original 44.1 kHz
/// tunings scaled to the sample rate.
class Reverb extends SampleProcessor {
  Reverb(int sampleRate, double roomSize, double damping, this._mix)
      : _tail = sampleRate * 4 {
    final scale = sampleRate / 44100;
    int scaled(int samples) => math.max(1, (samples * scale).toInt());
    _combs = [
      for (final tuning in _combTunings)
        _Comb(scaled(tuning), roomSize * _scaleRoom + _offsetRoom, damping * _scaleDamp),
    ];
    _allPasses = [for (final tuning in _allPassTunings) _AllPass(scaled(tuning))];
  }

  static const _combTunings = [1116, 1188, 1277, 1356, 1422, 1491, 1557, 1617];
  static const _allPassTunings = [556, 441, 341, 225];
  static const _fixedGain = 0.015;
  static const _scaleRoom = 0.28;
  static const _offsetRoom = 0.7;
  static const _scaleDamp = 0.4;
  static const _wetScale = 3.0;

  final double _mix;
  final int _tail;
  late final List<_Comb> _combs;
  late final List<_AllPass> _allPasses;

  @override
  int get tailSamples => _tail;

  @override
  double processSample(double x) {
    final input = x * _fixedGain;
    var wet = 0.0;
    for (final comb in _combs) {
      wet += comb.process(input);
    }
    for (final allPass in _allPasses) {
      wet = allPass.process(wet);
    }
    return x * (1 - _mix) + wet * _wetScale * _mix;
  }
}

class _Comb {
  _Comb(int size, this._feedback, this._damp) : _buffer = Float32List(size);

  final double _feedback;
  final double _damp;
  final Float32List _buffer;
  int _index = 0;
  double _store = 0;

  double process(double input) {
    final output = _buffer[_index];
    _store = output * (1 - _damp) + _store * _damp;
    _buffer[_index] = input + _store * _feedback;
    _index = (_index + 1) % _buffer.length;
    return output;
  }
}

class _AllPass {
  _AllPass(int size) : _buffer = Float32List(size);

  final Float32List _buffer;
  int _index = 0;

  double process(double input) {
    final buffered = _buffer[_index];
    _buffer[_index] = input + buffered * 0.5;
    _index = (_index + 1) % _buffer.length;
    return buffered - input;
  }
}
