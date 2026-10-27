import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import '../preset/effect_preset.dart';
import 'offline_renderer.dart';
import 'voice_changer.dart';

/// A file render running on a background isolate, so the UI never stalls.
///
/// ```dart
/// final job = await RenderJob.start(inputPath: a, outputPath: b, preset: p);
/// job.progress.listen((p) => setState(() => _progress = p));
/// await job.done; // throws RenderCancelledException after cancel()
/// ```
class RenderJob {
  RenderJob._(this._outputPath);

  /// Progress is reported in steps of at least 1%.
  static const _progressStep = 0.01;

  final String _outputPath;
  final _progress = StreamController<double>.broadcast();
  final _done = Completer<void>();
  late final Isolate _isolate;
  late final ReceivePort _port;

  Stream<double> get progress => _progress.stream;

  /// Completes when the output file is in place; completes with an error if
  /// the render failed or was cancelled.
  Future<void> get done => _done.future;

  bool get isFinished => _done.isCompleted;

  static Future<RenderJob> start({
    required String inputPath,
    required String outputPath,
    required EffectPreset preset,
    Map<String, double> controlValues = const {},
  }) async {
    final job = RenderJob._(outputPath);
    job._port = ReceivePort()..listen(job._onMessage);
    job._isolate = await Isolate.spawn(
      _run,
      _Request(job._port.sendPort, inputPath, outputPath, preset, controlValues),
      onExit: job._port.sendPort,
      debugName: 'render ${preset.id}',
    );
    return job;
  }

  /// Stops the render immediately. Any partial temporary file is removed and
  /// [done] fails with [RenderCancelledException].
  void cancel() {
    if (isFinished) return;
    _isolate.kill(priority: Isolate.immediate);
    final temp = File(VoiceChanger.tempPathFor(_outputPath));
    if (temp.existsSync()) temp.deleteSync();
    _finish(const RenderCancelledException());
  }

  void _onMessage(Object? message) {
    if (isFinished) return;
    switch (message) {
      case double progress:
        _progress.add(progress);
      case _Done():
        _finish();
      case _Failed(:final error, :final stackTrace):
        _finish(error, StackTrace.fromString(stackTrace));
      case null: // onExit without a result: the isolate died.
        _finish(StateError('Render isolate exited unexpectedly'));
    }
  }

  void _finish([Object? error, StackTrace? stackTrace]) {
    _port.close();
    _progress.close();
    if (error == null) {
      _done.complete();
    } else {
      _done.completeError(error, stackTrace);
    }
  }

  static void _run(_Request request) {
    var lastSent = -1.0;
    try {
      VoiceChanger().renderFile(
        request.inputPath,
        request.outputPath,
        request.preset,
        controlValues: request.controlValues,
        onProgress: (p) {
          if (p - lastSent >= _progressStep || p == 1) {
            lastSent = p;
            request.port.send(p);
          }
        },
      );
      request.port.send(const _Done());
    } catch (e, stackTrace) {
      // Exceptions are sent as text: not every exception type can cross isolates.
      request.port.send(_Failed(e is Exception ? e : Exception(e.toString()), stackTrace.toString()));
    }
  }
}

class _Request {
  const _Request(this.port, this.inputPath, this.outputPath, this.preset, this.controlValues);

  final SendPort port;
  final String inputPath;
  final String outputPath;
  final EffectPreset preset;
  final Map<String, double> controlValues;
}

class _Done {
  const _Done();
}

class _Failed {
  const _Failed(this.error, this.stackTrace);

  final Object error;
  final String stackTrace;
}
