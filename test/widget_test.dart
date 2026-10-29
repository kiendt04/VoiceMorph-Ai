import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voice_core/voice_core.dart';
import 'package:voicemorph_ai/main.dart';
import 'package:voicemorph_ai/services/presets/preset_service.dart';

void main() {
  // path_provider không có plugin thật trong widget test: mock channel để
  // Splash/OnboardingFlag không kẹt ở getApplicationDocumentsDirectory.
  // Trước khi có mock này, cả 2 test widget đều fail vì màn Onboarding
  // không bao giờ hiện sau Splash.
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (call) async {
        if (call.method == 'getApplicationDocumentsDirectory' ||
            call.method == 'getTemporaryDirectory') {
          return Directory.systemTemp.path;
        }
        return null;
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      null,
    );
  });

  testWidgets('first run shows onboarding after splash', (tester) async {
    // App mở ở /splash; cờ onboarding chưa có -> sau 600ms chuyển sang onboarding.
    await tester.pumpWidget(const ProviderScope(child: VoiceMorphApp()));
    expect(find.text('VoiceMorph'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();
    expect(find.text('Tiếp'), findsOneWidget);
  });

  testWidgets('home screen has record and library buttons', (tester) async {
    // Đi qua splash -> onboarding bằng nút Bỏ qua rồi tới Home.
    await tester.pumpWidget(const ProviderScope(child: VoiceMorphApp()));
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bỏ qua'));
    await tester.pumpAndSettle();
    // Nếu môi trường test trả về "từ chối vĩnh viễn" thì _finish hiện dialog
    // xin mở Cài đặt và chưa sang Home: bấm "Để sau" để đi tiếp.
    if (find.text('Để sau').evaluate().isNotEmpty) {
      await tester.tap(find.text('Để sau'));
      await tester.pumpAndSettle();
    }
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
