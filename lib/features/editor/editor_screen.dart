import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:voice_core/voice_core.dart';

import '../common/waveform.dart';
import '../flow/flow_args.dart';

/// Thông tin nguồn đọc một lần ở isolate (tránh đọc file lớn trên UI).
class _SourceInfo {
  const _SourceInfo({
    required this.peaks,
    required this.sampleRate,
    required this.totalSamples,
  });

  final Float32List peaks;
  final int sampleRate;
  final int totalSamples;
}

/// Màn FineTune: slider map đúng `controls` của preset, nghe thử 10 giây đầu.
/// Preview chạy ở isolate; đổi slider liên tục thì preview cũ bị hủy bằng
/// token (kết quả cũ về sau sẽ bị bỏ qua, không phát nhầm).
class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key, required this.args});

  final EditorArgs args;

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  final _player = AudioPlayer();
  late Map<String, double> _controls;
  _SourceInfo? _source;
  String? _loadError;

  var _previewToken = 0;
  var _previewBusy = false;
  var _playing = false;
  String? _previewPath;

  @override
  void initState() {
    super.initState();
    _controls = widget.args.preset.defaultControlValues();
    _loadSource();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _loadSource() async {
    try {
      final path = widget.args.source.path;
      final info = await Isolate.run(() {
        final audio = WavIO.readFile(path);
        return _SourceInfo(
          peaks: computePeaks(audio.samples, 64),
          sampleRate: audio.sampleRate,
          totalSamples: audio.samples.length,
        );
      });
      if (mounted) setState(() => _source = info);
    } catch (e) {
      if (mounted) setState(() => _loadError = 'Không đọc được file nguồn: $e');
    }
  }

  Future<void> _playPreview() async {
    if (_playing) {
      await _player.pause();
      if (mounted) setState(() => _playing = false);
      return;
    }
    final token = ++_previewToken;
    setState(() => _previewBusy = true);
    try {
      final path = widget.args.source.path;
      final preset = widget.args.preset;
      final controls = Map<String, double>.from(_controls);
      final bytes = await Isolate.run(() {
        final audio = WavIO.readFile(path);
        final rendered = VoiceChanger().renderPreview(
          audio.samples,
          audio.sampleRate,
          preset,
          controlValues: controls,
        );
        return WavIO.encode(rendered, audio.sampleRate);
      });
      if (!mounted || token != _previewToken) return;
      final temp = await getTemporaryDirectory();
      final previewPath =
          '${temp.path}/preview_${DateTime.now().millisecondsSinceEpoch}.wav';
      await File(previewPath).writeAsBytes(bytes, flush: true);
      if (!mounted || token != _previewToken) return;
      final old = _previewPath;
      _previewPath = previewPath;
      if (old != null && File(old).existsSync()) {
        try {
          File(old).deleteSync();
        } catch (_) {}
      }
      await _player.setFilePath(previewPath);
      await _player.play();
      if (mounted) setState(() => _playing = true);
      _player.playerStateStream.firstWhere(
        (s) => s.processingState == ProcessingState.completed,
      ).then((_) {
        if (mounted) setState(() => _playing = false);
      });
    } catch (e) {
      if (mounted && token == _previewToken) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không nghe thử được: $e')),
        );
      }
    } finally {
      if (mounted && token == _previewToken) {
        setState(() => _previewBusy = false);
      }
    }
  }

  void _onSlider(String key, double value) {
    // Đổi slider thì hủy preview đang phát/chuẩn bị, tránh phát nhầm bản cũ.
    _previewToken++;
    _player.stop();
    setState(() {
      _controls[key] = value;
      _playing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final preset = widget.args.preset;
    final source = _source;
    return Scaffold(
      appBar: AppBar(title: Text('Chỉnh: ${preset.name('vi')}')),
      body: _loadError != null
          ? Center(child: Text(_loadError!))
          : source == null
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Nguồn: ${widget.args.source.name}'),
                          Text(
                            'Độ dài: ${(source.totalSamples / source.sampleRate).toStringAsFixed(1)} giây',
                          ),
                          const SizedBox(height: 12),
                          // Waveform từ PCM thật (64 cột). Nguồn MP3/M4A
                          // đã được giải mã về WAV ở Home nên đọc thẳng
                          // bằng WavIO như trước.
                          WaveformBars(peaks: source.peaks),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                          for (final control in preset.controls)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${control.key} (${control.param})',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      _controls[control.key]!
                                          .toStringAsFixed(2),
                                    ),
                                  ],
                                ),
                                Slider(
                                  value: _controls[control.key]!,
                                  min: control.min,
                                  max: control.max,
                                  onChanged: (v) => _onSlider(control.key, v),
                                ),
                              ],
                            ),
                          if (preset.controls.isEmpty)
                            const Text(
                              'Preset này không có thanh trượt — dùng nguyên bản thiết kế của preset.',
                            ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _previewBusy ? null : _playPreview,
                              icon: Icon(
                                _playing ? Icons.pause : Icons.play_arrow,
                              ),
                              label: Text(
                                _previewBusy
                                    ? 'Đang tạo bản nghe thử...'
                                    : _playing
                                        ? 'Dừng nghe thử'
                                        : 'Nghe thử 10 giây',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                _previewToken++;
                                _player.stop();
                                context.push(
                                  '/processing',
                                  extra: ProcessingArgs(
                                    source: widget.args.source,
                                    preset: preset,
                                    controlValues:
                                        Map<String, double>.from(_controls),
                                  ),
                                );
                              },
                              child: const Text('Xử lý toàn file'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}
