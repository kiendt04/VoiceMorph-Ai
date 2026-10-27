import 'dart:typed_data';

import 'dsp/dsp_math.dart';

/// A streaming mono audio effect.
///
/// Blocks are pushed in order with [process]; after the last block the caller
/// calls [flush] once to collect whatever the effect still holds (reverb/echo
/// tails, buffered input). Processors are block-based so the same code can
/// later run in a realtime engine.
abstract class AudioProcessor {
  /// Processes the first [frames] samples of [input] (all of it when omitted)
  /// and returns a new list with the produced samples. Its length may differ
  /// from [frames] for effects that change duration.
  Float32List process(Float32List input, [int? frames]);

  /// Returns the remaining output after the last block.
  Float32List flush() => Float32List(0);
}

/// Base for effects that map one input sample to one output sample.
abstract class SampleProcessor extends AudioProcessor {
  static const _silenceThreshold = 1e-4; // -80 dBFS

  /// Maximum number of samples emitted by [flush] for effects with memory
  /// (echo, reverb). Trailing silence in the tail is trimmed.
  int get tailSamples => 0;

  double processSample(double x);

  @override
  Float32List process(Float32List input, [int? frames]) {
    final count = frames ?? input.length;
    final output = Float32List(count);
    for (var i = 0; i < count; i++) {
      output[i] = processSample(input[i]);
    }
    return output;
  }

  @override
  Float32List flush() {
    final length = tailSamples;
    if (length <= 0) return Float32List(0);
    final tail = Float32List(length);
    for (var i = 0; i < length; i++) {
      tail[i] = processSample(0);
    }
    var last = length - 1;
    while (last >= 0 && tail[last].abs() < _silenceThreshold) {
      last--;
    }
    return tail.sublist(0, last + 1);
  }
}

/// Runs processors in series; each stage's flushed tail still passes through
/// the later stages.
class ProcessorChain extends AudioProcessor {
  ProcessorChain(this._stages);

  final List<AudioProcessor> _stages;

  @override
  Float32List process(Float32List input, [int? frames]) {
    final count = frames ?? input.length;
    if (_stages.isEmpty) return input.sublist(0, count);
    var buffer = input;
    var length = count;
    for (final stage in _stages) {
      buffer = stage.process(buffer, length);
      length = buffer.length;
    }
    return buffer;
  }

  @override
  Float32List flush() {
    var carry = Float32List(0);
    for (final stage in _stages) {
      final processed = carry.isEmpty ? carry : stage.process(carry);
      carry = concatSamples([processed, stage.flush()]);
    }
    return carry;
  }
}
