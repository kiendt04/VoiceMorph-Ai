import 'dart:io';
import 'dart:math' as math;

import 'package:test/test.dart';
import 'package:voice_core/voice_core.dart';

import 'test_signals.dart';

void main() {
  final presets = PresetParser.parseLibrary(
      File('assets/presets/default_presets.json').readAsStringSync());
  EffectPreset preset(String id) => presets.firstWhere((p) => p.id == id);
  final changer = VoiceChanger();
  final ceiling = math.pow(10, -1 / 20);

  late Directory folder;
  setUp(() => folder = Directory.systemTemp.createTempSync('voice_core_test'));
  tearDown(() => folder.deleteSync(recursive: true));

  test('every default preset produces clean audio', () {
    final input = voiceLike(3);
    for (final p in presets) {
      final output = changer.render(input, sampleRate, p);
      final tempo = p.chain.first['tempo'];

      expect(output.every((s) => s.isFinite), isTrue, reason: p.id);
      expect(peak(output), lessThanOrEqualTo(ceiling + 1e-6), reason: '${p.id} clips');
      expect(output.length, greaterThanOrEqualTo(input.length ~/ tempo - 1), reason: '${p.id} too short');
      expect(peak(output), greaterThan(0.05), reason: '${p.id} is silent');
    }
  });

  test('user controls change the result', () {
    final input = voiceLike(1);
    final dry = changer.render(input, sampleRate, preset('cave'),
        controlValues: {'echo': 0, 'reverb': 0});
    final wet = changer.render(input, sampleRate, preset('cave'));

    expect(dry.length, input.length);
    expect(wet.length, greaterThan(dry.length), reason: 'echo and reverb add a tail');
  });

  test('preview only renders the first seconds', () {
    final output = changer.renderPreview(voiceLike(15), sampleRate, preset('chipmunk'), maxSeconds: 2);
    expect(output.length, closeTo(2 * sampleRate / 1.1, 1));
  });

  test('progress is monotonic and ends at 1', () {
    final progress = <double>[];
    changer.render(voiceLike(1), sampleRate, presets.first, onProgress: progress.add);

    expect(progress.last, 1);
    expect(progress, orderedEquals([...progress]..sort()));
  });

  test('cancellation aborts the render', () {
    var polls = 0;
    expect(
      () => changer.render(voiceLike(2), sampleRate, presets.first, isCancelled: () => ++polls > 3),
      throwsA(isA<RenderCancelledException>()),
    );
  });

  test('renderFile writes a WAV and leaves no temp file', () {
    final input = '${folder.path}/original.wav';
    final output = '${folder.path}/render.wav';
    WavIO.writeFile(input, voiceLike(1), sampleRate);

    changer.renderFile(input, output, preset('robot'));

    final result = WavIO.readFile(output);
    expect(result.sampleRate, sampleRate);
    expect(result.samples.length, greaterThanOrEqualTo(sampleRate));
    expect(File(VoiceChanger.tempPathFor(output)).existsSync(), isFalse);
  });

  test('renderFile replaces an existing output and validates the rate', () {
    final input = '${folder.path}/original.wav';
    final output = '${folder.path}/nested/render.wav';
    WavIO.writeFile(input, voiceLike(1), sampleRate);

    changer.renderFile(input, output, preset('robot'));
    expect(File(output).existsSync(), isTrue);
    // A second render over the same path must replace it, not fail.
    changer.renderFile(input, output, preset('robot'));
    expect(WavIO.readFile(output).samples.length, greaterThanOrEqualTo(sampleRate));
    expect(File(VoiceChanger.tempPathFor(output)).existsSync(), isFalse);

    expect(() => changer.render(Float32List(0), 0, presets.first), throwsArgumentError);
  });

  test('cancelled file render leaves no output', () {
    final input = '${folder.path}/original.wav';
    final output = '${folder.path}/render.wav';
    WavIO.writeFile(input, voiceLike(1), sampleRate);

    expect(() => changer.renderFile(input, output, presets.first, isCancelled: () => true),
        throwsA(isA<RenderCancelledException>()));
    expect(File(output).existsSync(), isFalse);
  });

  test('RenderJob renders on a background isolate with progress', () async {
    final input = '${folder.path}/original.wav';
    final output = '${folder.path}/render.wav';
    WavIO.writeFile(input, voiceLike(2), sampleRate);

    final job = await RenderJob.start(inputPath: input, outputPath: output, preset: preset('ghost'));
    final progress = <double>[];
    job.progress.listen(progress.add);
    await job.done;

    expect(progress, isNotEmpty);
    expect(progress.last, 1);
    expect(WavIO.readFile(output).samples.length, greaterThan(2 * sampleRate));
  });

  test('RenderJob reports failures from the isolate', () async {
    final input = '${folder.path}/not_a_wav.wav';
    File(input).writeAsStringSync('ID3 this is an mp3');

    final job = await RenderJob.start(
        inputPath: input, outputPath: '${folder.path}/render.wav', preset: presets.first);
    await expectLater(job.done, throwsA(isA<WavFormatException>()));
  });

  test('RenderJob cancel stops the isolate and leaves no output', () async {
    final input = '${folder.path}/original.wav';
    final output = '${folder.path}/render.wav';
    WavIO.writeFile(input, voiceLike(60), sampleRate);

    final job = await RenderJob.start(inputPath: input, outputPath: output, preset: preset('ghost'));
    await job.progress.first;
    job.cancel();

    await expectLater(job.done, throwsA(isA<RenderCancelledException>()));
    expect(File(output).existsSync(), isFalse);
    expect(File(VoiceChanger.tempPathFor(output)).existsSync(), isFalse);
  });

  // Target from the spec: a 1-minute clip in under 5 s on a mid-range phone.
  // Desktop JIT is only a rough proxy; measure on devices too.
  test('one minute renders quickly', () {
    final input = voiceLike(60);
    changer.render(input.sublist(0, sampleRate), sampleRate, presets.first); // warm-up
    for (final id in ['ghost', 'chipmunk', 'monster']) {
      final watch = Stopwatch()..start();
      changer.render(input, sampleRate, preset(id));
      print('Render 60 s with $id: ${watch.elapsedMilliseconds} ms');
      expect(watch.elapsedMilliseconds, lessThan(5000), reason: id);
    }
  });
}
