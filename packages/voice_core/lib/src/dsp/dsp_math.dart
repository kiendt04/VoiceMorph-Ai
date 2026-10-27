import 'dart:math' as math;
import 'dart:typed_data';

double dbToLinear(double db) => math.pow(10, db / 20).toDouble();

int msToSamples(int sampleRate, double ms) => (sampleRate * ms / 1000).round();

/// Q giving a maximally flat (Butterworth) 2nd-order response.
const butterworthQ = 0.7071;

/// dart:math has no tanh; clamped so exp() cannot overflow.
double tanh(double x) {
  if (x > 20) return 1;
  if (x < -20) return -1;
  final e = math.exp(2 * x);
  return (e - 1) / (e + 1);
}

Float32List concatSamples(List<Float32List> parts) {
  if (parts.length == 1) return parts.first;
  var length = 0;
  for (final part in parts) {
    length += part.length;
  }
  final result = Float32List(length);
  var offset = 0;
  for (final part in parts) {
    result.setRange(offset, offset + part.length, part);
    offset += part.length;
  }
  return result;
}
