# sm_flutter_health_devices_example

This example demonstrates how to integrate the unified health device plugin into a Flutter application.

## 🚀 Expert Setup

### 1. Requirements
Ensure you have the following API keys from your providers:
- **Omron**: Required for Bluetooth device pairing and data synchronization.
- **Fitrus**: Required for body composition analysis.

### 2. Configuration
The example app demonstrates using the `SmHealthInitConfig` to pass these keys securely:

```dart
SmHealthDeviceWidget(
  measurementType: MeasurementType.bloodPressure,
  initConfig: SmHealthInitConfig(
    omronApiKey: 'YOUR_OMRON_API_KEY',
    autoSave: true,
  ),
  // ... builders
)
```

### 3. Automated Flow
This version of the plugin supports:
- **Provider-less Initiation**: No need to pass a specific `provider`. The system automatically resolves the "Preferred Provider" from the settings.
- **Auto-Save**: Automatically triggers the `onResult` callback upon successful measurement to reduce user friction.

---
For full documentation, visit the [main README](../README.md).
