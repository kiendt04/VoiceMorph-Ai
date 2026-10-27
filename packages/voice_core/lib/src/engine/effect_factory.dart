import '../audio_processor.dart';
import '../dsp/biquad.dart';
import '../dsp/echo.dart';
import '../dsp/limiter.dart';
import '../dsp/pitch_tempo.dart';
import '../dsp/reverb.dart';
import '../dsp/simple_effects.dart';
import '../preset/effect_preset.dart';
import '../preset/node_type.dart';

/// Turns preset nodes into processors.
abstract final class EffectFactory {
  /// Builds the processing chain. Nodes that would not change the sound (zero
  /// mix, 0 dB gain, no pitch/speed change) are skipped, and a limiter is
  /// always appended unless the chain already ends with one, so output never
  /// clips.
  static AudioProcessor createChain(List<EffectNode> nodes, int sampleRate) {
    final processors = [
      for (final node in nodes) ?create(node, sampleRate),
      if (nodes.isEmpty || nodes.last.type != NodeType.limiter) Limiter(sampleRate),
    ];
    return ProcessorChain(processors);
  }

  static AudioProcessor? create(EffectNode node, int sampleRate) => switch (node.type) {
        NodeType.gain => node['db'] == 0 ? null : Gain(node['db']),
        NodeType.pitch => node['semitones'] == 0 && node['tempo'] == 1
            ? null
            : PitchTempo(sampleRate, node['semitones'], node['tempo']),
        NodeType.highPass => Biquad.highPass(sampleRate, node['freq'], node['q']),
        NodeType.lowPass => Biquad.lowPass(sampleRate, node['freq'], node['q']),
        NodeType.bandPass => Biquad.bandPass(sampleRate, node['freq'], node['q']),
        NodeType.peak => node['gainDb'] == 0
            ? null
            : Biquad.peaking(sampleRate, node['freq'], node['gainDb'], node['q']),
        NodeType.lowShelf =>
          node['gainDb'] == 0 ? null : Biquad.lowShelf(sampleRate, node['freq'], node['gainDb']),
        NodeType.highShelf =>
          node['gainDb'] == 0 ? null : Biquad.highShelf(sampleRate, node['freq'], node['gainDb']),
        NodeType.ringMod =>
          node['mix'] == 0 ? null : RingModulator(sampleRate, node['freq'], node['mix']),
        NodeType.tremolo =>
          node['depth'] == 0 ? null : Tremolo(sampleRate, node['rate'], node['depth']),
        NodeType.distortion => node['mix'] == 0 ? null : Distortion(node['drive'], node['mix']),
        NodeType.echo => node['mix'] == 0
            ? null
            : Echo(sampleRate, node['delayMs'], node['feedback'], node['mix']),
        NodeType.reverb => node['mix'] == 0
            ? null
            : Reverb(sampleRate, node['roomSize'], node['damping'], node['mix']),
        NodeType.limiter => Limiter(sampleRate, ceilingDb: node['ceilingDb']),
      };
}
