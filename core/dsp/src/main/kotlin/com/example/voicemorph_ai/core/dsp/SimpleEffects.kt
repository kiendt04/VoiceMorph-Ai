package com.example.voicemorph_ai.core.dsp

import com.example.voicemorph_ai.core.SampleProcessor
import kotlin.math.PI
import kotlin.math.cos
import kotlin.math.sin
import kotlin.math.tanh

class Gain(db: Float) : SampleProcessor() {
    private val gain = dbToLinear(db)

    override fun processSample(x: Float): Float = x * gain
}

/** Amplitude modulation by a low-frequency sine; gain swings between 1 and 1 - [depth]. */
class Tremolo(sampleRate: Int, rateHz: Float, private val depth: Float) : SampleProcessor() {
    private val step = 2 * PI * rateHz / sampleRate
    private var phase = 0.0

    override fun processSample(x: Float): Float {
        val gain = 1f - depth * 0.5f * (1f - cos(phase).toFloat())
        phase = (phase + step) % (2 * PI)
        return x * gain
    }
}

/** Multiplies the voice by a sine carrier: metallic "robot" at tens of Hz, "alien" at hundreds. */
class RingModulator(sampleRate: Int, freqHz: Float, private val mix: Float) : SampleProcessor() {
    private val step = 2 * PI * freqHz / sampleRate
    private var phase = 0.0

    override fun processSample(x: Float): Float {
        val modulated = x * sin(phase).toFloat()
        phase = (phase + step) % (2 * PI)
        return x * (1f - mix) + modulated * mix
    }
}

/** Soft clipping with tanh, normalised so a full-scale input stays at full scale. */
class Distortion(private val drive: Float, private val mix: Float) : SampleProcessor() {
    private val normalization = 1f / tanh(drive)

    override fun processSample(x: Float): Float =
        x * (1f - mix) + tanh(drive * x) * normalization * mix
}
