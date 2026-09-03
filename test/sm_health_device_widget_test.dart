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
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('flutter.baseflow.com/permissions/methods'),
      (MethodCall methodCall) async {
        if (methodCall.method == 'checkPermissionStatus') {
          return 1; // PermissionStatus.granted
        }
        if (methodCall.method == 'checkServiceStatus') {
          return 1; // ServiceStatus.enabled
        }
        return null;
      },
    );

    HealthPermissionManager.debugMockStatus = const HealthRequirementStatus(
      hasBluetoothPermission: true,
      hasLocationPermission: true,
      isBluetoothEnabled: true,
      isLocationServiceEnabled: true,
    );

    await SmHealthDevices().init();
  });

  tearDown(() {
    HealthPermissionManager.debugMockStatus = null;
  });

  testWidgets(
      'stateBuilder onCancel directly cancels without displaying confirmation dialog',
      (WidgetTester tester) async {
    bool cancelCalled = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SmHealthDeviceWidget(
            measurementType: MeasurementType.bloodPressure,
            uiConfig: const SmHealthUiConfig(showAppBar: false),
            initConfig: const SmHealthInitConfig(
              autoStartScan: false,
            ),
            onResult: (result) {},
            onCancel: () {
              cancelCalled = true;
            },
            stateBuilder: (context, event, onCancel) {
              return Center(
                child: ElevatedButton(
                  onPressed: onCancel,
                  child: const Text('Cancel In State'),
                ),
              );
            },
            successBuilder: (context, result, onSave, onReset) =>
                const SizedBox(),
            errorBuilder: (context, error, onRetry, onCancel) =>
                const SizedBox(),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Check if the Cancel In State button is found
    final cancelButton = find.text('Cancel In State');
    expect(cancelButton, findsOneWidget);

    // Tap Cancel
    await tester.tap(cancelButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify confirmation dialog (Stop Measurement?) is NOT displayed
    expect(find.text('Stop Measurement?'), findsNothing);
    expect(find.text('إيقاف القياس؟'), findsNothing);
    expect(find.byType(AlertDialog), findsNothing);

    // Verify onCancel was invoked directly
    expect(cancelCalled, isTrue);
  });

  testWidgets(
      'AppBar back button displays confirmation dialog when active',
      (WidgetTester tester) async {
    bool cancelCalled = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SmHealthDeviceWidget(
            measurementType: MeasurementType.bloodPressure,
            uiConfig: const SmHealthUiConfig(showAppBar: true),
            initConfig: const SmHealthInitConfig(
              autoStartScan: true,
            ),
            onResult: (result) {},
            onCancel: () {
              cancelCalled = true;
            },
            stateBuilder: (context, event, onCancel) {
              return const Center(child: Text('Active State'));
            },
            successBuilder: (context, result, onSave, onReset) =>
                const SizedBox(),
            errorBuilder: (context, error, onRetry, onCancel) =>
                const SizedBox(),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Tap AppBar back arrow
    final backIcon = find.byIcon(Icons.arrow_back);
    expect(backIcon, findsOneWidget);
    await tester.tap(backIcon);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Confirmation dialog should be displayed
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('Stop Measurement?'), findsOneWidget);
    expect(cancelCalled, isFalse);

    // Tap Stop in dialog to confirm exit
    final stopButton = find.text('Stop');
    expect(stopButton, findsOneWidget);
    await tester.tap(stopButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(cancelCalled, isTrue);
  });
}
