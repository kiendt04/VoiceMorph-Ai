package com.example.voicemorph_ai.core.preset

/** Built-in presets shipped as a resource of this module. */
object PresetLibrary {
    private const val DEFAULT_RESOURCE = "/presets/default_presets.json"

    fun loadDefaults(): List<EffectPreset> {
        val stream = PresetLibrary::class.java.getResourceAsStream(DEFAULT_RESOURCE)
            ?: error("Missing resource $DEFAULT_RESOURCE")
        return PresetParser.parseLibrary(stream.bufferedReader(Charsets.UTF_8).use { it.readText() })
    }
}
