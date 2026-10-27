package com.example.voicemorph_ai.core.io

import com.example.voicemorph_ai.core.TestSignals.sine
import org.junit.Assert.assertEquals
import org.junit.Assert.assertThrows
import org.junit.Test
import java.io.ByteArrayInputStream
import java.io.ByteArrayOutputStream
import java.nio.ByteBuffer
import java.nio.ByteOrder

class WavIOTest {

    @Test
    fun roundTripsPcm16() {
        val samples = sine(440.0, 0.1)
        val bytes = ByteArrayOutputStream().also { WavIO.write(it, samples, 22_050) }.toByteArray()

        val audio = WavIO.read(ByteArrayInputStream(bytes))

        assertEquals(22_050, audio.sampleRate)
        assertEquals(samples.size, audio.samples.size)
        for (i in samples.indices) assertEquals(samples[i], audio.samples[i], 1f / 16_000)
    }

    @Test
    fun downmixesStereoFloat() {
        val frames = floatArrayOf(0.5f, -0.5f, 1f, 0f)
        val audio = WavIO.read(ByteArrayInputStream(floatWav(frames, channels = 2, sampleRate = 48_000)))

        assertEquals(48_000, audio.sampleRate)
        assertEquals(listOf(0f, 0.5f), audio.samples.toList())
    }

    @Test
    fun clampsOutOfRangeAndNaNWhenWriting() {
        val bytes = ByteArrayOutputStream().also { WavIO.write(it, floatArrayOf(2f, -2f, Float.NaN), 8_000) }.toByteArray()
        val audio = WavIO.read(ByteArrayInputStream(bytes))

        assertEquals(1f, audio.samples[0], 1e-4f)
        assertEquals(-1f, audio.samples[1], 1e-4f)
        assertEquals(0f, audio.samples[2])
    }

    @Test
    fun rejectsNonWavData() {
        assertThrows(WavFormatException::class.java) {
            WavIO.read(ByteArrayInputStream("ID3 this is an mp3".toByteArray()))
        }
    }

    private fun floatWav(samples: FloatArray, channels: Int, sampleRate: Int): ByteArray {
        val dataSize = samples.size * 4
        val buffer = ByteBuffer.allocate(44 + dataSize).order(ByteOrder.LITTLE_ENDIAN)
        buffer.put("RIFF".toByteArray()).putInt(36 + dataSize).put("WAVE".toByteArray())
        buffer.put("fmt ".toByteArray()).putInt(16).putShort(3).putShort(channels.toShort())
        buffer.putInt(sampleRate).putInt(sampleRate * channels * 4).putShort((channels * 4).toShort()).putShort(32)
        buffer.put("data".toByteArray()).putInt(dataSize)
        samples.forEach { buffer.putFloat(it) }
        return buffer.array()
    }
}
