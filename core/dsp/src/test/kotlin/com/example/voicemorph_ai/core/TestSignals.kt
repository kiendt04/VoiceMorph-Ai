package com.example.voicemorph_ai.core

import kotlin.math.PI
import kotlin.math.abs
import kotlin.math.sin
import kotlin.random.Random

object TestSignals {
    const val SAMPLE_RATE = 44_100

    fun sine(freq: Double, seconds: Double, amplitude: Float = 0.5f, sampleRate: Int = SAMPLE_RATE) =
        FloatArray((seconds * sampleRate).toInt()) {
            (amplitude * sin(2 * PI * freq * it / sampleRate)).toFloat()
        }

    /** Harmonic-rich tone with vibrato, syllable-like envelope and breath noise. */
    fun voiceLike(seconds: Double, sampleRate: Int = SAMPLE_RATE): FloatArray {
        val random = Random(42)
        var phase = 0.0
        return FloatArray((seconds * sampleRate).toInt()) { i ->
            val t = i.toDouble() / sampleRate
            val f0 = 140 + 8 * sin(2 * PI * 5 * t)
            phase += 2 * PI * f0 / sampleRate
            var tone = 0.0
            for (harmonic in 1..12) tone += sin(harmonic * phase) / harmonic
            val envelope = 0.5 + 0.5 * sin(2 * PI * 3 * t)
            (0.3 * envelope * tone + 0.01 * (random.nextDouble() - 0.5)).toFloat()
        }
    }

    /** Frequency from upward zero crossings over the middle 60% of the signal. */
    fun estimateFrequency(samples: FloatArray, sampleRate: Int = SAMPLE_RATE): Double {
        val from = samples.size / 5
        val to = samples.size * 4 / 5
        var first = -1.0
        var last = -1.0
        var crossings = 0
        for (i in from until to - 1) {
            if (samples[i] <= 0f && samples[i + 1] > 0f) {
                val time = i + samples[i] / (samples[i] - samples[i + 1]).toDouble()
                if (first < 0) first = time
                last = time
                crossings++
            }
        }
        return (crossings - 1) * sampleRate / (last - first)
    }

    fun peak(samples: FloatArray): Float = samples.maxOfOrNull { abs(it) } ?: 0f

    fun runThrough(processor: AudioProcessor, input: FloatArray, blockSize: Int = 1024): FloatArray {
        val output = mutableListOf<FloatArray>()
        var position = 0
        while (position < input.size) {
            val frames = minOf(blockSize, input.size - position)
            output += processor.process(input.copyOfRange(position, position + frames), frames)
            position += frames
        }
        output += processor.flush()
        return output.fold(FloatArray(0)) { acc, block -> acc + block }
    }
}
