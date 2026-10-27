import 'dart:math' as math;
import 'dart:typed_data';

/// Growable FIFO of samples: append at the back, drop from the front.
class SampleQueue {
  SampleQueue([int initialCapacity = 4096])
      : _data = Float32List(math.max(initialCapacity, 16));

  Float32List _data;
  int _start = 0;
  int _length = 0;

  int get length => _length;

  /// Backing list for hot loops; live samples are at [offset] until
  /// [offset] + [length].
  Float32List get buffer => _data;
  int get offset => _start;

  double operator [](int index) => _data[_start + index];

  void add(double value) {
    _ensureCapacity(1);
    _data[_start + _length] = value;
    _length++;
  }

  void addAll(Float32List source, [int from = 0, int? count]) {
    final n = count ?? source.length - from;
    _ensureCapacity(n);
    final end = _start + _length;
    _data.setRange(end, end + n, source, from);
    _length += n;
  }

  void drop(int count) {
    final dropped = math.min(count, _length);
    _start += dropped;
    _length -= dropped;
    if (_length == 0) _start = 0;
  }

  Float32List toFloat32List() => _data.sublist(_start, _start + _length);

  void _ensureCapacity(int extra) {
    if (_start + _length + extra <= _data.length) return;
    final needed = _length + extra;
    // Compact in place only when it frees plenty of room, otherwise grow to
    // keep appends O(1).
    final target = needed <= _data.length ~/ 2
        ? _data
        : Float32List(math.max(needed, _data.length * 2));
    target.setRange(0, _length, _data, _start);
    _data = target;
    _start = 0;
  }
}
