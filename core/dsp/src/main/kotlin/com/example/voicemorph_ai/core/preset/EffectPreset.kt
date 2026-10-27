package com.example.voicemorph_ai.core.preset

/** One effect in a chain; [params] always holds every parameter of [type]. */
data class EffectNode(val type: NodeType, val params: Map<String, Float>) {

    operator fun get(param: String): Float =
        params[param] ?: throw IllegalArgumentException("$type has no parameter \"$param\"")

    fun with(param: String, value: Float): EffectNode {
        val spec = type.spec(param) ?: throw IllegalArgumentException("$type has no parameter \"$param\"")
        require(value in spec) { "$type.$param = $value is outside ${spec.min}..${spec.max}" }
        return copy(params = params + (param to value))
    }

    companion object {
        /** Builds a node, filling unspecified parameters with their defaults. */
        fun of(type: NodeType, vararg values: Pair<String, Float>): EffectNode =
            values.fold(EffectNode(type, type.params.associate { it.name to it.default })) { node, (name, value) ->
                node.with(name, value)
            }
    }
}

/**
 * A slider exposed to the user ("pitch", "speed", "echo"...) bound to one parameter of one node.
 * [min]..[max] is the slider range and lies within the parameter's allowed range.
 */
data class ControlBinding(
    val key: String,
    val nodeIndex: Int,
    val param: String,
    val min: Float,
    val max: Float,
)

/** A voice effect: an ordered chain of nodes plus the controls the user may tweak. */
data class EffectPreset(
    val id: String,
    val names: Map<String, String>,
    val category: String,
    val isPro: Boolean,
    val version: Int,
    val chain: List<EffectNode>,
    val controls: List<ControlBinding>,
) {
    /** Display name in [language] ("vi", "en"), falling back to English, then to the id. */
    fun name(language: String): String = names[language] ?: names["en"] ?: id

    fun defaultControlValues(): Map<String, Float> =
        controls.associate { it.key to chain[it.nodeIndex][it.param] }

    /**
     * The chain with the user's control values applied. Values are clamped to each control's
     * range; an unknown key is a programming error and throws.
     */
    fun resolveChain(controlValues: Map<String, Float> = emptyMap()): List<EffectNode> {
        if (controlValues.isEmpty()) return chain
        val nodes = chain.toMutableList()
        for ((key, value) in controlValues) {
            val control = controls.firstOrNull { it.key == key }
                ?: throw IllegalArgumentException("Preset \"$id\" has no control \"$key\"")
            require(!value.isNaN()) { "Control \"$key\" is NaN" }
            nodes[control.nodeIndex] = nodes[control.nodeIndex].with(control.param, value.coerceIn(control.min, control.max))
        }
        return nodes
    }
}
