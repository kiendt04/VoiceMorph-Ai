package com.example.voicemorph_ai.core.dsp

import com.example.voicemorph_ai.core.SampleProcessor
import kotlin.math.max

/**
 * Mono Freeverb (Schroeder/Moorer): 8 parallel damped comb filters followed by 4 series all-pass
 * filters. Delay lengths are the original 44.1 kHz tunings scaled to the sample rate.
 */
class Reverb(
    sampleRate: Int,
    roomSize: Float,
    damping: Float,
    private val mix: Float,
) : SampleProcessor() {
    private val scale = sampleRate / 44_100.0
    private val combs = COMB_TUNINGS.map {
        Comb(scaled(it), roomSize * SCALE_ROOM + OFFSET_ROOM, damping * SCALE_DAMP)
    }
    private val allPasses = ALLPASS_TUNINGS.map { AllPass(scaled(it)) }

    override val tailSamples: Int = sampleRate * 4

    override fun processSample(x: Float): Float {
        val input = x * FIXED_GAIN
        var wet = 0f
        for (comb in combs) wet += comb.process(input)
        for (allPass in allPasses) wet = allPass.process(wet)
        return x * (1f - mix) + wet * WET_SCALE * mix
    }

    private fun scaled(samples: Int) = max(1, (samples * scale).toInt())

    private class Comb(size: Int, private val feedback: Float, private val damp: Float) {
        private val buffer = FloatArray(size)
        private var index = 0
        private var store = 0f

        fun process(input: Float): Float {
            val output = buffer[index]
            store = output * (1f - damp) + store * damp
            buffer[index] = input + store * feedback
            index = (index + 1) % buffer.size
            return output
        }
    }

    private class AllPass(size: Int) {
        private val buffer = FloatArray(size)
        private var index = 0

        fun process(input: Float): Float {
            val buffered = buffer[index]
            buffer[index] = input + buffered * 0.5f
            index = (index + 1) % buffer.size
            return buffered - input
        }
    }

    private companion object {
        val COMB_TUNINGS = intArrayOf(1116, 1188, 1277, 1356, 1422, 1491, 1557, 1617)
        val ALLPASS_TUNINGS = intArrayOf(556, 441, 341, 225)
        const val FIXED_GAIN = 0.015f
        const val SCALE_ROOM = 0.28f
        const val OFFSET_ROOM = 0.7f
        const val SCALE_DAMP = 0.4f
        const val WET_SCALE = 3f
    }
}
