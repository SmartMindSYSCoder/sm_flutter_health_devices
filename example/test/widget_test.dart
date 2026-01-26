import 'package:flutter_test/flutter_test.dart';
import 'package:sm_flutter_health_devices_example/app/app.dart';

void main() {
  testWidgets('App renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const HealthDevicesApp());
    expect(find.text('Health Devices'), findsOneWidget);
  });
}
