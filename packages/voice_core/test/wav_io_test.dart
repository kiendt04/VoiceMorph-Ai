import 'dart:convert';
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:voice_core/voice_core.dart';

import 'test_signals.dart';

Uint8List floatWav(List<double> samples, {required int channels, required int sampleRate}) {
  final dataSize = samples.length * 4;
  final bytes = Uint8List(44 + dataSize);
  final data = ByteData.sublistView(bytes);
  void tag(int offset, String value) => bytes.setRange(offset, offset + 4, ascii.encode(value));
  tag(0, 'RIFF');
  data.setUint32(4, 36 + dataSize, Endian.little);
  tag(8, 'WAVE');
  tag(12, 'fmt ');
  data.setUint32(16, 16, Endian.little);
  data.setUint16(20, 3, Endian.little);
  data.setUint16(22, channels, Endian.little);
  data.setUint32(24, sampleRate, Endian.little);
  data.setUint32(28, sampleRate * channels * 4, Endian.little);
  data.setUint16(32, channels * 4, Endian.little);
  data.setUint16(34, 32, Endian.little);
  tag(36, 'data');
  data.setUint32(40, dataSize, Endian.little);
  for (var i = 0; i < samples.length; i++) {
    data.setFloat32(44 + i * 4, samples[i], Endian.little);
  }
  return bytes;
}

void main() {
  test('round-trips PCM16', () {
    final samples = sine(440, 0.1);
    final audio = WavIO.decode(WavIO.encode(samples, 22050));

    expect(audio.sampleRate, 22050);
    expect(audio.samples.length, samples.length);
    for (var i = 0; i < samples.length; i++) {
      expect(audio.samples[i], closeTo(samples[i], 1 / 16000));
    }
  });

  test('downmixes stereo float', () {
    final audio = WavIO.decode(floatWav([0.5, -0.5, 1, 0], channels: 2, sampleRate: 48000));

    expect(audio.sampleRate, 48000);
    expect(audio.samples, [0, 0.5]);
  });

  test('clamps out-of-range and NaN samples when writing', () {
    final audio = WavIO.decode(WavIO.encode(Float32List.fromList([2, -2, double.nan]), 8000));

    expect(audio.samples[0], closeTo(1, 1e-4));
    expect(audio.samples[1], closeTo(-1, 1e-4));
    expect(audio.samples[2], 0);
  });

  test('rejects non-WAV data', () {
    expect(() => WavIO.decode(Uint8List.fromList(ascii.encode('ID3 this is an mp3'))),
        throwsA(isA<WavFormatException>()));
  });
}
