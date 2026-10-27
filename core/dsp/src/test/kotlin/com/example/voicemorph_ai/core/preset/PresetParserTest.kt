package com.example.voicemorph_ai.core.preset

import org.junit.Assert.assertEquals
import org.junit.Assert.assertThrows
import org.junit.Assert.assertTrue
import org.junit.Test

class PresetParserTest {

    @Test
    fun defaultLibraryLoadsWithUniformControls() {
        val presets = PresetLibrary.loadDefaults()

        assertEquals(12, presets.size)
        for (preset in presets) {
            assertEquals(preset.id, setOf("pitch", "speed", "echo", "reverb"), preset.controls.map { it.key }.toSet())
            assertTrue(preset.id, preset.name("vi").isNotBlank())
        }
    }

    @Test
    fun missingParamsFallBackToDefaults() {
        val preset = parseOne("""{ "type": "ECHO", "params": { "delayMs": 120 } }""")

        assertEquals(120f, preset.chain[0]["delayMs"])
        assertEquals(NodeType.ECHO.spec("feedback")!!.default, preset.chain[0]["feedback"])
    }

    @Test
    fun rejectsUnknownEffectType() {
        val error = assertThrows(PresetFormatException::class.java) { parseOne("""{ "type": "WARP" }""") }
        assertTrue(error.message!!.contains("WARP"))
    }

    @Test
    fun rejectsUnknownParameter() {
        val error = assertThrows(PresetFormatException::class.java) {
            parseOne("""{ "type": "ECHO", "params": { "speed": 1 } }""")
        }
        assertTrue(error.message!!.contains("speed"))
    }

    @Test
    fun rejectsOutOfRangeValue() {
        assertThrows(PresetFormatException::class.java) {
            parseOne("""{ "type": "PITCH", "params": { "semitones": 24 } }""")
        }
    }

    @Test
    fun rejectsControlPointingAtMissingNode() {
        assertThrows(PresetFormatException::class.java) {
            parseOne(
                """{ "type": "PITCH" }""",
                controls = """[ { "key": "pitch", "node": 3, "param": "semitones" } ]""",
            )
        }
    }

    @Test
    fun rejectsDuplicateIds() {
        val preset = presetJson("a", """{ "type": "PITCH" }""")
        assertThrows(PresetFormatException::class.java) {
            PresetParser.parseLibrary("""{ "presets": [ $preset, $preset ] }""")
        }
    }

    @Test
    fun rejectsMalformedJson() {
        assertThrows(PresetFormatException::class.java) { PresetParser.parseLibrary("{ presets: [") }
    }

    @Test
    fun controlValuesAreAppliedAndClamped() {
        val preset = parseOne(
            """{ "type": "PITCH", "params": { "semitones": 3 } }""",
            controls = """[ { "key": "pitch", "node": 0, "param": "semitones", "min": -6, "max": 6 } ]""",
        )

        assertEquals(mapOf("pitch" to 3f), preset.defaultControlValues())
        assertEquals(-2f, preset.resolveChain(mapOf("pitch" to -2f))[0]["semitones"])
        assertEquals(6f, preset.resolveChain(mapOf("pitch" to 11f))[0]["semitones"])
        assertThrows(IllegalArgumentException::class.java) { preset.resolveChain(mapOf("volume" to 1f)) }
    }

    private fun parseOne(vararg nodes: String, controls: String = "[]"): EffectPreset =
        PresetParser.parseLibrary("""{ "presets": [ ${presetJson("test", *nodes, controls = controls)} ] }""").single()

    private fun presetJson(id: String, vararg nodes: String, controls: String = "[]") =
        """{ "id": "$id", "names": { "en": "Test" }, "chain": [ ${nodes.joinToString()} ], "controls": $controls }"""
}
