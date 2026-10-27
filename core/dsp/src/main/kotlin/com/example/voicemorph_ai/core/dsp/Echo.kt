package com.example.voicemorph_ai.core.dsp

import com.example.voicemorph_ai.core.SampleProcessor
import kotlin.math.ceil
import kotlin.math.ln
import kotlin.math.max
import kotlin.math.min

/** Feedback delay line. The dry signal is kept at full level; [mix] sets the echo level. */
class Echo(
    sampleRate: Int,
    delayMs: Float,
    private val feedback: Float,
    private val mix: Float,
) : SampleProcessor() {
    private val buffer = FloatArray(max(1, msToSamples(sampleRate, delayMs.toDouble())))
    private var index = 0

    override val tailSamples: Int = run {
        // Repeats needed for the echo to fall below -80 dB, capped at 10 seconds.
        val repeats = if (feedback <= 0f) 1 else ceil(ln(1e-4) / ln(feedback.toDouble())).toInt() + 1
        min(buffer.size.toLong() * repeats, sampleRate * 10L).toInt()
    }

    override fun processSample(x: Float): Float {
        val delayed = buffer[index]
        buffer[index] = x + delayed * feedback
        index = (index + 1) % buffer.size
        return x + delayed * mix
    }
}
