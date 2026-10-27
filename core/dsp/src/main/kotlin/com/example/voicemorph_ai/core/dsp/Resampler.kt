package com.example.voicemorph_ai.core.dsp

import com.example.voicemorph_ai.core.AudioProcessor
import com.example.voicemorph_ai.core.ProcessorChain
import kotlin.math.ceil
import kotlin.math.floor

/**
 * Streaming linear-interpolation resampler. [rate] is the number of input samples consumed per
 * output sample: 2.0 halves the length (and doubles the pitch when played at the same rate).
 *
 * It does not filter; put a low-pass in front when [rate] > 1 (see [antiAliased]).
 */
class Resampler(private val rate: Double) : AudioProcessor {
    private var position = 0.0
    private var blockStart = 0L
    private var previous = 0f
    private var produced = 0L

    init {
        require(rate > 0) { "rate must be positive: $rate" }
    }

    override fun process(input: FloatArray, frames: Int): FloatArray {
        val output = SampleQueue((frames / rate).toInt() + 2)
        val end = blockStart + frames
        while (true) {
            val index = floor(position).toLong()
            if (index + 1 >= end) break
            val a = sampleAt(input, index)
            val b = sampleAt(input, index + 1)
            output.add(a + (b - a) * (position - index).toFloat())
            position += rate
        }
        if (frames > 0) previous = input[frames - 1]
        blockStart = end
        produced += output.size
        return output.toArray()
    }

    /** Emits the last outputs by holding the final sample, so length is ceil(input / rate). */
    override fun flush(): FloatArray {
        val expected = ceil(blockStart / rate).toLong()
        val tail = process(floatArrayOf(previous), 1)
        val keep = (expected - (produced - tail.size)).coerceIn(0, tail.size.toLong()).toInt()
        return tail.copyOf(keep)
    }

    /** Every index reaching here is >= blockStart - 1, which is the held [previous] sample. */
    private fun sampleAt(input: FloatArray, index: Long): Float =
        if (index < blockStart) previous else input[(index - blockStart).toInt()]

    companion object {
        /** Resampler preceded by a 4th-order low-pass when it decimates. */
        fun antiAliased(sampleRate: Int, rate: Double): AudioProcessor {
            if (rate <= 1.0) return Resampler(rate)
            val cutoff = (0.45 * sampleRate / rate).toFloat()
            return ProcessorChain(
                listOf(
                    Biquad.lowPass(sampleRate, cutoff),
                    Biquad.lowPass(sampleRate, cutoff),
                    Resampler(rate),
                )
            )
        }

        /** Converts a whole buffer between sample rates (e.g. imported 48 kHz audio to 44.1 kHz). */
        fun convert(samples: FloatArray, fromRate: Int, toRate: Int): FloatArray {
            if (fromRate == toRate) return samples.copyOf()
            val resampler = antiAliased(fromRate, fromRate.toDouble() / toRate)
            return resampler.process(samples) + resampler.flush()
        }
    }
}
