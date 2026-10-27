/// Offline voice-changing engine for VoiceMorph.
///
/// Typical use from the app:
/// 1. Load presets: `PresetParser.parseLibrary(await rootBundle.loadString(
///    'packages/voice_core/assets/presets/default_presets.json'))`.
/// 2. Preview: `VoiceChanger().renderPreview(samples, 44100, preset,
///    controlValues: sliders)` (on an isolate, e.g. `Isolate.run`).
/// 3. Save: `RenderJob.start(inputPath:, outputPath:, preset:, controlValues:)`.
library;

export 'src/audio_processor.dart';
export 'src/dsp/resampler.dart' show Resampler;
export 'src/engine/effect_factory.dart';
export 'src/engine/offline_renderer.dart';
export 'src/engine/render_job.dart';
export 'src/engine/voice_changer.dart';
export 'src/io/wav_io.dart';
export 'src/preset/effect_preset.dart';
export 'src/preset/node_type.dart';
export 'src/preset/preset_parser.dart';
