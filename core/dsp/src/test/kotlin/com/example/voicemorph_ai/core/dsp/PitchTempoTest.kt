package com.example.voicemorph_ai.core.dsp

import com.example.voicemorph_ai.core.TestSignals.SAMPLE_RATE
import com.example.voicemorph_ai.core.TestSignals.estimateFrequency
import com.example.voicemorph_ai.core.TestSignals.runThrough
import com.example.voicemorph_ai.core.TestSignals.sine
import org.junit.Assert.assertEquals
import org.junit.Test

class PitchTempoTest {

    @Test
    fun octaveUpDoublesFrequencyAndKeepsDuration() {
        val input = sine(220.0, 2.0)
        val output = runThrough(PitchTempo(SAMPLE_RATE, semitones = 12f, tempo = 1f), input)

        assertEquals(input.size, output.size)
        assertEquals(440.0, estimateFrequency(output), 440 * 0.02)
    }

    @Test
    fun octaveDownHalvesFrequencyAndKeepsDuration() {
        val input = sine(440.0, 2.0)
        val output = runThrough(PitchTempo(SAMPLE_RATE, semitones = -12f, tempo = 1f), input)

        assertEquals(input.size, output.size)
        assertEquals(220.0, estimateFrequency(output), 220 * 0.02)
    }

    @Test
    fun fasterTempoShortensWithoutChangingPitch() {
        val input = sine(300.0, 3.0)
        val output = runThrough(PitchTempo(SAMPLE_RATE, semitones = 0f, tempo = 1.5f), input)

        assertEquals(input.size / 1.5, output.size.toDouble(), 2.0)
        assertEquals(300.0, estimateFrequency(output), 300 * 0.02)
    }

    @Test
    fun slowerTempoWithPitchShiftCombines() {
        val input = sine(200.0, 2.0)
        val output = runThrough(PitchTempo(SAMPLE_RATE, semitones = 7f, tempo = 0.75f), input)

        assertEquals(input.size / 0.75, output.size.toDouble(), 2.0)
        assertEquals(200 * 1.4983, estimateFrequency(output), 300 * 0.02)
    }

    @Test
    fun resamplerConvertsSampleRatePreservingFrequency() {
        val input = sine(1_000.0, 1.0, sampleRate = 48_000)
        val output = Resampler.convert(input, 48_000, 44_100)

        assertEquals(44_100.0, output.size.toDouble(), 1.0)
        assertEquals(1_000.0, estimateFrequency(output, 44_100), 5.0)
    }
}
