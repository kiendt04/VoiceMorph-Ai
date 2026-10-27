import 'dart:io';

import 'package:test/test.dart';
import 'package:voice_core/voice_core.dart';

String presetJson(String id, List<String> nodes, {String controls = '[]'}) =>
    '{ "id": "$id", "names": { "en": "Test" }, "chain": [ ${nodes.join(', ')} ], "controls": $controls }';

EffectPreset parseOne(List<String> nodes, {String controls = '[]'}) =>
    PresetParser.parseLibrary('{ "presets": [ ${presetJson('test', nodes, controls: controls)} ] }')
        .single;

Matcher throwsPresetError([String? containing]) => throwsA(isA<PresetFormatException>()
    .having((e) => e.message, 'message', containing == null ? anything : contains(containing)));

void main() {
  test('default library loads with uniform controls', () {
    final presets = PresetParser.parseLibrary(
        File('assets/presets/default_presets.json').readAsStringSync());

    expect(presets, hasLength(12));
    for (final preset in presets) {
      expect(preset.controls.map((c) => c.key).toSet(), {'pitch', 'speed', 'echo', 'reverb'},
          reason: preset.id);
      expect(preset.name('vi'), isNotEmpty);
    }
  });

  test('missing params fall back to defaults', () {
    final preset = parseOne(['{ "type": "ECHO", "params": { "delayMs": 120 } }']);

    expect(preset.chain[0]['delayMs'], 120);
    expect(preset.chain[0]['feedback'], NodeType.echo.spec('feedback')!.defaultValue);
  });

  test('rejects an unknown effect type', () {
    expect(() => parseOne(['{ "type": "WARP" }']), throwsPresetError('WARP'));
  });

  test('rejects an unknown parameter', () {
    expect(() => parseOne(['{ "type": "ECHO", "params": { "speed": 1 } }']),
        throwsPresetError('speed'));
  });

  test('rejects an out-of-range value', () {
    expect(() => parseOne(['{ "type": "PITCH", "params": { "semitones": 24 } }']),
        throwsPresetError('semitones'));
  });

  test('rejects a non-numeric value', () {
    expect(() => parseOne(['{ "type": "PITCH", "params": { "semitones": "high" } }']),
        throwsPresetError('number'));
  });

  test('rejects a control pointing at a missing node', () {
    expect(
      () => parseOne(['{ "type": "PITCH" }'],
          controls: '[ { "key": "pitch", "node": 3, "param": "semitones" } ]'),
      throwsPresetError('node 3'),
    );
  });

  test('rejects duplicate ids', () {
    final preset = presetJson('a', ['{ "type": "PITCH" }']);
    expect(() => PresetParser.parseLibrary('{ "presets": [ $preset, $preset ] }'),
        throwsPresetError('Duplicate'));
  });

  test('rejects malformed JSON', () {
    expect(() => PresetParser.parseLibrary('{ presets: ['), throwsPresetError());
  });

  test('control values are applied and clamped', () {
    final preset = parseOne(
      ['{ "type": "PITCH", "params": { "semitones": 3 } }'],
      controls: '[ { "key": "pitch", "node": 0, "param": "semitones", "min": -6, "max": 6 } ]',
    );

    expect(preset.defaultControlValues(), {'pitch': 3});
    expect(preset.resolveChain({'pitch': -2})[0]['semitones'], -2);
    expect(preset.resolveChain({'pitch': 11})[0]['semitones'], 6);
    expect(() => preset.resolveChain({'volume': 1}), throwsArgumentError);
  });
}
