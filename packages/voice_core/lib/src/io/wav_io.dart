import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

class WavFormatException extends FormatException {
  const WavFormatException(super.message);
}

/// Mono audio as floats in -1..1.
class WavAudio {
  const WavAudio(this.samples, this.sampleRate);

  final Float32List samples;
  final int sampleRate;

  Duration get duration => Duration(microseconds: samples.length * 1000000 ~/ sampleRate);
}

/// Minimal WAV codec. Reads PCM 8/16/24/32-bit and 32-bit float (including
/// WAVE_FORMAT_EXTENSIBLE), downmixing any channel count to mono. Writes
/// 16-bit mono PCM.
abstract final class WavIO {
  static const _formatPcm = 1;
  static const _formatFloat = 3;
  static const _formatExtensible = 0xFFFE;

  static WavAudio readFile(String path) => decode(File(path).readAsBytesSync());

  static void writeFile(String path, Float32List samples, int sampleRate) =>
      File(path).writeAsBytesSync(encode(samples, sampleRate), flush: true);

  static WavAudio decode(Uint8List bytes) {
    final data = ByteData.sublistView(bytes);
    if (bytes.length < 12 || _tag(bytes, 0) != 'RIFF' || _tag(bytes, 8) != 'WAVE') {
      throw const WavFormatException('Not a RIFF/WAVE file');
    }

    var format = -1;
    var channels = 0;
    var sampleRate = 0;
    var bits = 0;
    var dataStart = -1;
    var dataSize = 0;
    var position = 12;
    while (position + 8 <= bytes.length) {
      final size = data.getUint32(position + 4, Endian.little);
      final body = position + 8;
      final available = math.min(size, bytes.length - body);
      switch (_tag(bytes, position)) {
        case 'fmt ':
          if (available < 16) throw const WavFormatException('fmt chunk too short');
          format = data.getUint16(body, Endian.little);
          channels = data.getUint16(body + 2, Endian.little);
          sampleRate = data.getUint32(body + 4, Endian.little);
          bits = data.getUint16(body + 14, Endian.little);
          if (format == _formatExtensible && available >= 26) {
            format = data.getUint16(body + 24, Endian.little);
          }
        case 'data':
          dataStart = body;
          dataSize = available;
      }
      position = body + size + (size & 1);
    }

    if (format < 0) throw const WavFormatException('Missing fmt chunk');
    if (dataStart < 0) throw const WavFormatException('Missing data chunk');
    if (channels <= 0 || sampleRate <= 0) {
      throw const WavFormatException('Invalid channels/sample rate');
    }
    final supported = (format == _formatPcm && const [8, 16, 24, 32].contains(bits)) ||
        (format == _formatFloat && bits == 32);
    if (!supported) throw WavFormatException('Unsupported encoding: format $format, $bits bits');

    final bytesPerSample = bits ~/ 8;
    final frameSize = bytesPerSample * channels;
    final samples = Float32List(dataSize ~/ frameSize);
    for (var frame = 0; frame < samples.length; frame++) {
      var sum = 0.0;
      for (var channel = 0; channel < channels; channel++) {
        final offset = dataStart + frame * frameSize + channel * bytesPerSample;
        sum += _readSample(data, offset, format, bits);
      }
      samples[frame] = sum / channels;
    }
    return WavAudio(samples, sampleRate);
  }

  static Uint8List encode(Float32List samples, int sampleRate) {
    final dataSize = samples.length * 2;
    final bytes = Uint8List(44 + dataSize);
    final data = ByteData.sublistView(bytes);
    void tag(int offset, String value) => bytes.setRange(offset, offset + 4, value.codeUnits);

    tag(0, 'RIFF');
    data.setUint32(4, 36 + dataSize, Endian.little);
    tag(8, 'WAVE');
    tag(12, 'fmt ');
    data.setUint32(16, 16, Endian.little);
    data.setUint16(20, _formatPcm, Endian.little);
    data.setUint16(22, 1, Endian.little);
    data.setUint32(24, sampleRate, Endian.little);
    data.setUint32(28, sampleRate * 2, Endian.little);
    data.setUint16(32, 2, Endian.little);
    data.setUint16(34, 16, Endian.little);
    tag(36, 'data');
    data.setUint32(40, dataSize, Endian.little);
    for (var i = 0; i < samples.length; i++) {
      final sample = samples[i];
      final clamped = sample.isNaN ? 0.0 : sample.clamp(-1.0, 1.0);
      data.setInt16(44 + i * 2, (clamped * 32767).round(), Endian.little);
    }
    return bytes;
  }

  static double _readSample(ByteData data, int offset, int format, int bits) {
    if (format == _formatFloat) return data.getFloat32(offset, Endian.little);
    return switch (bits) {
      8 => (data.getUint8(offset) - 128) / 128,
      16 => data.getInt16(offset, Endian.little) / 32768,
      24 => (data.getUint8(offset) |
              (data.getUint8(offset + 1) << 8) |
              (data.getInt8(offset + 2) << 16)) /
          8388608,
      _ => data.getInt32(offset, Endian.little) / 2147483648,
    };
  }

  static String _tag(Uint8List bytes, int offset) =>
      String.fromCharCodes(bytes, offset, offset + 4);
}
