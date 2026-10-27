import 'dart:convert';

import 'effect_preset.dart';
import 'node_type.dart';

class PresetFormatException extends FormatException {
  const PresetFormatException(super.message);
}

/// Parses and validates a preset library:
///
/// ```json
/// { "presets": [ {
///     "id": "cave", "names": { "vi": "Hang động", "en": "Cave" }, "category": "place",
///     "isPro": false, "version": 1,
///     "chain": [ { "type": "ECHO", "params": { "delayMs": 280 } } ],
///     "controls": [ { "key": "echo", "node": 0, "param": "mix", "min": 0, "max": 1 } ]
/// } ] }
/// ```
///
/// Every mistake (unknown effect or parameter, value out of range, dangling
/// control) is rejected with a message naming the preset and field, so a bad
/// preset never reaches the engine.
abstract final class PresetParser {
  static List<EffectPreset> parseLibrary(String json) {
    final Object? root;
    try {
      root = jsonDecode(json);
    } on FormatException catch (e) {
      throw PresetFormatException('Invalid preset JSON: ${e.message}');
    }
    final list = root is Map<String, dynamic> ? root['presets'] : null;
    if (list is! List) throw const PresetFormatException('Missing "presets" array');

    final presets = [for (final item in list) parsePreset(_object(item, '?', 'preset'))];
    final ids = <String>{};
    for (final preset in presets) {
      if (!ids.add(preset.id)) throw PresetFormatException('Duplicate preset id "${preset.id}"');
    }
    return presets;
  }

  static EffectPreset parsePreset(Map<String, dynamic> json) {
    final id = json['id'];
    if (id is! String || id.trim().isEmpty) {
      throw const PresetFormatException('Preset id is missing or blank');
    }

    final namesJson = _object(json['names'], id, 'names');
    final names = <String, String>{};
    namesJson.forEach((language, name) {
      if (name is! String) _fail(id, 'names.$language must be a string');
      names[language] = name;
    });
    if (names.isEmpty) _fail(id, 'names is empty');

    final chainJson = _list(json['chain'], id, 'chain');
    if (chainJson.isEmpty) _fail(id, 'chain is empty');
    final chain = [
      for (var i = 0; i < chainJson.length; i++)
        _parseNode(id, i, _object(chainJson[i], id, 'chain[$i]')),
    ];

    final controlsJson = json['controls'] == null ? const [] : _list(json['controls'], id, 'controls');
    final controls = [
      for (final item in controlsJson) _parseControl(id, chain, _object(item, id, 'control')),
    ];
    final keys = <String>{};
    for (final control in controls) {
      if (!keys.add(control.key)) _fail(id, 'duplicate control "${control.key}"');
    }

    return EffectPreset(
      id: id,
      names: names,
      category: _optional<String>(json, 'category', id) ?? 'other',
      isPro: _optional<bool>(json, 'isPro', id) ?? false,
      version: _optional<int>(json, 'version', id) ?? 1,
      chain: chain,
      controls: controls,
    );
  }

  static EffectNode _parseNode(String presetId, int index, Map<String, dynamic> json) {
    final where = 'chain[$index]';
    final typeName = json['type'];
    if (typeName is! String) _fail(presetId, '$where: missing "type"');
    final type = NodeType.fromJsonName(typeName) ??
        _fail(presetId, '$where: unknown effect type "$typeName"');

    final params = json['params'] == null ? const <String, dynamic>{} : _object(json['params'], presetId, '$where.params');
    final values = <String, double>{};
    params.forEach((name, raw) {
      final spec = type.spec(name) ?? _fail(presetId, '$where: $typeName has no parameter "$name"');
      if (raw is! num) _fail(presetId, '$where: $name must be a number');
      final value = raw.toDouble();
      if (!spec.accepts(value)) {
        _fail(presetId, '$where: $name = $value is outside ${spec.min}..${spec.max}');
      }
      values[name] = value;
    });
    return EffectNode.of(type, values);
  }

  static ControlBinding _parseControl(
      String presetId, List<EffectNode> chain, Map<String, dynamic> json) {
    final key = json['key'];
    if (key is! String || key.isEmpty) _fail(presetId, 'control without "key"');
    final where = 'control "$key"';
    final nodeIndex = json['node'];
    if (nodeIndex is! int || nodeIndex < 0 || nodeIndex >= chain.length) {
      _fail(presetId, '$where: node $nodeIndex does not exist');
    }
    final node = chain[nodeIndex];
    final param = json['param'];
    if (param is! String) _fail(presetId, '$where: missing "param"');
    final spec = node.type.spec(param) ??
        _fail(presetId, '$where: ${node.type.jsonName} has no parameter "$param"');

    final min = (_optional<num>(json, 'min', presetId) ?? spec.min).toDouble();
    final max = (_optional<num>(json, 'max', presetId) ?? spec.max).toDouble();
    if (min >= max || !spec.accepts(min) || !spec.accepts(max)) {
      _fail(presetId, '$where: range $min..$max must be increasing and within ${spec.min}..${spec.max}');
    }
    final current = node[param];
    if (current < min || current > max) _fail(presetId, '$where: default $current is outside $min..$max');
    return ControlBinding(key: key, nodeIndex: nodeIndex, param: param, min: min, max: max);
  }

  static Map<String, dynamic> _object(Object? value, String presetId, String field) =>
      value is Map<String, dynamic> ? value : _fail(presetId, '$field must be an object');

  static List<dynamic> _list(Object? value, String presetId, String field) =>
      value is List ? value : _fail(presetId, '$field must be an array');

  static T? _optional<T>(Map<String, dynamic> json, String field, String presetId) {
    final value = json[field];
    if (value == null || value is T) return value as T?;
    _fail(presetId, '$field has the wrong type');
  }

  static Never _fail(String presetId, String message) =>
      throw PresetFormatException('Preset "$presetId": $message');
}
