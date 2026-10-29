import 'package:flutter/services.dart';
import 'package:voice_core/voice_core.dart';

/// Tải thư viện preset từ asset của package voice_core.
///
/// Asset đã được khai báo trong `packages/voice_core/pubspec.yaml`, nên app
/// đọc bằng đường dẫn `packages/voice_core/...` qua rootBundle — không cần
/// khai báo lại asset ở pubspec của app.
class PresetService {
  static const assetPath = 'packages/voice_core/assets/presets/default_presets.json';

  /// 5 preset nổi bật ở màn Home, đúng thứ tự trong Figma.
  static const homeFeaturedIds = ['robot', 'alien', 'deep_male', 'child', 'ghost'];

  static Future<List<EffectPreset>> loadPresets() async {
    final json = await rootBundle.loadString(assetPath);
    return PresetParser.parseLibrary(json);
  }

  /// 5 preset Home theo đúng thứ tự [homeFeaturedIds]; preset thiếu trong
  /// JSON sẽ bị bỏ qua thay vì làm crash màn hình.
  static List<EffectPreset> featured(List<EffectPreset> presets) {
    final byId = {for (final p in presets) p.id: p};
    return [
      for (final id in homeFeaturedIds)
        if (byId.containsKey(id)) byId[id]!,
    ];
  }
}
