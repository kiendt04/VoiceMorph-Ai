/// Allowed range and default of one effect parameter.
class ParamSpec {
  const ParamSpec(this.name, this.min, this.max, this.defaultValue);

  final String name;
  final double min;
  final double max;
  final double defaultValue;

  bool accepts(double value) => value >= min && value <= max;
}

/// Effect building blocks a preset chain can use, with the parameters each one
/// accepts. [jsonName] is the spelling used in preset files.
enum NodeType {
  gain('GAIN', [ParamSpec('db', -24, 24, 0)]),
  pitch('PITCH', [ParamSpec('semitones', -12, 12, 0), ParamSpec('tempo', 0.5, 2, 1)]),
  highPass('HIGHPASS', [ParamSpec('freq', 20, 20000, 100), ParamSpec('q', 0.1, 10, 0.7071)]),
  lowPass('LOWPASS', [ParamSpec('freq', 20, 20000, 8000), ParamSpec('q', 0.1, 10, 0.7071)]),
  bandPass('BANDPASS', [ParamSpec('freq', 20, 20000, 1000), ParamSpec('q', 0.1, 10, 0.7071)]),
  peak('PEAK', [
    ParamSpec('freq', 20, 20000, 1000),
    ParamSpec('gainDb', -24, 24, 0),
    ParamSpec('q', 0.1, 10, 1),
  ]),
  lowShelf('LOW_SHELF', [ParamSpec('freq', 20, 20000, 200), ParamSpec('gainDb', -24, 24, 0)]),
  highShelf('HIGH_SHELF', [ParamSpec('freq', 20, 20000, 4000), ParamSpec('gainDb', -24, 24, 0)]),
  ringMod('RING_MOD', [ParamSpec('freq', 1, 2000, 50), ParamSpec('mix', 0, 1, 1)]),
  tremolo('TREMOLO', [ParamSpec('rate', 0.1, 20, 5), ParamSpec('depth', 0, 1, 0.5)]),
  distortion('DISTORTION', [ParamSpec('drive', 1, 50, 4), ParamSpec('mix', 0, 1, 1)]),
  echo('ECHO', [
    ParamSpec('delayMs', 10, 2000, 300),
    ParamSpec('feedback', 0, 0.95, 0.4),
    ParamSpec('mix', 0, 1, 0.5),
  ]),
  reverb('REVERB', [
    ParamSpec('roomSize', 0, 1, 0.5),
    ParamSpec('damping', 0, 1, 0.5),
    ParamSpec('mix', 0, 1, 0.3),
  ]),
  limiter('LIMITER', [ParamSpec('ceilingDb', -24, 0, -1)]);

  const NodeType(this.jsonName, this.params);

  final String jsonName;
  final List<ParamSpec> params;

  ParamSpec? spec(String name) {
    for (final param in params) {
      if (param.name == name) return param;
    }
    return null;
  }

  static NodeType? fromJsonName(String name) {
    for (final type in values) {
      if (type.jsonName == name) return type;
    }
    return null;
  }
}
