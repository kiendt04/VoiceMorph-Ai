package com.example.voicemorph_ai.core.dsp

import com.example.voicemorph_ai.core.TestSignals.SAMPLE_RATE
import com.example.voicemorph_ai.core.TestSignals.peak
import com.example.voicemorph_ai.core.TestSignals.runThrough
import com.example.voicemorph_ai.core.TestSignals.sine
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import kotlin.math.abs

class EffectsTest {

    @Test
    fun lowPassKeepsLowAndCutsHighFrequencies() {
        val low = runThrough(Biquad.lowPass(SAMPLE_RATE, 1_000f), sine(200.0, 0.5))
        val high = runThrough(Biquad.lowPass(SAMPLE_RATE, 1_000f), sine(10_000.0, 0.5))

        assertEquals(0.5f, peak(low.copyOfRange(2_000, low.size)), 0.02f)
        assertTrue("10 kHz should be ~40 dB down", peak(high.copyOfRange(2_000, high.size)) < 0.01f)
    }

    @Test
    fun echoRepeatsImpulseAfterDelayAndKeepsTail() {
        val impulse = FloatArray(1_000).also { it[0] = 1f }
        val output = runThrough(Echo(SAMPLE_RATE, delayMs = 100f, feedback = 0.5f, mix = 0.5f), impulse)
        val delay = SAMPLE_RATE / 10

        assertEquals(1f, output[0], 1e-6f)
        assertEquals(0.5f, output[delay], 1e-6f)
        assertEquals(0.25f, output[2 * delay], 1e-6f)
        assertTrue("tail continues past the input", output.size > 3 * delay)
    }

    @Test
    fun reverbTailIsFiniteAndDecays() {
        val impulse = FloatArray(1_000).also { it[0] = 1f }
        val output = runThrough(Reverb(SAMPLE_RATE, roomSize = 0.8f, damping = 0.3f, mix = 0.5f), impulse)

        assertTrue(output.all { it.isFinite() })
        assertTrue("reverb adds a tail", output.size > SAMPLE_RATE / 2)
        assertTrue(peak(output.copyOfRange(output.size - 1_000, output.size)) < 1e-3f)
    }

    @Test
    fun limiterNeverExceedsCeilingAndKeepsLength() {
        val loud = sine(440.0, 1.0, amplitude = 3f)
        val output = runThrough(Limiter(SAMPLE_RATE, ceilingDb = -1f), loud, blockSize = 777)

        assertEquals(loud.size, output.size)
        assertTrue(peak(output) <= dbToLinear(-1f) + 1e-6f)
    }

    @Test
    fun limiterLeavesQuietSignalUntouched() {
        val quiet = sine(440.0, 0.5, amplitude = 0.2f)
        val output = runThrough(Limiter(SAMPLE_RATE), quiet)

        assertEquals(quiet.size, output.size)
        for (i in quiet.indices) assertEquals(quiet[i], output[i], 1e-6f)
    }

    @Test
    fun limiterHandlesInputShorterThanLookahead() {
        val input = floatArrayOf(0.1f, -0.2f, 0.3f)
        val output = runThrough(Limiter(SAMPLE_RATE), input)

        assertEquals(input.toList(), output.toList())
    }

    @Test
    fun distortionStaysWithinFullScale() {
        val output = runThrough(Distortion(drive = 20f, mix = 1f), sine(200.0, 0.2, amplitude = 1f))
        assertTrue(output.all { abs(it) <= 1f + 1e-6f })
    }
}
