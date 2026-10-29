# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

VoiceMorph is an offline Flutter app for Android and iOS that changes voices with DSP effects. The product spec, covering MVP scope, monetization, architecture, and the packages it plans to use, is in [00-app-overview.md](00-app-overview.md). It is written in Vietnamese, and the user works in Vietnamese.

Current state:
- **All working logic is in `packages/voice_core`.** It is a pure Dart package with no Flutter dependency. The only Flutter-specific piece is the `flutter: assets:` entry in its pubspec.
- The Flutter app (`lib/main.dart`, `test/widget_test.dart`) is still the counter template.
- The platform audio layer (recording, MP3/M4A decode, playback, MP3/AAC export) and app state (Riverpod, go_router, storage) are not built yet.

## Commands

Run the core package's commands from `packages/voice_core`. The tests load `assets/presets/default_presets.json` by relative path, so they fail when run from anywhere else.

```sh
cd packages/voice_core
dart pub get
dart analyze
dart test                                   # all tests
dart test test/voice_changer_test.dart      # one file
dart test --name "renderFile"               # tests whose name matches
```

App (repo root): `flutter pub get`, `flutter analyze`, `flutter test`, `flutter run`.

`voice_changer_test.dart` contains a timing test that requires rendering 60 s of audio in under 5 s. Desktop JIT is only a rough proxy for that target, which is defined for a mid-range phone.

## voice_core architecture

How the pipeline fits together:

1. **Presets are data, not code.**
   - `assets/presets/default_presets.json` defines each preset as a `chain` of effect nodes plus `controls`.
   - Each control is a UI slider key (`pitch`, `speed`, `echo`, `reverb`) bound to a `node` index and a `param`.
   - `PresetParser` validates strictly. Every param is range-checked against `NodeType`'s `ParamSpec`s in `preset/node_type.dart`, which is the single source of truth for allowed node types and parameter ranges.
   - The `speed` control binds to the PITCH node's `tempo` param, because pitch and tempo are one processor.
   - `isPro` marks paid presets. The core does not enforce it; gating is the app's job.
2. **`EffectPreset.resolveChain(controlValues)`** applies slider values to the node list.
3. **`EffectFactory.createChain`** turns nodes into `AudioProcessor`s.
   - It skips no-op nodes (mix 0, gain 0 dB, pitch 0 with tempo 1).
   - It always appends a `Limiter` at -1 dBFS unless the chain already ends with one, so output never clips.
   - **Adding a new effect** touches three places: a `NodeType` entry with its params, a processor in `dsp/`, and a case in `EffectFactory.create`.
4. **`AudioProcessor`** (`audio_processor.dart`) is block-based and streaming: `process(block)`, then a single `flush()` call for tails such as echo and reverb.
   - The block-based design is intentional, so the same processors can later drive a realtime engine.
   - An effect that changes duration (`PitchTempo`) may return a different number of samples than it receives.
   - `SampleProcessor` handles 1:1 effects and trims silent tails.
5. **`OfflineRenderer`** feeds blocks of 4096 samples and reports progress and cancellation through callbacks.
6. **`VoiceChanger`** is the public API.
   - `render`: renders the whole input.
   - `renderPreview`: renders only the first 10 s, for live slider tweaking.
   - `renderFile`: reads a WAV, renders it, then writes to `<out>.tmp` and renames, so a failed or cancelled render never leaves partial output.
7. **`RenderJob`** runs `renderFile` on a separate isolate. It exposes a progress stream, `cancel()`, and a `done` future that rethrows the isolate's typed exceptions (`WavFormatException`, `RenderCancelledException`).

Other parts:
- **`WavIO`** reads PCM 8/16/24/32-bit, float32, and WAVE_FORMAT_EXTENSIBLE files, downmixing to mono `Float32List`. It writes 16-bit PCM mono only. Other formats (MP3, M4A) must be decoded to WAV by the app before they reach the core.
- **`PitchTempo`** combines WSOLA time-stretching (`time_stretcher.dart`) with an anti-aliased resampler. Formants shift along with pitch. There is no separate formant control yet, although the spec calls for one.
- **`audio_utils.dart`** provides helpers for the app: waveform `computePeaks`, `peakLevel`, `applyFade`, `trimSilence`. These are not wired into the render pipeline.
- `voice_core.dart` is the only public entry point. Anything not exported there is internal.

Tests build synthetic audio with `test/test_signals.dart` (`sine`, `voiceLike`). Samples are `Float32List`, so compare computed values with `closeTo` rather than exact equality.

Record user-visible core changes in `packages/voice_core/CHANGELOG.md`.
