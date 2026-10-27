package com.example.voicemorph_ai.core.preset

import org.json.JSONException
import org.json.JSONObject

class PresetFormatException(message: String, cause: Throwable? = null) : IllegalArgumentException(message, cause)

/**
 * Parses and validates a preset library:
 *
 * ```json
 * { "presets": [ {
 *     "id": "cave", "names": { "vi": "Hang động", "en": "Cave" }, "category": "place",
 *     "isPro": false, "version": 1,
 *     "chain": [ { "type": "ECHO", "params": { "delayMs": 280 } } ],
 *     "controls": [ { "key": "echo", "node": 0, "param": "mix", "min": 0, "max": 1 } ]
 * } ] }
 * ```
 *
 * Every mistake (unknown effect or parameter, value out of range, dangling control) is rejected
 * with a message naming the preset and field, so a bad preset never reaches the engine.
 */
object PresetParser {

    fun parseLibrary(json: String): List<EffectPreset> {
        val presets = wrapJsonErrors("library") {
            val array = JSONObject(json).optJSONArray("presets")
                ?: throw PresetFormatException("Missing \"presets\" array")
            (0 until array.length()).map { parsePreset(array.getJSONObject(it)) }
        }
        val duplicate = presets.groupBy { it.id }.entries.firstOrNull { it.value.size > 1 }
        if (duplicate != null) throw PresetFormatException("Duplicate preset id \"${duplicate.key}\"")
        return presets
    }

    fun parsePreset(json: JSONObject): EffectPreset = wrapJsonErrors(json.optString("id", "?")) {
        val id = json.getString("id")
        if (id.isBlank()) throw PresetFormatException("Preset id is blank")

        val namesJson = json.getJSONObject("names")
        val names = namesJson.keys().asSequence().associateWith { namesJson.getString(it) }
        if (names.isEmpty()) fail(id, "names is empty")

        val chainJson = json.getJSONArray("chain")
        if (chainJson.length() == 0) fail(id, "chain is empty")
        val chain = (0 until chainJson.length()).map { parseNode(id, it, chainJson.getJSONObject(it)) }

        val controlsJson = json.optJSONArray("controls")
        val controls = if (controlsJson == null) emptyList() else
            (0 until controlsJson.length()).map { parseControl(id, chain, controlsJson.getJSONObject(it)) }
        val duplicateKey = controls.groupBy { it.key }.entries.firstOrNull { it.value.size > 1 }?.key
        if (duplicateKey != null) fail(id, "duplicate control \"$duplicateKey\"")

        EffectPreset(
            id = id,
            names = names,
            category = json.optString("category", "other"),
            isPro = json.optBoolean("isPro", false),
            version = json.optInt("version", 1),
            chain = chain,
            controls = controls,
        )
    }

    private fun parseNode(presetId: String, index: Int, json: JSONObject): EffectNode {
        val where = "chain[$index]"
        val typeName = json.getString("type")
        val type = NodeType.entries.firstOrNull { it.name == typeName }
            ?: fail(presetId, "$where: unknown effect type \"$typeName\"")

        var node = EffectNode.of(type)
        val params = json.optJSONObject("params") ?: return node
        for (name in params.keys()) {
            val spec = type.spec(name) ?: fail(presetId, "$where: $typeName has no parameter \"$name\"")
            val value = params.getDouble(name).toFloat()
            if (value !in spec) fail(presetId, "$where: $name = $value is outside ${spec.min}..${spec.max}")
            node = node.with(name, value)
        }
        return node
    }

    private fun parseControl(presetId: String, chain: List<EffectNode>, json: JSONObject): ControlBinding {
        val key = json.getString("key")
        val where = "control \"$key\""
        val nodeIndex = json.getInt("node")
        val node = chain.getOrNull(nodeIndex) ?: fail(presetId, "$where: node $nodeIndex does not exist")
        val param = json.getString("param")
        val spec = node.type.spec(param) ?: fail(presetId, "$where: ${node.type} has no parameter \"$param\"")
        val min = json.optDouble("min", spec.min.toDouble()).toFloat()
        val max = json.optDouble("max", spec.max.toDouble()).toFloat()
        if (min >= max || min !in spec || max !in spec) {
            fail(presetId, "$where: range $min..$max must be increasing and within ${spec.min}..${spec.max}")
        }
        if (node[param] !in min..max) fail(presetId, "$where: default ${node[param]} is outside $min..$max")
        return ControlBinding(key, nodeIndex, param, min, max)
    }

    private fun fail(presetId: String, message: String): Nothing =
        throw PresetFormatException("Preset \"$presetId\": $message")

    private inline fun <T> wrapJsonErrors(context: String, block: () -> T): T = try {
        block()
    } catch (e: JSONException) {
        throw PresetFormatException("Invalid preset JSON ($context): ${e.message}", e)
    }
}
