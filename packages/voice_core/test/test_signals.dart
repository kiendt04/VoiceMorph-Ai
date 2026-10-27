import 'dart:math' as math;
import 'dart:typed_data';

import 'package:voice_core/voice_core.dart';

const sampleRate = 44100;

Float32List sine(double freq, double seconds, {double amplitude = 0.5, int rate = sampleRate}) {
  final samples = Float32List((seconds * rate).toInt());
  for (var i = 0; i < samples.length; i++) {
    samples[i] = amplitude * math.sin(2 * math.pi * freq * i / rate);
  }
  return samples;
}

/// Harmonic-rich tone with vibrato, syllable-like envelope and breath noise.
Float32List voiceLike(double seconds) {
  final random = math.Random(42);
  final samples = Float32List((seconds * sampleRate).toInt());
  var phase = 0.0;
  for (var i = 0; i < samples.length; i++) {
    final t = i / sampleRate;
    final f0 = 140 + 8 * math.sin(2 * math.pi * 5 * t);
    phase += 2 * math.pi * f0 / sampleRate;
    var tone = 0.0;
    for (var harmonic = 1; harmonic <= 12; harmonic++) {
      tone += math.sin(harmonic * phase) / harmonic;
    }
    final envelope = 0.5 + 0.5 * math.sin(2 * math.pi * 3 * t);
    samples[i] = 0.3 * envelope * tone + 0.01 * (random.nextDouble() - 0.5);
  }
  return samples;
}

/// Frequency from upward zero crossings over the middle 60% of the signal.
double estimateFrequency(Float32List samples, {int rate = sampleRate}) {
  final from = samples.length ~/ 5;
  final to = samples.length * 4 ~/ 5;
  var first = -1.0;
  var last = -1.0;
  var crossings = 0;
  for (var i = from; i < to - 1; i++) {
    if (samples[i] <= 0 && samples[i + 1] > 0) {
      final time = i + samples[i] / (samples[i] - samples[i + 1]);
      if (first < 0) first = time;
      last = time;
      crossings++;
    }
  }
  return (crossings - 1) * rate / (last - first);
}

double peak(Float32List samples) => samples.fold(0.0, (m, s) => math.max(m, s.abs()));

Float32List runThrough(AudioProcessor processor, Float32List input, {int blockSize = 1024}) {
  final output = <double>[];
  for (var position = 0; position < input.length; position += blockSize) {
    final end = math.min(position + blockSize, input.length);
    output.addAll(processor.process(input.sublist(position, end)));
  }
  output.addAll(processor.flush());
  return Float32List.fromList(output);
}
