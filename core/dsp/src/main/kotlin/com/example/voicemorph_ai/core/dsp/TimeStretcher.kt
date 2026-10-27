package com.example.voicemorph_ai.core.dsp

import com.example.voicemorph_ai.core.AudioProcessor
import kotlin.math.max
import kotlin.math.min
import kotlin.math.roundToLong
import kotlin.math.sqrt

/**
 * Changes speed without changing pitch using WSOLA (waveform-similarity overlap-add), the same
 * scheme SoundTouch uses: the input is cut into ~40 ms sequences, and each new sequence starts
 * at the offset (within a 15 ms seek window) whose waveform best matches the end of the previous
 * one, so the 8 ms crossfades don't smear the pitch period.
 *
 * [tempo] > 1 speeds up (shorter output), < 1 slows down.
 */
class TimeStretcher(sampleRate: Int, private val tempo: Double) : AudioProcessor {
    private val sequence = msToSamples(sampleRate, SEQUENCE_MS)
    private val seek = max(1, msToSamples(sampleRate, SEEK_MS))
    private val overlap = max(1, msToSamples(sampleRate, OVERLAP_MS))
    private val nominalSkip = tempo * (sequence - overlap)
    private val required = max(nominalSkip.toInt() + overlap, sequence) + seek

    private val input = SampleQueue()
    private val previousTail = FloatArray(overlap)
    private var started = false
    private var skipFraction = 0.0
    private var totalIn = 0L
    private var totalOut = 0L

    init {
        require(tempo > 0) { "tempo must be positive: $tempo" }
    }

    override fun process(input: FloatArray, frames: Int): FloatArray {
        this.input.addAll(input, 0, frames)
        totalIn += frames
        val output = SampleQueue()
        stretch(output)
        totalOut += output.size
        return output.toArray()
    }

    /** Pads with silence until the output covers all input, then trims to the exact length. */
    override fun flush(): FloatArray {
        val expected = (totalIn / tempo).roundToLong()
        val output = SampleQueue()
        val silence = FloatArray(required)
        while (totalOut + output.size < expected) {
            input.addAll(silence)
            stretch(output)
        }
        val keep = (expected - totalOut).coerceIn(0, output.size.toLong()).toInt()
        totalOut += keep
        return output.toArray().copyOf(keep)
    }

    private fun stretch(output: SampleQueue) {
        while (input.size >= required) {
            val buffer = input.array
            val base = input.offset
            if (!started) {
                // Nothing to match against yet: start exactly at the first sample.
                buffer.copyInto(previousTail, 0, base, base + overlap)
                started = true
            }
            val start = base + bestOffset(buffer, base)

            for (i in 0 until overlap) {
                val t = i.toFloat() / overlap
                output.add(previousTail[i] * (1f - t) + buffer[start + i] * t)
            }
            output.addAll(buffer, start + overlap, sequence - 2 * overlap)
            buffer.copyInto(previousTail, 0, start + sequence - overlap, start + sequence)

            skipFraction += nominalSkip
            val skip = skipFraction.toInt()
            skipFraction -= skip
            input.drop(skip)
        }
    }

    /** Coarse search on every 4th offset/sample, then a full-resolution search around the winner. */
    private fun bestOffset(buffer: FloatArray, base: Int): Int {
        var best = 0
        var bestScore = Double.NEGATIVE_INFINITY
        var offset = 0
        while (offset < seek) {
            val score = similarity(buffer, base + offset, COARSE_STEP)
            if (score > bestScore) {
                bestScore = score
                best = offset
            }
            offset += COARSE_STEP
        }

        val from = max(0, best - COARSE_STEP + 1)
        val to = min(seek - 1, best + COARSE_STEP - 1)
        bestScore = Double.NEGATIVE_INFINITY
        for (candidate in from..to) {
            val score = similarity(buffer, base + candidate, 1)
            if (score > bestScore) {
                bestScore = score
                best = candidate
            }
        }
        return best
    }

    /** Cross-correlation with the previous tail, normalised by the candidate's energy. */
    private fun similarity(buffer: FloatArray, position: Int, step: Int): Double {
        var correlation = 0.0
        var energy = 0.0
        var i = 0
        while (i < overlap) {
            val value = buffer[position + i]
            correlation += previousTail[i] * value
            energy += value * value
            i += step
        }
        return if (energy > 1e-12) correlation / sqrt(energy) else 0.0
    }

    private companion object {
        const val SEQUENCE_MS = 40.0
        const val SEEK_MS = 15.0
        const val OVERLAP_MS = 8.0
        const val COARSE_STEP = 4
    }
}
