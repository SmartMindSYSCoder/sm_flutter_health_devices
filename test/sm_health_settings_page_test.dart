import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sm_flutter_health_devices/sm_flutter_health_devices.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async => '.',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider_macos'),
      (MethodCall methodCall) async => '.',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/shared_preferences'),
      (MethodCall methodCall) async {
        if (methodCall.method == 'getAll') {
          return <String, Object>{};
        }
        return null;
      },
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('sm_omron'),
      (MethodCall methodCall) async => null,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('sm_fitrus'),
      (MethodCall methodCall) async => null,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('sm_lepu'),
      (MethodCall methodCall) async => null,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('sm_raycome'),
      (MethodCall methodCall) async => null,
    );
    await SmHealthDevices().init();
  });

  testWidgets('session banner appears when test measurement is triggered and resets on new page instance',
      (WidgetTester tester) async {
    // 1. Build SmHealthSettingsPage with custom onTestMeasurement callback
    await tester.pumpWidget(
      MaterialApp(
        home: SmHealthSettingsPage(
          onTestMeasurement: (context, type, provider) {},
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Verify initially no 'Measured Successfully' banner exists
    expect(find.text('Measured Successfully'), findsNothing);

    // 2. Tap the first 'Test Device' button
    final testButtons = find.text('Test Device');
    expect(testButtons, findsWidgets);

    await tester.tap(testButtons.first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Verify 'Measured Successfully' banner now appears
    expect(find.text('Measured Successfully'), findsOneWidget);

    // 3. Re-open page (new instance)
    await tester.pumpWidget(
      MaterialApp(
        home: SmHealthSettingsPage(
          key: UniqueKey(),
          onTestMeasurement: (context, type, provider) {},
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Verify session state was reset and banner is gone
    expect(find.text('Measured Successfully'), findsNothing);
  });

  testWidgets('session banner displays Arabic translation when language is set to Arabic',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SmHealthSettingsPage(
          initConfig: const SmHealthInitConfig(
            lang: SmHealthSettingsLanguage.ar,
          ),
          onTestMeasurement: (context, type, provider) {},
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('تم القياس بنجاح'), findsNothing);

    final testButtons = find.text('اختبار الجهاز');
    expect(testButtons, findsWidgets);

    await tester.tap(testButtons.first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('تم القياس بنجاح'), findsOneWidget);
  });
}
