import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voice_core/voice_core.dart';
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

  test('home features the expected presets from the bundled JSON', () {
    // Read from disk: rootBundle.loadString hangs inside widget tests.
    final presets = PresetParser.parseLibrary(
        File('packages/voice_core/assets/presets/default_presets.json').readAsStringSync());
    final featured = PresetService.featured(presets);

    expect(featured.map((p) => p.id), PresetService.homeFeaturedIds);
    expect(featured.firstWhere((p) => p.id == 'deep_male').isPro, isTrue);
  });
}
