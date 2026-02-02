# sm_flutter_health_devices

[![Pub Version](https://img.shields.io/pub/v/sm_flutter_health_devices)](https://pub.dev/packages/sm_flutter_health_devices)
[![Flutter Platform](https://img.shields.io/badge/Platform-Flutter-02569B?logo=flutter)](https://flutter.dev)

A unified Flutter plugin for health devices that wraps **sm_fitrus**, **sm_lepu**, and **sm_omron** plugins into a single, easy-to-use API.

---

## 🚀 Features

- **Unified API**: Single interface for all health device measurements
- **Smart Pairing Workflow**: Automated discovery, pairing, and saving for Omron devices
- **Multiple Providers**: Support for Omron, Lepu Medical, Fitrus, Raycome, and AccuChek
- **Permission Management**: Centralized Bluetooth, Location, Audio, and Network permissions
- **Unified Data Model**: `HealthVitalResult` covers all measurement types
- **Event Streaming**: Real-time updates from all devices through a single stream
- **Provider Selection**: Choose your preferred device provider for each measurement type
- **Pre-built UI Widget**: Production-ready widget with customizable builders

---

## 📊 Supported Measurements & Providers

| Measurement | Omron | Lepu | Fitrus | AccuChek | Raycome |
|-------------|:-----:|:----:|:------:|:--------:|:-------:|
| **Weight** | ✅ | ✅ | - | - | - |
| **Blood Pressure** | ✅ | ✅ | - | - | ✅ |
| **Temperature** | ✅ | ✅ | - | - | - |
| **SpO2** | ✅ | ✅ | - | - | - |
| **Body Composition** | - | - | ✅ | - | - |
| **Activity** | ✅ | - | - | - | - |
| **Blood Glucose** | - | - | - | ✅ | - |

---

## 📋 Prerequisites

### Android Permissions

Add to your `android/app/src/main/AndroidManifest.xml`:

```xml
<!-- Bluetooth Permissions -->
<uses-permission android:name="android.permission.BLUETOOTH" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />

<!-- Location (Required for BLE scanning) -->
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />

<!-- Audio (For Omron temperature devices) -->
<uses-permission android:name="android.permission.RECORD_AUDIO" />

<!-- Network (For Fitrus API) -->
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
```

---

## 🛠 Getting Started

### Installation

```yaml
dependencies:
  sm_flutter_health_devices:
    git:
      url: https://github.com/SmartMindSYSCoder/sm_flutter_health_devices.git
```

### Basic Usage

```dart
import 'package:sm_flutter_health_devices/sm_flutter_health_devices.dart';

final healthDevices = SmHealthDevices();

// 1. Request permissions
final permResult = await healthDevices.permissions.requestAllPermissions();
if (!permResult.isBleReady) {
  print('Bluetooth permissions not granted');
  return;
}

// 2. Initialize
await healthDevices.init();

// 3. Listen to events
healthDevices.getEvents().listen((event) {
  print('Provider: ${event.provider.displayName}');
  print('Type: ${event.measurementType.displayName}');
  print('State: ${event.connectionState}');
  
  if (event.isCompleted && event.vitalResult != null) {
    final result = event.vitalResult!;
    print('Result: $result');
  }
});
```

---

## 📱 UI Components

### SmHealthDeviceWidget

The plugin includes a pre-built, production-ready widget that handles the entire measurement lifecycle with customizable UI builders.

#### ✨ Features

- **4 Customizable States**: Init, Active (Scanning/Connecting/Measuring), Success, and Error
- **Optional Init Screen**: Show a custom UI before starting the measurement
- **Smart State Locking**: Success state remains stable even when device disconnects
- **Auto-Pairing (Omron)**: Automatically handles device discovery and pairing
- **Flexible Reset**: Return to init screen or retry measurement after success

---

### 🎯 Basic Usage with initBuilder (Recommended)

The `initBuilder` provides a clean initial state where users can prepare before starting the measurement:

```dart
SmHealthDeviceWidget(
  measurementType: MeasurementType.bloodPressure,
  provider: DeviceProvider.omron,
  onResult: (result) {
    print("Systolic: ${result.systolic}");
    print("Diastolic: ${result.diastolic}");
  },
  
  // 0. Initial State (Optional but Recommended)
  initBuilder: (context, onStart, onCancel) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.health_and_safety, size: 64, color: Colors.blue),
        SizedBox(height: 16),
        Text("Ready to Measure Blood Pressure"),
        SizedBox(height: 24),
        ElevatedButton(
          onPressed: onStart, // Starts scan and measurement
          child: Text("Start Scan"),
        ),
        TextButton(
          onPressed: onCancel, // Exits the widget
          child: Text("Cancel"),
        ),
      ],
    );
  },
  
  // 1. Active State (Scanning/Connecting/Measuring)
  stateBuilder: (context, event, onCancel) {
    return Column(
      children: [
        CircularProgressIndicator(value: event.progress / 100),
        SizedBox(height: 16),
        Text(event.message), // "Scanning...", "Measuring...", etc.
        if (event.connectionState == HealthConnectionState.measuring)
          Text("${event.progress.toInt()}%"),
        SizedBox(height: 24),
        TextButton(
          onPressed: onCancel,
          child: Text("Stop Measurement"),
        ),
      ],
    );
  },
  
  // 2. Success State
  successBuilder: (context, result, onSave, onReset) {
    return Column(
      children: [
        Icon(Icons.check_circle, color: Colors.green, size: 64),
        SizedBox(height: 16),
        Text("Measurement Complete!"),
        SizedBox(height: 24),
        Text("BP: ${result.systolic}/${result.diastolic} mmHg"),
        Text("Pulse: ${result.pulse} bpm"),
        SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            TextButton(
              onPressed: onReset, // Returns to initBuilder
              child: Text("Reset"),
            ),
            ElevatedButton(
              onPressed: onSave, // Calls onResult and exits
              child: Text("Save & Exit"),
            ),
          ],
        ),
      ],
    );
  },
  
  // 3. Error State
  errorBuilder: (context, errorMessage, onRetry, onCancel) {
    return Column(
      children: [
        Icon(Icons.error, color: Colors.red, size: 64),
        SizedBox(height: 16),
        Text("Error: $errorMessage"),
        SizedBox(height: 24),
        ElevatedButton(
          onPressed: onRetry, // Restarts measurement
          child: Text("Try Again"),
        ),
        TextButton(
          onPressed: onCancel, // Exits the widget
          child: Text("Close"),
        ),
      ],
    );
  },
)
```

---

### 🔄 Without initBuilder (Auto-Start)

If you don't provide an `initBuilder`, the widget will auto-start based on `config.autoStartScan`:

```dart
SmHealthDeviceWidget(
  measurementType: MeasurementType.bloodPressure,
  provider: DeviceProvider.lepu,
  onResult: (result) => print("Result: $result"),
  config: SmDeviceConfig(
    autoStartScan: true, // Starts immediately
  ),
  stateBuilder: (context, event, onCancel) {
    return Column(
      children: [
        CircularProgressIndicator(),
        Text(event.message),
        TextButton(onPressed: onCancel, child: Text("Cancel")),
      ],
    );
  },
  successBuilder: (context, result, onSave, onReset) {
    return Column(
      children: [
        Text("BP: ${result.systolic}/${result.diastolic}"),
        ElevatedButton(onPressed: onSave, child: Text("Save")),
        TextButton(
          onPressed: onReset, // Acts as retry (restarts measurement)
          child: Text("Retry"),
        ),
      ],
    );
  },
  errorBuilder: (context, error, onRetry, onCancel) {
    return Column(
      children: [
        Text("Error: $error"),
        ElevatedButton(onPressed: onRetry, child: Text("Retry")),
      ],
    );
  },
)
```

---

### 📊 State Flow Diagram

#### With initBuilder:
```
Init Screen → [User clicks "Start"] → Scanning → Connecting → Measuring → Success
                                                                              ↓
                                                                    [User clicks "Reset"]
                                                                              ↓
                                                                         Init Screen
```

#### Without initBuilder:
```
Auto-Start → Scanning → Connecting → Measuring → Success
                                                     ↓
                                           [User clicks "Reset"]
                                                     ↓
                                                  Scanning (retry)
```

---

### 📝 Builder Parameters Explained

#### initBuilder (Optional)
```dart
Widget Function(
  BuildContext context,
  VoidCallback onStart,   // Call to start scan and measurement
  VoidCallback onCancel   // Call to exit/cancel
)? initBuilder;
```

**When to use**: When you want users to explicitly trigger the measurement start.

---

#### stateBuilder (Required)
```dart
Widget Function(
  BuildContext context,
  HealthEventData event,  // Current event with state, message, progress
  VoidCallback onCancel   // Call to cancel measurement
) stateBuilder;
```

**Event states**:
- `HealthConnectionState.scanning` - Looking for devices
- `HealthConnectionState.connecting` - Connecting to device
- `HealthConnectionState.connected` - Connected, preparing
- `HealthConnectionState.measuring` - Actively measuring (check `event.progress`)

---

#### successBuilder (Required)
```dart
Widget Function(
  BuildContext context,
  HealthVitalResult result,  // Measurement result
  VoidCallback onSave,       // Call to save and exit (triggers onResult)
  VoidCallback onReset       // Call to reset (behavior depends on initBuilder)
) successBuilder;
```

**onReset behavior**:
- **With initBuilder**: Returns to init screen
- **Without initBuilder**: Restarts measurement (acts as retry)

> **⚠️ Important**: The success state is **locked** once reached. Even if the device disconnects, the UI will remain on the success screen until the user clicks "Reset" or "Save & Exit".

---

#### errorBuilder (Required)
```dart
Widget Function(
  BuildContext context,
  String errorMessage,    // Error description
  VoidCallback onRetry,   // Call to retry measurement
  VoidCallback onCancel   // Call to exit/cancel
) errorBuilder;
```

---

### ⚙️ Configuration Options

```dart
SmDeviceConfig(
  // Auto-start behavior (only used if initBuilder is null)
  autoStartScan: true,
  
  // UI customization (optional)
  showAppBar: true,
  title: "Blood Pressure Measurement",
  backgroundColor: Colors.white,
  
  // Animation
  animationDuration: Duration(milliseconds: 300),
  
  // Default messages
  scanningText: "Scanning for devices...",
  connectingText: "Connecting...",
  measuringText: "Measuring...",
)
```

---

### 💡 Complete Example: Body Composition (Fitrus)

```dart
SmHealthDeviceWidget(
  measurementType: MeasurementType.bodyComposition,
  provider: DeviceProvider.fitrus,
  fitrusApiKey: 'YOUR_API_KEY',
  userProfile: SmUserProfile(
    heightCm: 175,
    weightKg: 70,
    gender: Gender.male,
    birthDate: "19900101",
  ),
  onResult: (result) {
    print("Body Fat: ${result.fatPercentage}%");
    print("Muscle Mass: ${result.muscleMass} kg");
    print("BMI: ${result.bmi}");
  },
  initBuilder: (context, onStart, onCancel) {
    return Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.accessibility_new, size: 80, color: Colors.blue),
          SizedBox(height: 24),
          Text(
            "Body Composition Analysis",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          Text("Hold the device with both hands"),
          SizedBox(height: 32),
          ElevatedButton(
            onPressed: onStart,
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            child: Text("Start Measurement"),
          ),
          SizedBox(height: 12),
          TextButton(
            onPressed: onCancel,
            child: Text("Cancel"),
          ),
        ],
      ),
    );
  },
  stateBuilder: (context, event, onCancel) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(value: event.progress / 100),
        SizedBox(height: 24),
        Text(event.message, style: TextStyle(fontSize: 18)),
        if (event.progress > 0)
          Text("${event.progress.toInt()}%", 
               style: TextStyle(fontSize: 16, color: Colors.blue)),
        SizedBox(height: 32),
        TextButton(
          onPressed: onCancel,
          child: Text("Cancel"),
        ),
      ],
    );
  },
  successBuilder: (context, result, onSave, onReset) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 64),
          SizedBox(height: 16),
          Text("Analysis Complete!", 
               style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          SizedBox(height: 32),
          _buildMetric("Body Fat", "${result.fatPercentage}%"),
          _buildMetric("Muscle Mass", "${result.muscleMass} kg"),
          _buildMetric("BMI", "${result.bmi}"),
          _buildMetric("BMR", "${result.bmr} kcal"),
          SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: onReset,
                  child: Text("New Measurement"),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: onSave,
                  child: Text("Save Results"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  },
  errorBuilder: (context, error, onRetry, onCancel) {
    return Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: Colors.red, size: 64),
          SizedBox(height: 16),
          Text("Measurement Failed", style: TextStyle(fontSize: 20)),
          SizedBox(height: 8),
          Text(error, textAlign: TextAlign.center),
          SizedBox(height: 32),
          ElevatedButton(
            onPressed: onRetry,
            child: Text("Try Again"),
          ),
          SizedBox(height: 12),
          TextButton(
            onPressed: onCancel,
            child: Text("Cancel"),
          ),
        ],
      ),
    );
  },
)

Widget _buildMetric(String label, String value) {
  return Padding(
    padding: EdgeInsets.symmetric(vertical: 8),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 16)),
        Text(value, 
             style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    ),
  );
}
```

---

### ✅ Key Features

**Built-in Logic:**
- ✅ **Auto-Scanning**: Automatically scans for devices when started
- ✅ **Smart Pairing (Omron)**: 
  - Checks for saved devices first
  - If found, connects immediately
  - If not found, opens Device Selector Dialog
  - Pairs and saves new devices automatically
- ✅ **State Locking**: Success state remains stable even when device disconnects
- ✅ **Unified Events**: Handles all connection states internally
- ✅ **Flexible Reset**: Choose between returning to init or retrying measurement

**Best Practices:**
1. ✅ Always provide `initBuilder` for better UX
2. ✅ Show progress during measurement using `event.progress`
3. ✅ Display clear error messages in `errorBuilder`
4. ✅ Use `onReset` to let users start fresh measurements
5. ✅ Call `onSave` only when user confirms they want to save results

---

## 📖 Manual Usage Examples

### Weight Measurement

```dart
// Using Lepu (ICOMON scale)
await healthDevices.readWeight(provider: DeviceProvider.lepu);

// Using Omron (Smart Manual Flow)
final savedScale = await healthDevices.getSavedOmronDevices();
if (savedScale.isNotEmpty) {
   await healthDevices.readWeight(
     provider: DeviceProvider.omron,
     omronDevice: savedScale.first,
   );
}
```

### Blood Pressure

```dart
// Using Lepu (PC-102)
await healthDevices.readBloodPressure(provider: DeviceProvider.lepu);

// Using Omron (Smart Manual Flow)
// 1. Get saved devices
final savedDevices = await healthDevices.getSavedOmronDevices();

// 2. Filter for BP Category
final bpDevice = savedDevices.firstWhere(
  (d) => d.deviceCategory == DeviceCategory.bloodPressure,
  orElse: () => null,
);

if (bpDevice != null) {
  // 3. Measure
  await healthDevices.readBloodPressure(
    provider: DeviceProvider.omron,
    omronDevice: bpDevice,
  );
} else {
  // 4. Handle pairing flow (handled automatically by SmHealthDeviceWidget)
  print("Please pair a device first");
}

// Stop measurement (Lepu only)
await healthDevices.stopBloodPressure();

// Using Raycome (RBP-9000)
await healthDevices.readBloodPressure(provider: DeviceProvider.raycome);
```

### Temperature

```dart
// Using Lepu (AOJ-20A thermometer)
await healthDevices.readTemperature(provider: DeviceProvider.lepu);

// Using Omron (MC-280B-E via microphone)
await healthDevices.readTemperature(provider: DeviceProvider.omron);
```

### SpO2 (Pulse Oximetry)

```dart
// Using Lepu (PC60FW)
await healthDevices.readSpo2(provider: DeviceProvider.lepu);

// Using Omron (P300)
// Requires a paired Omron Pulse Oximeter
await healthDevices.readSpo2(
  provider: DeviceProvider.omron,
  omronDevice: savedSpo2Device,
);
```

### Body Composition (Fitrus)

```dart
// Initialize Fitrus (scans for device)
await healthDevices.initFitrus(apiKey: 'YOUR_API_KEY');

// Start measurement
await healthDevices.readBodyComposition(
  heightCm: 175.0,
  weightKg: 70.0,
  gender: Gender.male,
  birthDate: '19901215', // yyyyMMdd format
);

// Results come through the event stream
healthDevices.getEvents().listen((event) {
  if (event.measurementType == MeasurementType.bodyComposition && event.isCompleted) {
    final result = event.vitalResult!;
    print('Body Fat: ${result.fatPercentage}%');
    print('Skeletal Muscle Mass: ${result.skeletalMuscleMass} kg');
    print('BMI: ${result.bmi}');
  }
});
```

### Blood Glucose (AccuChek)

```dart
// Using AccuChek Guide
await healthDevices.readGlucose();

// Results come through the event stream
healthDevices.getEvents().listen((event) {
  if (event.measurementType == MeasurementType.glucometer && event.isCompleted) {
    final result = event.vitalResult!;
    print('Glucose: ${result.glucose} ${result.glucoseUnit}');
  }
});
```

---

## 🔐 Permission Manager

```dart
final permissions = healthDevices.permissions;

// Request all permissions
final result = await permissions.requestAllPermissions();

// Check specific permissions
if (!result.isBluetoothGranted) {
  print('Bluetooth permission denied');
}
if (!result.isLocationServiceEnabled) {
  await permissions.requestLocationService();
}
if (!result.isNetworkConnected) {
  print('Network required for Fitrus');
}

// Request permissions for specific measurement
final bpPermissions = await permissions.requestPermissionsFor(
  MeasurementType.bloodPressure,
);
```

---

## 📊 Data Models

### HealthVitalResult

Unified result model covering all measurement types:

```dart
class HealthVitalResult {
  // Common
  DeviceProvider provider;
  MeasurementType measurementType;
  DateTime? measurementDate;
  
  // Weight
  double? weight;
  double? bmi;
  
  // Blood Pressure
  int? systolic;
  int? diastolic;
  int? pulse;
  
  // Temperature
  double? temperature;
  TemperatureUnit temperatureUnit;
  
  // SpO2
  int? spo2;
  int? heartRate;
  
  // Body Composition (Fitrus)
  double? fatPercentage;
  double? fatMass;
  double? muscleMass;
  double? skeletalMuscleMass;
  double? waterPercentage;
  double? bmr;
  double? minerals;
  double? protein;
  
  // Blood Glucose
  double? glucose;
  String? glucoseUnit;
  // ... more fields
}
```

### HealthEventData

Real-time event data from devices:

```dart
class HealthEventData {
  DeviceProvider provider;
  MeasurementType measurementType;
  HealthConnectionState connectionState;
  bool isConnected;
  bool isCompleted;
  String message;
  int progress;
  HealthVitalResult? vitalResult;
}
```

---

## 🔧 Direct Plugin Access

For advanced usage, access underlying plugins directly:

```dart
// Direct Fitrus access
healthDevices.fitrus.startBFP(...);

// Direct Lepu access
healthDevices.lepu.initBP();

// Direct Omron access
healthDevices.omron.scanBleDevice(...);
```

---

## 🧹 Cleanup

```dart
await healthDevices.dispose();
```

---

## Requirements

| Platform | Minimum Version |
|----------|-----------------|
| Flutter | ≥ 3.3.0 |
| Dart | ≥ 3.5.0 |
| Android | minSdk 24 |
| iOS | 12.0+ |

---

## 📝 Changelog

### Latest Updates

#### v1.1.0 - InitBuilder Feature
- ✨ Added optional `initBuilder` parameter for custom initial UI
- ✨ Success state now locks and prevents auto-transitions on device disconnect
- ✨ Changed `successBuilder` parameter from `onRetry` to `onReset`
- ✨ Reset behavior is now context-aware (returns to init or retries based on configuration)
- 🐛 Fixed issue where success UI would disappear when device disconnects
- 📚 Updated documentation with comprehensive examples

---

## Author

[SmartMind SYS](https://github.com/SmartMindSYSCoder)
