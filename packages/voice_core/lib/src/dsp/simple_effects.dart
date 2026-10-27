import 'dart:math' as math;

import '../audio_processor.dart';
import 'dsp_math.dart';

class Gain extends SampleProcessor {
  Gain(double db) : _gain = dbToLinear(db);

  final double _gain;

  @override
  double processSample(double x) => x * _gain;
}

/// Amplitude modulation by a low-frequency sine; gain swings between 1 and
/// 1 - depth.
class Tremolo extends SampleProcessor {
  Tremolo(int sampleRate, double rateHz, this._depth)
      : _step = 2 * math.pi * rateHz / sampleRate;

  final double _depth;
  final double _step;
  double _phase = 0;

  @override
  double processSample(double x) {
    final gain = 1 - _depth * 0.5 * (1 - math.cos(_phase));
    _phase = (_phase + _step) % (2 * math.pi);
    return x * gain;
  }
}

/// Multiplies the voice by a sine carrier: metallic "robot" at tens of Hz,
/// "alien" at hundreds.
class RingModulator extends SampleProcessor {
  RingModulator(int sampleRate, double freqHz, this._mix)
      : _step = 2 * math.pi * freqHz / sampleRate;

  final double _mix;
  final double _step;
  double _phase = 0;

  @override
  double processSample(double x) {
    final modulated = x * math.sin(_phase);
    _phase = (_phase + _step) % (2 * math.pi);
    return x * (1 - _mix) + modulated * _mix;
  }
}

/// Soft clipping with tanh, normalised so a full-scale input stays at full
/// scale.
class Distortion extends SampleProcessor {
  Distortion(this._drive, this._mix) : _normalization = 1 / tanh(_drive);

  final double _drive;
  final double _mix;
  final double _normalization;

  @override
  double processSample(double x) =>
      x * (1 - _mix) + tanh(_drive * x) * _normalization * _mix;
}
