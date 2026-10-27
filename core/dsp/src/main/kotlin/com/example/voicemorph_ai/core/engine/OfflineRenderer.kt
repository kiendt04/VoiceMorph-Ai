package com.example.voicemorph_ai.core.engine

import com.example.voicemorph_ai.core.AudioProcessor
import com.example.voicemorph_ai.core.dsp.SampleQueue
import kotlin.math.min

class RenderCancelledException : RuntimeException("Render was cancelled")

/** Pushes a whole buffer through a processor block by block, reporting progress. */
class OfflineRenderer(private val blockSize: Int = DEFAULT_BLOCK_SIZE) {

    init {
        require(blockSize > 0) { "blockSize must be positive: $blockSize" }
    }

    /**
     * @param onProgress called after each block with a value in 0..1, ending with exactly 1.
     * @param isCancelled polled before each block; returning true aborts with [RenderCancelledException].
     */
    fun render(
        input: FloatArray,
        processor: AudioProcessor,
        onProgress: (Float) -> Unit = {},
        isCancelled: () -> Boolean = { false },
    ): FloatArray {
        val output = SampleQueue(input.size + input.size / 4)
        val block = FloatArray(blockSize)
        var position = 0
        while (position < input.size) {
            if (isCancelled()) throw RenderCancelledException()
            val frames = min(blockSize, input.size - position)
            input.copyInto(block, 0, position, position + frames)
            output.addAll(processor.process(block, frames))
            position += frames
            onProgress(position.toFloat() / input.size * PROCESS_SHARE)
        }
        if (isCancelled()) throw RenderCancelledException()
        output.addAll(processor.flush())
        onProgress(1f)
        return output.toArray()
    }

    private companion object {
        const val DEFAULT_BLOCK_SIZE = 4096

        /** Flushing tails is the last few percent of the work. */
        const val PROCESS_SHARE = 0.98f
    }
}
