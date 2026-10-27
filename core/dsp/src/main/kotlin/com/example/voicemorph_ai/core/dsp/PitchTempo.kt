package com.example.voicemorph_ai.core.dsp

import com.example.voicemorph_ai.core.AudioProcessor
import com.example.voicemorph_ai.core.ProcessorChain
import kotlin.math.pow
import kotlin.math.roundToLong

/**
 * Independent pitch and speed change.
 *
 * Pitch is shifted by time-stretching by the pitch ratio and then resampling back to the
 * original duration. Formants move together with the pitch (the "chipmunk" character at large
 * shifts); formant-preserving shifting needs a vocoder and is not part of this engine yet.
 */
class PitchTempo(sampleRate: Int, semitones: Float, private val tempo: Float) : AudioProcessor {
    private val chain: AudioProcessor
    private var totalIn = 0L
    private var produced = 0L

    init {
        require(tempo > 0f) { "tempo must be positive: $tempo" }
        val pitchRatio = 2.0.pow(semitones / 12.0)
        val stretchTempo = tempo / pitchRatio
        val stages = mutableListOf<AudioProcessor>()
        if (stretchTempo != 1.0) stages += TimeStretcher(sampleRate, stretchTempo)
        if (pitchRatio != 1.0) stages += Resampler.antiAliased(sampleRate, pitchRatio)
        chain = ProcessorChain(stages)
    }

    override fun process(input: FloatArray, frames: Int): FloatArray {
        totalIn += frames
        return chain.process(input, frames).also { produced += it.size }
    }

    /** Stretching and resampling each round once; settle the total at exactly input / tempo. */
    override fun flush(): FloatArray {
        val tail = chain.flush()
        val expected = (totalIn / tempo.toDouble()).roundToLong()
        return tail.copyOf((expected - produced).coerceIn(0, Int.MAX_VALUE.toLong()).toInt())
    }
}
