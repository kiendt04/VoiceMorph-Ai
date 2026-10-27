package com.example.voicemorph_ai.core.dsp

import kotlin.math.max
import kotlin.math.min

/** Growable FIFO of samples: append at the back, drop from the front. */
class SampleQueue(initialCapacity: Int = 4096) {
    private var data = FloatArray(max(initialCapacity, 16))
    private var start = 0

    var size = 0
        private set

    /** Backing array for hot loops; live samples are at [offset] until [offset] + [size]. */
    val array: FloatArray get() = data
    val offset: Int get() = start

    operator fun get(index: Int): Float = data[start + index]

    fun add(value: Float) {
        ensureCapacity(1)
        data[start + size] = value
        size++
    }

    fun addAll(source: FloatArray, from: Int = 0, count: Int = source.size - from) {
        ensureCapacity(count)
        source.copyInto(data, start + size, from, from + count)
        size += count
    }

    fun drop(count: Int) {
        val dropped = min(count, size)
        start += dropped
        size -= dropped
        if (size == 0) start = 0
    }

    fun toArray(): FloatArray = data.copyOfRange(start, start + size)

    private fun ensureCapacity(extra: Int) {
        if (start + size + extra <= data.size) return
        val needed = size + extra
        // Compact in place only when it frees plenty of room, otherwise grow to keep appends O(1).
        val target = if (needed <= data.size / 2) data else FloatArray(max(needed, data.size * 2))
        data.copyInto(target, 0, start, start + size)
        data = target
        start = 0
    }
}
