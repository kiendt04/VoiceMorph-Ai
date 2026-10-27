package com.example.voicemorph_ai.core.io

import java.io.File
import java.io.InputStream
import java.io.OutputStream
import java.nio.ByteBuffer
import java.nio.ByteOrder
import kotlin.math.min
import kotlin.math.roundToInt

class WavFormatException(message: String) : IllegalArgumentException(message)

/** Mono audio as floats in -1..1. */
class WavAudio(val samples: FloatArray, val sampleRate: Int) {
    val durationMs: Long get() = samples.size * 1000L / sampleRate
}

/**
 * Minimal WAV codec. Reads PCM 8/16/24/32-bit and 32-bit float (including WAVE_FORMAT_EXTENSIBLE),
 * downmixing any channel count to mono. Writes 16-bit mono PCM.
 */
object WavIO {
    private const val FORMAT_PCM = 1
    private const val FORMAT_FLOAT = 3
    private const val FORMAT_EXTENSIBLE = 0xFFFE

    fun read(file: File): WavAudio = file.inputStream().buffered().use { read(it) }

    fun read(stream: InputStream): WavAudio {
        val bytes = stream.readBytes()
        val buffer = ByteBuffer.wrap(bytes).order(ByteOrder.LITTLE_ENDIAN)
        if (bytes.size < 12 || tag(bytes, 0) != "RIFF" || tag(bytes, 8) != "WAVE") {
            throw WavFormatException("Not a RIFF/WAVE file")
        }

        var format = -1
        var channels = 0
        var sampleRate = 0
        var bits = 0
        var dataStart = -1
        var dataSize = 0
        var position = 12L
        while (position + 8 <= bytes.size) {
            val chunk = position.toInt()
            val size = buffer.getInt(chunk + 4).toLong() and 0xFFFFFFFFL
            val body = chunk + 8
            val available = min(size, (bytes.size - body).toLong()).toInt()
            when (tag(bytes, chunk)) {
                "fmt " -> {
                    if (available < 16) throw WavFormatException("fmt chunk too short")
                    format = buffer.getShort(body).toInt() and 0xFFFF
                    channels = buffer.getShort(body + 2).toInt() and 0xFFFF
                    sampleRate = buffer.getInt(body + 4)
                    bits = buffer.getShort(body + 14).toInt() and 0xFFFF
                    if (format == FORMAT_EXTENSIBLE && available >= 26) {
                        format = buffer.getShort(body + 24).toInt() and 0xFFFF
                    }
                }
                "data" -> {
                    dataStart = body
                    dataSize = available
                }
            }
            position = body + size + (size and 1)
        }

        if (format < 0) throw WavFormatException("Missing fmt chunk")
        if (dataStart < 0) throw WavFormatException("Missing data chunk")
        if (channels <= 0 || sampleRate <= 0) throw WavFormatException("Invalid channels/sample rate")
        val supported = (format == FORMAT_PCM && bits in intArrayOf(8, 16, 24, 32)) ||
            (format == FORMAT_FLOAT && bits == 32)
        if (!supported) throw WavFormatException("Unsupported encoding: format $format, $bits bits")

        val bytesPerSample = bits / 8
        val frameSize = bytesPerSample * channels
        val samples = FloatArray(dataSize / frameSize) { frame ->
            var sum = 0f
            for (channel in 0 until channels) {
                sum += readSample(buffer, dataStart + frame * frameSize + channel * bytesPerSample, format, bits)
            }
            sum / channels
        }
        return WavAudio(samples, sampleRate)
    }

    fun write(file: File, samples: FloatArray, sampleRate: Int) {
        file.outputStream().buffered().use { write(it, samples, sampleRate) }
    }

    fun write(stream: OutputStream, samples: FloatArray, sampleRate: Int) {
        val dataSize = samples.size * 2
        val buffer = ByteBuffer.allocate(44 + dataSize).order(ByteOrder.LITTLE_ENDIAN)
        buffer.put("RIFF".toByteArray(Charsets.US_ASCII)).putInt(36 + dataSize)
        buffer.put("WAVE".toByteArray(Charsets.US_ASCII))
        buffer.put("fmt ".toByteArray(Charsets.US_ASCII)).putInt(16)
        buffer.putShort(FORMAT_PCM.toShort()).putShort(1).putInt(sampleRate).putInt(sampleRate * 2)
        buffer.putShort(2).putShort(16)
        buffer.put("data".toByteArray(Charsets.US_ASCII)).putInt(dataSize)
        for (sample in samples) {
            val clamped = if (sample.isNaN()) 0f else sample.coerceIn(-1f, 1f)
            buffer.putShort((clamped * Short.MAX_VALUE).roundToInt().toShort())
        }
        stream.write(buffer.array())
    }

    private fun readSample(buffer: ByteBuffer, offset: Int, format: Int, bits: Int): Float = when {
        format == FORMAT_FLOAT -> buffer.getFloat(offset)
        bits == 8 -> ((buffer.get(offset).toInt() and 0xFF) - 128) / 128f
        bits == 16 -> buffer.getShort(offset) / 32_768f
        bits == 24 -> {
            val value = (buffer.get(offset).toInt() and 0xFF) or
                ((buffer.get(offset + 1).toInt() and 0xFF) shl 8) or
                (buffer.get(offset + 2).toInt() shl 16)
            value / 8_388_608f
        }
        else -> buffer.getInt(offset) / 2_147_483_648f
    }

    private fun tag(bytes: ByteArray, offset: Int) = String(bytes, offset, 4, Charsets.US_ASCII)
}
