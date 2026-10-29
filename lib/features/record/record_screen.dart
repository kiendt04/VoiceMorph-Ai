import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

import '../flow/flow_args.dart';

/// Màn ghi âm: ghi WAV 44.1kHz mono, đếm thời gian, sóng âm trực tiếp từ
/// biên độ mic. Ghi xong -> sang màn chọn hiệu ứng với file vừa ghi.
class RecordScreen extends StatefulWidget {
  const RecordScreen({super.key});

  @override
  State<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends State<RecordScreen> {
  final _recorder = AudioRecorder();
  StreamSubscription<Amplitude>? _amplitudeSub;
  Timer? _timer;

  var _recording = false;
  var _seconds = 0;
  var _level = 0.0; // 0..1, từ biên độ mic
  var _busy = false;
  String? _error;

  @override
  void dispose() {
    _timer?.cancel();
    _amplitudeSub?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      var status = await Permission.microphone.status;
      if (!status.isGranted) {
        status = await Permission.microphone.request();
      }
      if (!status.isGranted) {
        if (status.isPermanentlyDenied && mounted) {
          await _showDeniedDialog();
        } else if (mounted) {
          setState(() => _error = 'Chưa có quyền micro nên chưa ghi được.');
        }
        return;
      }
      if (!await _recorder.hasPermission()) {
        if (mounted) {
          setState(() => _error = 'Thiết bị không cho phép ghi âm lúc này.');
        }
        return;
      }
      final temp = await getTemporaryDirectory();
      final dir = Directory('${temp.path}/recordings');
      if (!dir.existsSync()) dir.createSync(recursive: true);
      final path =
          '${dir.path}/rec_${DateTime.now().millisecondsSinceEpoch}.wav';
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 44100,
          numChannels: 1,
        ),
        path: path,
      );
      _amplitudeSub = _recorder
          .onAmplitudeChanged(const Duration(milliseconds: 100))
          .listen((amp) {
        if (!mounted) return;
        final max = amp.max <= 0 ? 1 : amp.max;
        setState(() => _level = (amp.current / max).clamp(0.0, 1.0));
      });
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() => _seconds++);
      });
      setState(() {
        _recording = true;
        _seconds = 0;
      });
    } catch (e) {
      // Mất quyền giữa chừng hoặc mic bận: báo rõ, không crash.
      if (mounted) setState(() => _error = 'Không ghi được: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _showDeniedDialog() async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cần quyền micro'),
        content: const Text(
          'Quyền micro đã bị từ chối vĩnh viễn. Mở Cài đặt để bật lại nhé.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Để sau'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings();
            },
            child: const Text('Mở Cài đặt'),
          ),
        ],
      ),
    );
  }

  Future<void> _stop({bool keep = true}) async {
    _timer?.cancel();
    await _amplitudeSub?.cancel();
    _amplitudeSub = null;
    String? path;
    try {
      path = await _recorder.stop();
    } catch (e) {
      if (mounted) setState(() => _error = 'Không dừng được bản ghi: $e');
    }
    if (!mounted) return;
    setState(() {
      _recording = false;
      _level = 0;
    });
    if (keep && path != null && path.isNotEmpty) {
      context.push(
        '/effects',
        extra: EffectsArgs(
          source: SourceArgs(path: path, name: 'Bản ghi $_seconds giây'),
        ),
      );
    }
  }

  String get _timeText {
    final m = (_seconds ~/ 60).toString().padLeft(2, '0');
    final s = (_seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ghi âm')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _timeText,
              style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            // Sóng âm đơn giản: 24 cột, cao theo biên độ mic hiện tại.
            SizedBox(
              height: 80,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < 24; i++)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      width: 6,
                      height: 12 + _level * 64 * (0.4 + 0.6 * ((i % 5) / 4)),
                      decoration: BoxDecoration(
                        color: _recording
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _recording
                  ? 'Đang ghi... bấm Dừng khi nói xong'
                  : 'Bấm nút mic để bắt đầu ghi',
              textAlign: TextAlign.center,
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!, style: const TextStyle(color: Colors.redAccent)),
            ],
            const SizedBox(height: 32),
            if (_recording)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _stop(),
                    icon: const Icon(Icons.stop),
                    label: const Text('Dừng'),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: () => _stop(keep: false),
                    child: const Text('Hủy bản ghi'),
                  ),
                ],
              )
            else
              ElevatedButton.icon(
                onPressed: _busy ? null : _start,
                icon: const Icon(Icons.mic),
                label: const Text('Bắt đầu ghi'),
              ),
          ],
        ),
      ),
    );
  }
}
