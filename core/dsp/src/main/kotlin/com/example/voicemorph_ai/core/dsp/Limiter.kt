package com.example.voicemorph_ai.core.dsp

import com.example.voicemorph_ai.core.AudioProcessor
import kotlin.math.abs
import kotlin.math.exp
import kotlin.math.max

/**
 * Look-ahead peak limiter: no output sample exceeds [ceilingDb].
 *
 * The signal is delayed by the look-ahead so the gain can come down before a peak arrives. That
 * delay is compensated internally (the first look-ahead outputs are dropped and [flush] releases
 * the held samples), so output length always equals input length.
 */
class Limiter(
    sampleRate: Int,
    ceilingDb: Float = -1f,
    lookaheadMs: Float = 5f,
    releaseMs: Float = 80f,
) : AudioProcessor {
    private val ceiling = dbToLinear(ceilingDb)
    private val lookahead = max(1, msToSamples(sampleRate, lookaheadMs.toDouble()))
    private val attack = 1f - exp(-4f / lookahead)
    private val release = 1f - exp(-1f / max(1, msToSamples(sampleRate, releaseMs.toDouble())))

    private val delay = FloatArray(lookahead)
    private var delayIndex = 0
    private val window = SlidingMax(lookahead + 1)
    private var gain = 1f
    private var received = 0L

    override fun process(input: FloatArray, frames: Int): FloatArray {
        val skip = (lookahead - received).coerceIn(0, frames.toLong()).toInt()
        val output = FloatArray(frames - skip)
        for (i in 0 until frames) {
            val y = processSample(input[i])
            if (i >= skip) output[i - skip] = y
        }
        received += frames
        return output
    }

    override fun flush(): FloatArray {
        val outputs = FloatArray(lookahead) { processSample(0f) }
        // Inputs shorter than the look-ahead have not yet skipped all the initial delay padding.
        val held = minOf(received, lookahead.toLong()).toInt()
        return outputs.copyOfRange(lookahead - held, lookahead)
    }

    private fun processSample(x: Float): Float {
        val peak = window.push(abs(x))
        val target = if (peak > ceiling) ceiling / peak else 1f
        gain += (target - gain) * (if (target < gain) attack else release)

        val delayed = delay[delayIndex]
        delay[delayIndex] = x
        delayIndex = (delayIndex + 1) % lookahead

        // The smoothed gain can trail the target by a hair; never let that through.
        return (delayed * gain).coerceIn(-ceiling, ceiling)
    }

    /** Maximum of the last [size] values in O(1) amortised time (monotonic deque). */
    private class SlidingMax(private val size: Int) {
        private val capacity = size + 1
        private val values = FloatArray(capacity)
        private val positions = LongArray(capacity)
        private var head = 0
        private var count = 0
        private var position = 0L

        fun push(value: Float): Float {
            while (count > 0 && values[back()] <= value) count--
            val slot = (head + count) % capacity
            values[slot] = value
            positions[slot] = position
            count++
            while (positions[head] <= position - size) {
                head = (head + 1) % capacity
                count--
            }
            position++
            return values[head]
        }

        private fun back() = (head + count - 1) % capacity
    }
}
