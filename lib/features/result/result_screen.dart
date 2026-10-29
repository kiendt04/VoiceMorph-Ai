import 'dart:io';
import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:voice_core/voice_core.dart';

import '../common/providers.dart';
import '../flow/flow_args.dart';

/// Màn Result: nghe đối chiếu Bản gốc / Đã đổi, Lưu vào thư viện,
/// Chia sẻ, Đặt nhạc chuông (Android).
///
/// Bản đã đổi khi phát sẽ qua một bản copy đã applyFade (chống click ở
/// đầu/cuối) — file lưu/chia sẻ vẫn là file render gốc, không bị sửa.
class ResultScreen extends ConsumerStatefulWidget {
  const ResultScreen({super.key, required this.args});

  final ResultArgs args;

  @override
  ConsumerState<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends ConsumerState<ResultScreen> {
  final _player = AudioPlayer();
  var _playingRendered = true;
  var _playing = false;
  var _saved = false;
  var _saving = false;
  String? _fadedPath;

  @override
  void initState() {
    super.initState();
    _prepareFadedCopy();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _prepareFadedCopy() async {
    try {
      final path = widget.args.renderedPath;
      final bytes = await Isolate.run(() {
        final audio = WavIO.readFile(path);
        final faded = applyFade(audio.samples, sampleRate: audio.sampleRate);
        return WavIO.encode(faded, audio.sampleRate);
      });
      final temp = await getTemporaryDirectory();
      final fadedPath =
          '${temp.path}/faded_${DateTime.now().millisecondsSinceEpoch}.wav';
      await File(fadedPath).writeAsBytes(bytes, flush: true);
      if (mounted) setState(() => _fadedPath = fadedPath);
    } catch (_) {
      // Không tạo được bản fade thì phát file gốc — không chặn người dùng.
    }
  }

  Future<void> _play({required bool rendered}) async {
    if (_playing && _playingRendered == rendered) {
      await _player.pause();
      if (mounted) setState(() => _playing = false);
      return;
    }
    final path = rendered
        ? (_fadedPath ?? widget.args.renderedPath)
        : widget.args.source.path;
    try {
      await _player.stop();
      await _player.setFilePath(path);
      await _player.play();
      if (mounted) {
        setState(() {
          _playing = true;
          _playingRendered = rendered;
        });
      }
      _player.playerStateStream.firstWhere(
        (s) => s.processingState == ProcessingState.completed,
      ).then((_) {
        if (mounted) setState(() => _playing = false);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không phát được: $e')),
        );
      }
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final name =
          '${widget.args.preset.name('vi')} — ${widget.args.source.name}';
      await ref.read(libraryProvider.notifier).addRendered(
            renderedPath: widget.args.renderedPath,
            originalPath: widget.args.source.path,
            name: name,
          );
      if (mounted) {
        setState(() => _saved = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã lưu vào thư viện.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không lưu được: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _share() async {
    try {
      // share_plus 10.x (the version pinned in pubspec.lock) uses the
      // static Share API; SharePlus.instance only exists from 11.0.0.
      await Share.shareXFiles([XFile(widget.args.renderedPath)]);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không chia sẻ được: $e')),
        );
      }
    }
  }

  Future<void> _ringtone() async {
    // Giai đoạn 1 làm gọn: Android không đặt nhạc chuông trực tiếp từ
    // Flutter mà không có platform channel riêng; app lưu một bản copy vào
    // documents và hướng dẫn người dùng chọn trong Cài đặt hệ thống.
    // (iOS không cho app bên thứ ba đặt nhạc chuông trực tiếp.)
    if (!Platform.isAndroid) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('iOS không cho app đặt nhạc chuông trực tiếp.'),
          ),
        );
      }
      return;
    }
    try {
      final docs = await getApplicationDocumentsDirectory();
      final target =
          '${docs.path}/ringtones/${widget.args.preset.id}_${DateTime.now().millisecondsSinceEpoch}.wav';
      await Directory('${docs.path}/ringtones').create(recursive: true);
      await File(widget.args.renderedPath).copy(target);
      if (mounted) {
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Đặt làm nhạc chuông'),
            content: const Text(
              'File đã được lưu vào thư mục của app. Mở Cài đặt > Âm thanh > '
              'Nhạc chuông trên điện thoại và chọn file vừa lưu nhé.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Đã hiểu'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không lưu được file nhạc chuông: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final preset = widget.args.preset;
    return Scaffold(
      appBar: AppBar(title: const Text('Kết quả')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              preset.name('vi'),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text('Nguồn: ${widget.args.source.name}'),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _play(rendered: false),
                    icon: Icon(
                      _playing && !_playingRendered
                          ? Icons.pause
                          : Icons.play_arrow,
                    ),
                    label: const Text('Bản gốc'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _play(rendered: true),
                    icon: Icon(
                      _playing && _playingRendered
                          ? Icons.pause
                          : Icons.play_arrow,
                    ),
                    label: const Text('Đã đổi'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _saved || _saving ? null : _save,
                icon: const Icon(Icons.save),
                label: Text(_saved ? 'Đã lưu' : 'Lưu vào thư viện'),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _share,
                    icon: const Icon(Icons.share),
                    label: const Text('Chia sẻ'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _ringtone,
                    icon: const Icon(Icons.music_note),
                    label: const Text('Nhạc chuông'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => context.go('/'),
              child: const Text('Về trang chính'),
            ),
          ],
        ),
      ),
    );
  }
}
