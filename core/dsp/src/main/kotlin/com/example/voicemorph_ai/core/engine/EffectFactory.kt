package com.example.voicemorph_ai.core.engine

import com.example.voicemorph_ai.core.AudioProcessor
import com.example.voicemorph_ai.core.ProcessorChain
import com.example.voicemorph_ai.core.dsp.Biquad
import com.example.voicemorph_ai.core.dsp.Distortion
import com.example.voicemorph_ai.core.dsp.Echo
import com.example.voicemorph_ai.core.dsp.Gain
import com.example.voicemorph_ai.core.dsp.Limiter
import com.example.voicemorph_ai.core.dsp.PitchTempo
import com.example.voicemorph_ai.core.dsp.Reverb
import com.example.voicemorph_ai.core.dsp.RingModulator
import com.example.voicemorph_ai.core.dsp.Tremolo
import com.example.voicemorph_ai.core.preset.EffectNode
import com.example.voicemorph_ai.core.preset.NodeType

/** Turns preset nodes into processors. */
object EffectFactory {

    /**
     * Builds the processing chain. Nodes that would not change the sound (zero mix, 0 dB gain,
     * no pitch/speed change) are skipped, and a limiter is always appended unless the chain
     * already ends with one, so output never clips.
     */
    fun createChain(nodes: List<EffectNode>, sampleRate: Int): AudioProcessor {
        val processors = nodes.mapNotNull { create(it, sampleRate) }.toMutableList()
        if (nodes.lastOrNull()?.type != NodeType.LIMITER) processors += Limiter(sampleRate)
        return ProcessorChain(processors)
    }

    fun create(node: EffectNode, sampleRate: Int): AudioProcessor? = when (node.type) {
        NodeType.GAIN -> if (node["db"] == 0f) null else Gain(node["db"])
        NodeType.PITCH ->
            if (node["semitones"] == 0f && node["tempo"] == 1f) null
            else PitchTempo(sampleRate, node["semitones"], node["tempo"])
        NodeType.HIGHPASS -> Biquad.highPass(sampleRate, node["freq"], node["q"])
        NodeType.LOWPASS -> Biquad.lowPass(sampleRate, node["freq"], node["q"])
        NodeType.BANDPASS -> Biquad.bandPass(sampleRate, node["freq"], node["q"])
        NodeType.PEAK ->
            if (node["gainDb"] == 0f) null
            else Biquad.peaking(sampleRate, node["freq"], node["gainDb"], node["q"])
        NodeType.LOW_SHELF ->
            if (node["gainDb"] == 0f) null else Biquad.lowShelf(sampleRate, node["freq"], node["gainDb"])
        NodeType.HIGH_SHELF ->
            if (node["gainDb"] == 0f) null else Biquad.highShelf(sampleRate, node["freq"], node["gainDb"])
        NodeType.RING_MOD -> if (node["mix"] == 0f) null else RingModulator(sampleRate, node["freq"], node["mix"])
        NodeType.TREMOLO -> if (node["depth"] == 0f) null else Tremolo(sampleRate, node["rate"], node["depth"])
        NodeType.DISTORTION -> if (node["mix"] == 0f) null else Distortion(node["drive"], node["mix"])
        NodeType.ECHO ->
            if (node["mix"] == 0f) null
            else Echo(sampleRate, node["delayMs"], node["feedback"], node["mix"])
        NodeType.REVERB ->
            if (node["mix"] == 0f) null
            else Reverb(sampleRate, node["roomSize"], node["damping"], node["mix"])
        NodeType.LIMITER -> Limiter(sampleRate, node["ceilingDb"])
    }
}
