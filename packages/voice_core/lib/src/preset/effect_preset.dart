import 'node_type.dart';

/// One effect in a chain; [params] always holds every parameter of [type].
class EffectNode {
  const EffectNode._(this.type, this.params);

  /// Builds a node, filling unspecified parameters with their defaults.
  factory EffectNode.of(NodeType type, [Map<String, double> values = const {}]) {
    var node = EffectNode._(type, {for (final p in type.params) p.name: p.defaultValue});
    values.forEach((name, value) => node = node.withParam(name, value));
    return node;
  }

  final NodeType type;
  final Map<String, double> params;

  double operator [](String param) =>
      params[param] ?? (throw ArgumentError('${type.jsonName} has no parameter "$param"'));

  EffectNode withParam(String param, double value) {
    final spec = type.spec(param);
    if (spec == null) throw ArgumentError('${type.jsonName} has no parameter "$param"');
    if (!spec.accepts(value)) {
      throw RangeError('${type.jsonName}.$param = $value is outside ${spec.min}..${spec.max}');
    }
    return EffectNode._(type, {...params, param: value});
  }
}

/// A slider exposed to the user ("pitch", "speed", "echo"...) bound to one
/// parameter of one node. [min]..[max] is the slider range and lies within the
/// parameter's allowed range.
class ControlBinding {
  const ControlBinding({
    required this.key,
    required this.nodeIndex,
    required this.param,
    required this.min,
    required this.max,
  });

  final String key;
  final int nodeIndex;
  final String param;
  final double min;
  final double max;
}

/// A voice effect: an ordered chain of nodes plus the controls the user may
/// tweak.
class EffectPreset {
  const EffectPreset({
    required this.id,
    required this.names,
    required this.category,
    required this.isPro,
    required this.version,
    required this.chain,
    required this.controls,
  });

  final String id;
  final Map<String, String> names;
  final String category;
  final bool isPro;
  final int version;
  final List<EffectNode> chain;
  final List<ControlBinding> controls;

  /// Display name in [language] ("vi", "en"), falling back to English, then
  /// to the id.
  String name(String language) => names[language] ?? names['en'] ?? id;

  Map<String, double> defaultControlValues() =>
      {for (final c in controls) c.key: chain[c.nodeIndex][c.param]};

  /// The chain with the user's control values applied. Values are clamped to
  /// each control's range; an unknown key is a programming error and throws.
  List<EffectNode> resolveChain([Map<String, double> controlValues = const {}]) {
    if (controlValues.isEmpty) return chain;
    final nodes = [...chain];
    controlValues.forEach((key, value) {
      final control = controls.where((c) => c.key == key).firstOrNull;
      if (control == null) throw ArgumentError('Preset "$id" has no control "$key"');
      if (value.isNaN) throw ArgumentError('Control "$key" is NaN');
      nodes[control.nodeIndex] = nodes[control.nodeIndex]
          .withParam(control.param, value.clamp(control.min, control.max).toDouble());
    });
    return nodes;
  }
}
