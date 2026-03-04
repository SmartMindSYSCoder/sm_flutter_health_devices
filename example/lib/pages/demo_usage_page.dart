import 'dart:async';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sm_flutter_health_devices/sm_flutter_health_devices.dart';

class DemoUsagePage extends StatefulWidget {
  const DemoUsagePage({super.key});

  @override
  State<DemoUsagePage> createState() => _DemoUsagePageState();
}

class _DemoUsagePageState extends State<DemoUsagePage>
    with WidgetsBindingObserver {
  static const String _kFitrusApiKey =
      'vrmCquCRjqTKGQNt3b9pEYy6NhjOL45Mi3d56I16RGTuCAeDNXW53kDaJGn7KUii5SAnHAdtcNoIlnJUk5M5HIj3mJpKAzsIIDilz0bKwdIekWot5X1KyCBMUXBGmICS';
  static const String _kOmronApiKey = 'F8C4D353-1309-41A4-A190-34C1101CC43D';

  final HealthPermissionManager _permissions = SmHealthDevices().permissions;

  // State
  PermissionState _bluetoothPermission = PermissionState.unknown;
  PermissionState _locationPermission = PermissionState.unknown;
  bool _isLocationServiceEnabled = false;
  bool _isBluetoothServiceEnabled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkStatus();
    }
  }

  Future<void> _checkStatus() async {
    // Check Permissions
    final bt = await _permissions.checkBluetoothPermissions();
    final loc = await _permissions.checkLocationPermission();

    // Check Services
    final locService = await _permissions.isLocationServiceEnabled();
    final btService = await Permission.bluetooth.serviceStatus.isEnabled;

    if (mounted) {
      setState(() {
        _bluetoothPermission =
            bt ? PermissionState.granted : PermissionState.denied;
        _locationPermission =
            loc ? PermissionState.granted : PermissionState.denied;
        _isLocationServiceEnabled = locService;
        _isBluetoothServiceEnabled = btService;
      });
    }
  }

  Future<void> _requestPermissions() async {
    await _permissions.requestBasePermissions();
    // Also re-check services
    await _checkStatus();
  }

  bool get _isReady =>
      _bluetoothPermission == PermissionState.granted &&
      _locationPermission == PermissionState.granted &&
      _isBluetoothServiceEnabled &&
      _isLocationServiceEnabled;

  static const List<_MeasurementOption> _options = [
    // Blood Pressure
    _MeasurementOption(
      type: MeasurementType.bloodPressure,
      icon: Icons.speed,
    ),

    // Weight
    _MeasurementOption(
      type: MeasurementType.weight,
      icon: Icons.monitor_weight,
    ),

    // SpO2
    _MeasurementOption(
      type: MeasurementType.spo2,
      icon: Icons.bloodtype,
    ),

    // Temperature
    _MeasurementOption(
      type: MeasurementType.temperature,
      icon: Icons.thermostat,
    ),

    // Body Composition
    _MeasurementOption(
      type: MeasurementType.bodyComposition,
      icon: Icons.accessibility_new,
    ),

    // Glucose
    _MeasurementOption(
      type: MeasurementType.glucometer,
      icon: Icons.water_drop,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Devices Demo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => SmHealthSettingsPage.open(
              context,
              initConfig: const SmHealthInitConfig(
                fitrusApiKey: _kFitrusApiKey,
                omronApiKey: _kOmronApiKey,
              ),
            ),
            tooltip: 'Settings',
          ),
        ],
      ),
      body: Column(
        children: [
          // Status Section
          _buildStatusSection(),

          const Divider(height: 1),

          // Grid Section
          Expanded(
            child: IgnorePointer(
              ignoring: !_isReady,
              child: Opacity(
                opacity: _isReady ? 1.0 : 0.3,
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.1,
                  ),
                  itemCount: _options.length,
                  itemBuilder: (context, index) {
                    final option = _options[index];
                    return Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      child: InkWell(
                        onTap: () => _openMeasurementDialog(context, option),
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(option.icon, size: 40, color: Colors.blue),
                              const SizedBox(height: 12),
                              Text(
                                option.type.displayName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Auto (Settings)',
                                style:
                                    TextStyle(color: Colors.grey, fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey.shade50,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'System Requirements',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Bluetooth Status
          _buildStatusRow(
            icon: Icons.bluetooth,
            label: 'Bluetooth Adapter',
            isEnabled: _isBluetoothServiceEnabled,
            action: !_isBluetoothServiceEnabled
                ? () => openAppSettings()
                : null, // Cannot open specific BT settings easily on all OS
          ),

          // Bluetooth Permission
          _buildStatusRow(
            icon: Icons.security,
            label: 'Bluetooth Permission',
            isEnabled: _bluetoothPermission == PermissionState.granted,
            action: _bluetoothPermission != PermissionState.granted
                ? _requestPermissions
                : null,
          ),

          // Location Service
          _buildStatusRow(
            icon: Icons.location_on,
            label: 'Location Service',
            isEnabled: _isLocationServiceEnabled,
            action: !_isLocationServiceEnabled
                ? () => _permissions.requestLocationService()
                : null,
          ),

          // Location Permission
          _buildStatusRow(
            icon: Icons.security,
            label: 'Location Permission',
            isEnabled: _locationPermission == PermissionState.granted,
            action: _locationPermission != PermissionState.granted
                ? _requestPermissions
                : null,
          ),

          const SizedBox(height: 16),

          if (!_isReady)
            ElevatedButton.icon(
              onPressed: _requestPermissions,
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Request All Permissions & Check Status'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusRow({
    required IconData icon,
    required String label,
    required bool isEnabled,
    VoidCallback? action,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: isEnabled ? Colors.green : Colors.orange, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: isEnabled ? Colors.green.shade700 : Colors.black87,
                fontWeight: isEnabled ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ),
          if (!isEnabled)
            Text(
              isEnabled ? "OK" : "Required",
              style: TextStyle(
                color: isEnabled ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          const SizedBox(width: 8),
          if (!isEnabled && action != null)
            SizedBox(
              height: 28,
              child: OutlinedButton(
                onPressed: action,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  side: const BorderSide(color: Colors.blue),
                ),
                child: const Text("Fix", style: TextStyle(fontSize: 12)),
              ),
            )
        ],
      ),
    );
  }

  void _openMeasurementDialog(BuildContext context, _MeasurementOption option) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: "Measurement",
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return Center(
          child: ScaleTransition(
            scale:
                CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
            child: Dialog(
              elevation: 0,
              backgroundColor: Colors.transparent,
              insetPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Container(
                width: 450,
                clipBehavior: Clip.antiAlias, // Force Radius clipping
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white,
                      Colors.blue.shade50.withOpacity(0.9),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Premium Header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 16, 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                option.type.displayName,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              Text(
                                'Auto (Settings)',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.blue.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.5),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.close,
                                  color: Colors.black54),
                              onPressed: () =>
                                  Navigator.of(dialogContext).maybePop(),
                              tooltip: "Cancel",
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, thickness: 0.5),
                    // Content
                    Flexible(
                      child: SingleChildScrollView(
                        child: SmHealthDeviceWidget(
                          measurementType: option.type,
                          onResult: (result) {
                            debugPrint('Result: ${result.toJson()}');
                          },
                          onCancel: () => Navigator.pop(dialogContext),
                          initConfig: SmHealthInitConfig(
                            autoSave: false,
                            fitrusApiKey:
                                option.type == MeasurementType.bodyComposition
                                    ? _kFitrusApiKey
                                    : null,
                            omronApiKey: _kOmronApiKey,
                            userProfile:
                                option.type == MeasurementType.bodyComposition
                                    ? const SmUserProfile(
                                        heightCm: 180,
                                        weightKg: 75,
                                        gender: Gender.male,
                                        birthDate: "19900101",
                                      )
                                    : null,
                          ),
                          uiConfig: const SmHealthUiConfig(
                            showAppBar: false,
                          ),
                          stateBuilder: _buildState,
                          successBuilder: _buildSuccess,
                          errorBuilder: _buildError,
                          initBuilder: _buildInit,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // --- PREMIUM BUILDERS ---

  Widget _buildInit(
      BuildContext context, VoidCallback onStart, VoidCallback onCancel) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Icon
          Center(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.blue.shade100.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.health_and_safety,
                size: 64,
                color: Colors.blue.shade600,
              ),
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            "Ready to Measure",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "Press the button below to start scanning for devices",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: onStart,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
              elevation: 2,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text(
              "Start Scan",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: onCancel,
            child: const Text("Cancel"),
          ),
        ],
      ),
    );
  }

  Widget _buildState(
      BuildContext context, HealthEventData event, VoidCallback onCancel) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Animated Icon Container
          Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.95, end: 1.05),
              duration: const Duration(seconds: 1),
              curve: Curves.easeInOut,
              builder: (context, scale, child) {
                return Transform.scale(scale: scale, child: child);
              },
              onEnd:
                  () {}, // Repeat would need a stateful controller, but this gives a nice entry
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  event.connectionState == HealthConnectionState.scanning
                      ? Icons.bluetooth_searching
                      : event.connectionState == HealthConnectionState.measuring
                          ? Icons.favorite
                          : Icons.bluetooth,
                  size: 64,
                  color: Colors.blue.shade600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            event.message.isNotEmpty
                ? event.message
                : event.connectionState.statusMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          if (event.connectionState == HealthConnectionState.measuring) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: event.progress / 100,
                minHeight: 10,
                backgroundColor: Colors.blue.shade50,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade400),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "${event.progress.toInt()}%",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade700,
              ),
            ),
          ],
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: onCancel,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.red.shade400,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.red.shade100),
              ),
            ),
            child: const Text("Stop Measurement"),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccess(BuildContext context, HealthVitalResult result,
      VoidCallback onSave, VoidCallback onReset) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded,
                  size: 64, color: Colors.green),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "Measurement Complete!",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 24),

          // Results Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.blue.shade50),
            ),
            child: Column(
              children: [
                if (result.systolic != null) ...[
                  _buildMetricRow("Blood Pressure",
                      "${result.systolic}/${result.diastolic}", "mmHg"),
                  if (result.pulse != null)
                    _buildMetricRow("Pulse", "${result.pulse}", "bpm"),
                ],
                if (result.weight != null)
                  _buildMetricRow("Weight", "${result.weight}", "kg"),
                if (result.bmi != null)
                  _buildMetricRow("BMI", "${result.bmi}", ""),
                if (result.temperature != null)
                  _buildMetricRow("Temperature", "${result.temperature}",
                      result.temperatureUnit.symbol),
                if (result.spo2 != null) ...[
                  _buildMetricRow("SpO2", "${result.spo2}", "%"),
                  if (result.heartRate != null)
                    _buildMetricRow("Heart Rate", "${result.heartRate}", "bpm"),
                ],
                if (result.fatPercentage != null)
                  _buildMetricRow("Body Fat", "${result.fatPercentage}", "%"),
                if (result.muscleMass != null)
                  _buildMetricRow("Muscle Mass", "${result.muscleMass}", "kg"),
              ],
            ),
          ),

          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: onReset,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text("Reset"),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: onSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                    elevation: 2,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text("Save & Exit"),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildMetricRow(String label, String value, String unit) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16, color: Colors.grey)),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 4),
                Text(
                  unit,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context, String error, VoidCallback onRetry,
      VoidCallback onCancel) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline_rounded,
                  size: 64, color: Colors.red),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "Something went wrong",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            error,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text("Try Again"),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: onCancel,
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }
}

class _MeasurementOption {
  final MeasurementType type;
  final IconData icon;

  const _MeasurementOption({
    required this.type,
    required this.icon,
  });
}
