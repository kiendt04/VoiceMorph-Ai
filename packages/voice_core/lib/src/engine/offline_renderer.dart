import 'dart:math' as math;
import 'dart:typed_data';

import '../audio_processor.dart';
import '../dsp/sample_queue.dart';

class RenderCancelledException implements Exception {
  const RenderCancelledException();

  @override
  String toString() => 'RenderCancelledException: render was cancelled';
}

typedef ProgressCallback = void Function(double progress);
typedef CancelCheck = bool Function();

/// Pushes a whole buffer through a processor block by block, reporting
/// progress.
class OfflineRenderer {
  OfflineRenderer({this.blockSize = 4096}) {
    if (blockSize <= 0) throw ArgumentError.value(blockSize, 'blockSize', 'must be positive');
  }

  /// Flushing tails is the last few percent of the work.
  static const _processShare = 0.98;

  final int blockSize;

  /// [onProgress] is called after each block with a value in 0..1, ending
  /// with exactly 1. [isCancelled] is polled before each block; returning
  /// true aborts with [RenderCancelledException].
  Float32List render(
    Float32List input,
    AudioProcessor processor, {
    ProgressCallback? onProgress,
    CancelCheck? isCancelled,
  }) {
    final output = SampleQueue(input.length + input.length ~/ 4);
    final block = Float32List(blockSize);
    var position = 0;
    while (position < input.length) {
      if (isCancelled?.call() ?? false) throw const RenderCancelledException();
      final frames = math.min(blockSize, input.length - position);
      block.setRange(0, frames, input, position);
      output.addAll(processor.process(block, frames));
      position += frames;
      onProgress?.call(position / input.length * _processShare);
    }
    if (isCancelled?.call() ?? false) throw const RenderCancelledException();
    output.addAll(processor.flush());
    onProgress?.call(1);
    return output.toFloat32List();
  }
}
