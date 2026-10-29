import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voicemorph_ai/main.dart';
import 'package:voicemorph_ai/services/presets/preset_service.dart';

void main() {
  testWidgets('app opens on the home screen', (tester) async {
    // AdService is not initialized here, so the banner stays a placeholder.
    await tester.pumpWidget(const ProviderScope(child: VoiceMorphApp()));

    expect(find.text('VoiceMorph'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Ghi âm'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Thư viện'), findsOneWidget);
  });

  testWidgets('home lists the featured presets from the bundled JSON', (tester) async {
    final presets = await tester.runAsync(PresetService.loadPresets);
    final featured = PresetService.featured(presets!);

    expect(featured.map((p) => p.id), PresetService.homeFeaturedIds);
    expect(featured.firstWhere((p) => p.id == 'deep_male').isPro, isTrue);
  });
}
