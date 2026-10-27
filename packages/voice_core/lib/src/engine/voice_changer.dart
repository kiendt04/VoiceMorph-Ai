import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import '../io/wav_io.dart';
import '../preset/effect_preset.dart';
import 'effect_factory.dart';
import 'offline_renderer.dart';

/// Entry point of the voice-changing core: applies a preset (plus the user's
/// slider values) to mono audio.
///
/// Everything here is synchronous and CPU-bound. In the app, run it off the
/// UI isolate — [RenderJob] does that for whole files.
class VoiceChanger {
  VoiceChanger({OfflineRenderer? renderer}) : _renderer = renderer ?? OfflineRenderer();

  static const defaultPreviewSeconds = 10.0;

  final OfflineRenderer _renderer;

  Float32List render(
    Float32List audio,
    int sampleRate,
    EffectPreset preset, {
    Map<String, double> controlValues = const {},
    ProgressCallback? onProgress,
    CancelCheck? isCancelled,
  }) {
    final chain = EffectFactory.createChain(preset.resolveChain(controlValues), sampleRate);
    return _renderer.render(audio, chain, onProgress: onProgress, isCancelled: isCancelled);
  }

  /// Fast render of only the first [maxSeconds] for previewing while the user
  /// adjusts sliders.
  Float32List renderPreview(
    Float32List audio,
    int sampleRate,
    EffectPreset preset, {
    Map<String, double> controlValues = const {},
    double maxSeconds = defaultPreviewSeconds,
    CancelCheck? isCancelled,
  }) {
    final frames = math.min(audio.length, (maxSeconds * sampleRate).toInt());
    return render(audio.sublist(0, frames), sampleRate, preset,
        controlValues: controlValues, isCancelled: isCancelled);
  }

  /// Renders a WAV file into a 16-bit mono WAV. The result is written to
  /// [tempPathFor] and moved into place only on success, so a failed or
  /// cancelled render never leaves a partial [outputPath] behind.
  void renderFile(
    String inputPath,
    String outputPath,
    EffectPreset preset, {
    Map<String, double> controlValues = const {},
    ProgressCallback? onProgress,
    CancelCheck? isCancelled,
  }) {
    final source = WavIO.readFile(inputPath);
    final rendered = render(source.samples, source.sampleRate, preset,
        controlValues: controlValues, onProgress: onProgress, isCancelled: isCancelled);
    final temp = File(tempPathFor(outputPath));
    try {
      WavIO.writeFile(temp.path, rendered, source.sampleRate);
      temp.renameSync(outputPath);
    } finally {
      if (temp.existsSync()) temp.deleteSync();
    }
  }

  static String tempPathFor(String outputPath) => '$outputPath.tmp';
}
