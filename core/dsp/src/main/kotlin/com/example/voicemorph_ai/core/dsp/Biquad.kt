package com.example.voicemorph_ai.core.dsp

import com.example.voicemorph_ai.core.SampleProcessor
import kotlin.math.PI
import kotlin.math.cos
import kotlin.math.pow
import kotlin.math.sin
import kotlin.math.sqrt

/**
 * Second-order IIR filter (transposed direct form II) with coefficients from the
 * RBJ Audio EQ Cookbook.
 */
class Biquad private constructor(
    private val b0: Double,
    private val b1: Double,
    private val b2: Double,
    private val a1: Double,
    private val a2: Double,
) : SampleProcessor() {
    private var z1 = 0.0
    private var z2 = 0.0

    override fun processSample(x: Float): Float {
        val y = b0 * x + z1
        z1 = b1 * x - a1 * y + z2
        z2 = b2 * x - a2 * y
        return y.toFloat()
    }

    companion object {
        fun lowPass(sampleRate: Int, freq: Float, q: Float = BUTTERWORTH_Q): Biquad {
            val (cosW, alpha) = shape(sampleRate, freq, q)
            return normalized(
                (1 - cosW) / 2, 1 - cosW, (1 - cosW) / 2,
                1 + alpha, -2 * cosW, 1 - alpha,
            )
        }

        fun highPass(sampleRate: Int, freq: Float, q: Float = BUTTERWORTH_Q): Biquad {
            val (cosW, alpha) = shape(sampleRate, freq, q)
            return normalized(
                (1 + cosW) / 2, -(1 + cosW), (1 + cosW) / 2,
                1 + alpha, -2 * cosW, 1 - alpha,
            )
        }

        /** Band-pass with 0 dB gain at the centre frequency. */
        fun bandPass(sampleRate: Int, freq: Float, q: Float): Biquad {
            val (cosW, alpha) = shape(sampleRate, freq, q)
            return normalized(alpha, 0.0, -alpha, 1 + alpha, -2 * cosW, 1 - alpha)
        }

        fun peaking(sampleRate: Int, freq: Float, gainDb: Float, q: Float): Biquad {
            val (cosW, alpha) = shape(sampleRate, freq, q)
            val a = 10.0.pow(gainDb / 40.0)
            return normalized(
                1 + alpha * a, -2 * cosW, 1 - alpha * a,
                1 + alpha / a, -2 * cosW, 1 - alpha / a,
            )
        }

        fun lowShelf(sampleRate: Int, freq: Float, gainDb: Float): Biquad {
            val (cosW, alpha) = shape(sampleRate, freq, BUTTERWORTH_Q)
            val a = 10.0.pow(gainDb / 40.0)
            val k = 2 * sqrt(a) * alpha
            return normalized(
                a * ((a + 1) - (a - 1) * cosW + k),
                2 * a * ((a - 1) - (a + 1) * cosW),
                a * ((a + 1) - (a - 1) * cosW - k),
                (a + 1) + (a - 1) * cosW + k,
                -2 * ((a - 1) + (a + 1) * cosW),
                (a + 1) + (a - 1) * cosW - k,
            )
        }

        fun highShelf(sampleRate: Int, freq: Float, gainDb: Float): Biquad {
            val (cosW, alpha) = shape(sampleRate, freq, BUTTERWORTH_Q)
            val a = 10.0.pow(gainDb / 40.0)
            val k = 2 * sqrt(a) * alpha
            return normalized(
                a * ((a + 1) + (a - 1) * cosW + k),
                -2 * a * ((a - 1) + (a + 1) * cosW),
                a * ((a + 1) + (a - 1) * cosW - k),
                (a + 1) - (a - 1) * cosW + k,
                2 * ((a - 1) - (a + 1) * cosW),
                (a + 1) - (a - 1) * cosW - k,
            )
        }

        /** Returns cos(w0) and alpha; the frequency is kept below Nyquist. */
        private fun shape(sampleRate: Int, freq: Float, q: Float): Pair<Double, Double> {
            val safeFreq = freq.toDouble().coerceIn(1.0, sampleRate * 0.49)
            val w0 = 2 * PI * safeFreq / sampleRate
            return cos(w0) to sin(w0) / (2 * q)
        }

        private fun normalized(
            b0: Double, b1: Double, b2: Double,
            a0: Double, a1: Double, a2: Double,
        ) = Biquad(b0 / a0, b1 / a0, b2 / a0, a1 / a0, a2 / a0)
    }
}
