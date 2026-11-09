import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:voice_core/voice_core.dart';

import '../../core/strings.dart';
import '../../services/ads/interstitial_gate.dart';
import '../flow/flow_args.dart';

/// Màn Processing: chạy RenderJob toàn file ở isolate, hiện tiến độ %,
/// cho hủy (RenderJob tự xóa file tạm, không để file dở). Lỗi -> màn
/// Failed với nút thử lại. Xong -> sang màn Result.
class ProcessingScreen extends ConsumerStatefulWidget {
  const ProcessingScreen({super.key, required this.args});

  final ProcessingArgs args;

  @override
  ConsumerState<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends ConsumerState<ProcessingScreen> {
  RenderJob? _job;
  StreamSubscription<double>? _progressSub;
  var _progress = 0.0;
  Object? _error;
  var _cancelled = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    _progressSub?.cancel();
    super.dispose();
  }

  Future<void> _start() async {
    setState(() {
      _progress = 0.0;
      _error = null;
      _cancelled = false;
    });
    try {
      final temp = await getTemporaryDirectory();
      final dir = Directory('${temp.path}/renders');
      if (!dir.existsSync()) dir.createSync(recursive: true);
      final outputPath =
          '${dir.path}/render_${DateTime.now().millisecondsSinceEpoch}.wav';
      final job = await RenderJob.start(
        inputPath: widget.args.source.path,
        outputPath: outputPath,
        preset: widget.args.preset,
        controlValues: widget.args.controlValues,
      );
      if (!mounted || _cancelled) {
        job.cancel();
        return;
      }
      _job = job;
      _progressSub = job.progress.listen((p) {
        if (mounted) setState(() => _progress = p);
      });
      await job.done;
      if (!mounted || _cancelled) return;
      // Render thành công: cổng interstitial (Giai đoạn 3) quyết định có
      // hiện quảng cáo không — lỗi quảng cáo không chặn sang Result.
      await InterstitialGate.maybeShowAfterRender(ref);
      if (!mounted || _cancelled) return;
      context.go(
        '/result',
        extra: ResultArgs(
          source: widget.args.source,
          renderedPath: outputPath,
          preset: widget.args.preset,
        ),
      );
    } catch (e) {
      // Hủy render cũng đi qua đây (RenderCancelledException) — nhưng nút
      // Hủy đã pop màn hình rồi nên chỉ hiện lỗi khi không phải do hủy.
      if (mounted && !_cancelled) setState(() => _error = e);
    }
  }

  void _cancel() {
    _cancelled = true;
    _progressSub?.cancel();
    _job?.cancel();
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: Text(AppLocalizations.of(context).t('processingFailedTitle'))),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64),
              const SizedBox(height: 16),
              Text(
                '${AppLocalizations.of(context).t('processingFailed')}: $_error',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _start,
                child: Text(AppLocalizations.of(context).t('retry')),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => context.pop(),
                child: Text(AppLocalizations.of(context).t('back')),
              ),
            ],
          ),
        ),
      );
    }
    final s = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(s.t('processingTitle'))),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.autorenew, size: 64),
            const SizedBox(height: 24),
            LinearProgressIndicator(value: _progress),
            const SizedBox(height: 12),
            Text('${(_progress * 100).toStringAsFixed(0)}%'),
            const SizedBox(height: 8),
            Text('${s.t('processingPreset')}: ${widget.args.preset.name('vi')}'),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: _cancel,
              child: Text(s.t('processingCancel')),
            ),
          ],
        ),
      ),
    );
  }
}
