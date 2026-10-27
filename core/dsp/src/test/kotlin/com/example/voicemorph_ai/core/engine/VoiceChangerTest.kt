package com.example.voicemorph_ai.core.engine

import com.example.voicemorph_ai.core.TestSignals.SAMPLE_RATE
import com.example.voicemorph_ai.core.TestSignals.peak
import com.example.voicemorph_ai.core.TestSignals.voiceLike
import com.example.voicemorph_ai.core.io.WavIO
import com.example.voicemorph_ai.core.preset.PresetLibrary
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertThrows
import org.junit.Assert.assertTrue
import org.junit.Rule
import org.junit.Test
import org.junit.rules.TemporaryFolder
import kotlin.math.pow

class VoiceChangerTest {
    @get:Rule
    val folder = TemporaryFolder()

    private val presets = PresetLibrary.loadDefaults()
    private val changer = VoiceChanger()
    private val ceiling = 10f.pow(-1f / 20f)

    @Test
    fun everyDefaultPresetProducesCleanAudio() {
        val input = voiceLike(3.0)
        for (preset in presets) {
            val output = changer.render(input, SAMPLE_RATE, preset)
            val tempo = preset.chain.first()["tempo"]

            assertTrue(preset.id, output.all { it.isFinite() })
            assertTrue("${preset.id} clips: ${peak(output)}", peak(output) <= ceiling + 1e-6f)
            assertTrue("${preset.id} too short: ${output.size}", output.size >= (input.size / tempo).toInt() - 1)
            assertTrue("${preset.id} is silent", peak(output) > 0.05f)
        }
    }

    @Test
    fun userControlsChangeTheResult() {
        val cave = presets.first { it.id == "cave" }
        val input = voiceLike(1.0)
        val dry = changer.render(input, SAMPLE_RATE, cave, mapOf("echo" to 0f, "reverb" to 0f))
        val wet = changer.render(input, SAMPLE_RATE, cave)

        assertEquals(input.size, dry.size)
        assertTrue("echo and reverb add a tail", wet.size > dry.size)
    }

    @Test
    fun previewOnlyRendersTheFirstSeconds() {
        val chipmunk = presets.first { it.id == "chipmunk" }
        val output = changer.renderPreview(voiceLike(15.0), SAMPLE_RATE, chipmunk, maxSeconds = 2f)

        assertEquals(2 * SAMPLE_RATE / 1.1, output.size.toDouble(), 2.0)
    }

    @Test
    fun progressEndsAtOneAndIsMonotonic() {
        val progress = mutableListOf<Float>()
        changer.render(voiceLike(1.0), SAMPLE_RATE, presets.first(), onProgress = { progress += it })

        assertEquals(1f, progress.last())
        assertEquals(progress.sorted(), progress)
    }

    @Test
    fun cancellationAbortsTheRender() {
        var polls = 0
        assertThrows(RenderCancelledException::class.java) {
            changer.render(voiceLike(2.0), SAMPLE_RATE, presets.first(), isCancelled = { ++polls > 3 })
        }
    }

    @Test
    fun renderFileWritesWavAndLeavesNoTempFile() {
        val input = folder.newFile("original.wav")
        val output = folder.root.resolve("render.wav")
        WavIO.write(input, voiceLike(1.0), SAMPLE_RATE)

        changer.renderFile(input, output, presets.first { it.id == "robot" })

        val result = WavIO.read(output)
        assertEquals(SAMPLE_RATE, result.sampleRate)
        assertTrue(result.samples.size >= SAMPLE_RATE)
        assertFalse(folder.root.resolve("render.wav.tmp").exists())
    }

    @Test
    fun cancelledFileRenderLeavesNoOutput() {
        val input = folder.newFile("original.wav")
        val output = folder.root.resolve("render.wav")
        WavIO.write(input, voiceLike(1.0), SAMPLE_RATE)

        assertThrows(RenderCancelledException::class.java) {
            changer.renderFile(input, output, presets.first(), isCancelled = { true })
        }
        assertFalse(output.exists())
    }

    /** Target from the spec: a 1-minute clip in under 5 s on a mid-range phone. Desktop is a rough proxy. */
    @Test
    fun oneMinuteRendersQuickly() {
        val input = voiceLike(60.0)
        changer.render(input.copyOf(SAMPLE_RATE), SAMPLE_RATE, presets.first()) // JIT warm-up
        for (id in listOf("ghost", "chipmunk", "monster")) {
            val start = System.nanoTime()
            changer.render(input, SAMPLE_RATE, presets.first { it.id == id })
            val ms = (System.nanoTime() - start) / 1_000_000
            println("Render 60 s with $id: $ms ms")
            assertTrue("$id took $ms ms", ms < 5_000)
        }
    }
}
