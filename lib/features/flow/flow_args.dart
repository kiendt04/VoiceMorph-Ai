import 'package:voice_core/voice_core.dart';

/// Dữ liệu truyền giữa các màn của luồng đổi giọng (qua go_router `extra`).
/// Luồng: Record/Import -> Effects -> Editor -> Processing -> Result.

/// Một file âm thanh nguồn (bản ghi từ mic hoặc file import).
class SourceArgs {
  const SourceArgs({required this.path, required this.name});

  final String path;
  final String name;
}

/// Vào màn ChooseEffect. [source] null khi người dùng bấm preset ở Home mà
/// chưa có bản ghi — màn hình sẽ nhắc ghi âm/import trước.
class EffectsArgs {
  const EffectsArgs({this.source, this.preselectedPresetId});

  final SourceArgs? source;
  final String? preselectedPresetId;
}

/// Vào màn FineTune: nguồn + preset đã chọn.
class EditorArgs {
  const EditorArgs({required this.source, required this.preset});

  final SourceArgs source;
  final EffectPreset preset;
}

/// Vào màn Processing: nguồn + preset + giá trị slider người dùng đã chỉnh.
class ProcessingArgs {
  const ProcessingArgs({
    required this.source,
    required this.preset,
    required this.controlValues,
  });

  final SourceArgs source;
  final EffectPreset preset;
  final Map<String, double> controlValues;
}

/// Vào màn Result: nguồn gốc + file đã render + preset đã dùng.
class ResultArgs {
  const ResultArgs({
    required this.source,
    required this.renderedPath,
    required this.preset,
  });

  final SourceArgs source;
  final String renderedPath;
  final EffectPreset preset;
}
