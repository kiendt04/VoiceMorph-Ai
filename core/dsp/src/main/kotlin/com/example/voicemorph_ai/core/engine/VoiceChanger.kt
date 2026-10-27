package com.example.voicemorph_ai.core.engine

import com.example.voicemorph_ai.core.io.WavIO
import com.example.voicemorph_ai.core.preset.EffectPreset
import java.io.File
import kotlin.math.min

/**
 * Entry point of the voice-changing core: applies a preset (plus the user's slider values) to
 * mono audio. Everything is synchronous and CPU-bound; callers run it on a background thread and
 * map coroutine cancellation to [isCancelled].
 */
class VoiceChanger(private val renderer: OfflineRenderer = OfflineRenderer()) {

    fun render(
        audio: FloatArray,
        sampleRate: Int,
        preset: EffectPreset,
        controlValues: Map<String, Float> = emptyMap(),
        onProgress: (Float) -> Unit = {},
        isCancelled: () -> Boolean = { false },
    ): FloatArray {
        val chain = EffectFactory.createChain(preset.resolveChain(controlValues), sampleRate)
        return renderer.render(audio, chain, onProgress, isCancelled)
    }

    /** Fast render of only the first [maxSeconds] for previewing while the user adjusts sliders. */
    fun renderPreview(
        audio: FloatArray,
        sampleRate: Int,
        preset: EffectPreset,
        controlValues: Map<String, Float> = emptyMap(),
        maxSeconds: Float = DEFAULT_PREVIEW_SECONDS,
        isCancelled: () -> Boolean = { false },
    ): FloatArray {
        val frames = min(audio.size, (maxSeconds * sampleRate).toInt())
        return render(audio.copyOf(frames), sampleRate, preset, controlValues, isCancelled = isCancelled)
    }

    /**
     * Renders a WAV file into a 16-bit mono WAV. The result is written to a temporary file and
     * moved into place only on success, so a failed or cancelled render never leaves a partial
     * [output] behind.
     */
    fun renderFile(
        input: File,
        output: File,
        preset: EffectPreset,
        controlValues: Map<String, Float> = emptyMap(),
        onProgress: (Float) -> Unit = {},
        isCancelled: () -> Boolean = { false },
    ) {
        val source = WavIO.read(input)
        val rendered = render(source.samples, source.sampleRate, preset, controlValues, onProgress, isCancelled)
        val temp = File(output.parentFile, "${output.name}.tmp")
        try {
            WavIO.write(temp, rendered, source.sampleRate)
            if (output.exists() && !output.delete()) error("Cannot replace $output")
            if (!temp.renameTo(output)) error("Cannot move $temp to $output")
        } finally {
            temp.delete()
        }
    }

    companion object {
        const val DEFAULT_PREVIEW_SECONDS = 10f
    }
}
