package com.example.voicemorph_ai.core.preset

/** Allowed range and default of one effect parameter. */
data class ParamSpec(val name: String, val min: Float, val max: Float, val default: Float) {
    operator fun contains(value: Float) = value in min..max
}

/** Effect building blocks a preset chain can use, with the parameters each one accepts. */
enum class NodeType(vararg specs: ParamSpec) {
    GAIN(ParamSpec("db", -24f, 24f, 0f)),
    PITCH(ParamSpec("semitones", -12f, 12f, 0f), ParamSpec("tempo", 0.5f, 2f, 1f)),
    HIGHPASS(ParamSpec("freq", 20f, 20_000f, 100f), ParamSpec("q", 0.1f, 10f, 0.7071f)),
    LOWPASS(ParamSpec("freq", 20f, 20_000f, 8_000f), ParamSpec("q", 0.1f, 10f, 0.7071f)),
    BANDPASS(ParamSpec("freq", 20f, 20_000f, 1_000f), ParamSpec("q", 0.1f, 10f, 0.7071f)),
    PEAK(
        ParamSpec("freq", 20f, 20_000f, 1_000f),
        ParamSpec("gainDb", -24f, 24f, 0f),
        ParamSpec("q", 0.1f, 10f, 1f),
    ),
    LOW_SHELF(ParamSpec("freq", 20f, 20_000f, 200f), ParamSpec("gainDb", -24f, 24f, 0f)),
    HIGH_SHELF(ParamSpec("freq", 20f, 20_000f, 4_000f), ParamSpec("gainDb", -24f, 24f, 0f)),
    RING_MOD(ParamSpec("freq", 1f, 2_000f, 50f), ParamSpec("mix", 0f, 1f, 1f)),
    TREMOLO(ParamSpec("rate", 0.1f, 20f, 5f), ParamSpec("depth", 0f, 1f, 0.5f)),
    DISTORTION(ParamSpec("drive", 1f, 50f, 4f), ParamSpec("mix", 0f, 1f, 1f)),
    ECHO(
        ParamSpec("delayMs", 10f, 2_000f, 300f),
        ParamSpec("feedback", 0f, 0.95f, 0.4f),
        ParamSpec("mix", 0f, 1f, 0.5f),
    ),
    REVERB(
        ParamSpec("roomSize", 0f, 1f, 0.5f),
        ParamSpec("damping", 0f, 1f, 0.5f),
        ParamSpec("mix", 0f, 1f, 0.3f),
    ),
    LIMITER(ParamSpec("ceilingDb", -24f, 0f, -1f));

    val params: List<ParamSpec> = specs.toList()

    fun spec(name: String): ParamSpec? = params.firstOrNull { it.name == name }
}
