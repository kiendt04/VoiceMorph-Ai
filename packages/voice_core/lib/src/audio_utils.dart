import 'dart:math' as math;
import 'dart:typed_data';

/// Small helpers the app UI needs around rendered audio. These do not change
/// the sound of a preset; they only measure it (waveform peaks) or tidy its
/// edges (fades, silence trimming) so recordings do not click or start with
/// dead air.

/// Peak absolute value per bucket, for drawing waveforms. Each bucket covers
/// an equal slice of [samples]; a bucket with no samples reports 0. Returns
/// an empty list for empty input.
Float32List computePeaks(Float32List samples, int bucketCount) {
  if (bucketCount <= 0) {
    throw ArgumentError.value(bucketCount, 'bucketCount', 'must be positive');
  }
  if (samples.isEmpty) return Float32List(0);
  final peaks = Float32List(bucketCount);
  for (var i = 0; i < samples.length; i++) {
    final bucket = math.min(bucketCount - 1, (i * bucketCount) ~/ samples.length);
    final value = samples[i].abs();
    if (value > peaks[bucket]) peaks[bucket] = value;
  }
  return peaks;
}

/// Largest absolute sample, 0 for empty input.
double peakLevel(Float32List samples) {
  var peak = 0.0;
  for (final sample in samples) {
    final value = sample.abs();
    if (value > peak) peak = value;
  }
  return peak;
}

/// A copy of [samples] with linear fades applied at both ends, so playback
/// never starts or stops with a click. Fade lengths are clamped to half the
/// clip; a zero fade leaves that end untouched.
Float32List applyFade(
  Float32List samples, {
  required int sampleRate,
  double fadeInMs = 5,
  double fadeOutMs = 5,
}) {
  if (sampleRate <= 0) {
    throw ArgumentError.value(sampleRate, 'sampleRate', 'must be positive');
  }
  if (samples.isEmpty) return Float32List(0);
  final result = Float32List.fromList(samples);
  final fadeIn = math.min(
    (fadeInMs * sampleRate / 1000).round(),
    result.length ~/ 2,
  );
  final fadeOut = math.min(
    (fadeOutMs * sampleRate / 1000).round(),
    result.length ~/ 2,
  );
  for (var i = 0; i < fadeIn; i++) {
    result[i] = result[i] * (i / fadeIn);
  }
  for (var i = 0; i < fadeOut; i++) {
    final index = result.length - 1 - i;
    result[index] = result[index] * (i / fadeOut);
  }
  return result;
}

/// Trims leading and trailing samples quieter than [threshold], keeping
/// [marginMs] of context on each side so words are not clipped. Returns the
/// original list unchanged when nothing is below the threshold at the edges.
Float32List trimSilence(
  Float32List samples, {
  required int sampleRate,
  double threshold = 1e-3,
  double marginMs = 50,
}) {
  if (sampleRate <= 0) {
    throw ArgumentError.value(sampleRate, 'sampleRate', 'must be positive');
  }
  var start = 0;
  while (start < samples.length && samples[start].abs() < threshold) {
    start++;
  }
  if (start == samples.length) return Float32List(0);
  var end = samples.length;
  while (end > start && samples[end - 1].abs() < threshold) {
    end--;
  }
  final margin = (marginMs * sampleRate / 1000).round();
  start = math.max(0, start - margin);
  end = math.min(samples.length, end + margin);
  return samples.sublist(start, end);
}
