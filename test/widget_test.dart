import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voice_core/voice_core.dart';
import 'package:voicemorph_ai/main.dart';
import 'package:voicemorph_ai/services/presets/preset_service.dart';

void main() {
  testWidgets('first run shows onboarding after splash', (tester) async {
    // App mở ở /splash; cờ onboarding chưa có (path_provider không có mock
    // trong test nên isDone trả về false) -> sau 600ms chuyển sang onboarding.
    await tester.pumpWidget(const ProviderScope(child: VoiceMorphApp()));
    expect(find.text('VoiceMorph'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump();
    expect(find.text('Tiếp'), findsOneWidget);
  });

  testWidgets('home screen has record and library buttons', (tester) async {
    // Bơm trực tiếp Home (không qua splash) để kiểm tra các nút chính.
    // Home dùng go_router nên cần MaterialApp.router với router thật;
    // ở đây chỉ kiểm tra widget Home qua app đầy đủ sau khi bỏ qua splash
    // bằng cách pump thêm: splash -> onboarding là luồng mặc định, nên test
    // này dùng cùng app nhưng đi qua onboarding bằng nút Bỏ qua.
    await tester.pumpWidget(const ProviderScope(child: VoiceMorphApp()));
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump();
    await tester.tap(find.text('Bỏ qua'));
    await tester.pumpAndSettle();
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
