package com.example.voicemorph_ai.core

/**
 * A streaming mono audio effect.
 *
 * Blocks are pushed in order with [process]; after the last block the caller calls [flush] once
 * to collect whatever the effect still holds (reverb/echo tails, buffered input). Processors are
 * block-based so the same code can later run in a realtime engine.
 */
interface AudioProcessor {
    /**
     * Processes the first [frames] samples of [input] and returns a new array with the produced
     * samples. Its size may differ from [frames] for effects that change duration.
     */
    fun process(input: FloatArray, frames: Int = input.size): FloatArray

    /** Returns the remaining output after the last block. */
    fun flush(): FloatArray = FloatArray(0)
}

/** Base for effects that map one input sample to one output sample. */
abstract class SampleProcessor : AudioProcessor {
    /**
     * Maximum number of samples emitted by [flush] for effects with memory (echo, reverb).
     * Trailing silence in the tail is trimmed.
     */
    protected open val tailSamples: Int = 0

    protected abstract fun processSample(x: Float): Float

    override fun process(input: FloatArray, frames: Int): FloatArray =
        FloatArray(frames) { processSample(input[it]) }

    override fun flush(): FloatArray {
        if (tailSamples <= 0) return FloatArray(0)
        val tail = FloatArray(tailSamples) { processSample(0f) }
        var last = tail.size - 1
        while (last >= 0 && kotlin.math.abs(tail[last]) < SILENCE_THRESHOLD) last--
        return tail.copyOf(last + 1)
    }

    private companion object {
        const val SILENCE_THRESHOLD = 1e-4f // -80 dBFS
    }
}

/** Runs processors in series; each stage's flushed tail still passes through the later stages. */
class ProcessorChain(private val stages: List<AudioProcessor>) : AudioProcessor {

    override fun process(input: FloatArray, frames: Int): FloatArray {
        if (stages.isEmpty()) return input.copyOf(frames)
        var buffer = input
        var count = frames
        for (stage in stages) {
            buffer = stage.process(buffer, count)
            count = buffer.size
        }
        return buffer
    }

    override fun flush(): FloatArray {
        var carry = FloatArray(0)
        for (stage in stages) {
            val processed = if (carry.isEmpty()) carry else stage.process(carry, carry.size)
            carry = processed + stage.flush()
        }
        return carry
    }
}
