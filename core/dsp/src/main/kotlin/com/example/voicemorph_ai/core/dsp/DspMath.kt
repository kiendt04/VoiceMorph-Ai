package com.example.voicemorph_ai.core.dsp

import kotlin.math.pow
import kotlin.math.roundToInt

internal fun dbToLinear(db: Float): Float = 10f.pow(db / 20f)

internal fun msToSamples(sampleRate: Int, ms: Double): Int = (sampleRate * ms / 1000.0).roundToInt()

/** Q giving a maximally flat (Butterworth) 2nd-order response. */
internal const val BUTTERWORTH_Q = 0.7071f
