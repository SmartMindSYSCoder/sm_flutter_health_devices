# sm_flutter_health_devices

[![Pub Version](https://img.shields.io/pub/v/sm_flutter_health_devices)](https://pub.dev/packages/sm_flutter_health_devices)
[![Flutter Platform](https://img.shields.io/badge/Platform-Flutter-02569B?logo=flutter)](https://flutter.dev)

A unified Flutter plugin for health devices that wraps **sm_fitrus**, **sm_lepu**, and **sm_omron** plugins into a single, easy-to-use API.

---

## 🚀 Features

- **Unified API**: Single interface for all health device measurements
- **Smart Pairing Workflow**: Automated discovery, pairing, and saving for Omron devices
- **Multiple Providers**: Support for Omron, Lepu Medical, Fitrus, and Raycome (future)
- **Permission Management**: Centralized Bluetooth, Location, Audio, and Network permissions
- **Unified Data Model**: `HealthVitalResult` covers all measurement types
- **Event Streaming**: Real-time updates from all devices through a single stream
- **Provider Selection**: Choose your preferred device provider for each measurement type

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

The plugin includes a pre-built, production-ready widget that handles the entire measurement lifecycle:

```dart
SmHealthDeviceWidget(
  measurementType: MeasurementType.bloodPressure,
  provider: DeviceProvider.omron,
  onResult: (result) {
    print("Systolic: ${result.systolic}");
  },
  onCancel: () => Navigator.pop(context),
)
```

**Built-in Logic:**
- **Auto-Scanning**: Automatically scans for devices.
- **Smart Pairing (Omron)**: 
  - Checks for saved devices first.
  - If found, connects immediately.
  - If not found, opens a **Device Selector Dialog**.
  - Pairs and saves the new device automatically.
- **Unified Events**: Handles connection states (Scanning -> Measuring -> Completed/Error) internally.
- **UI Feedback**: Shows progress bars, status messages, and error handling.

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

## Author

[SmartMind SYS](https://github.com/SmartMindSYSCoder)
