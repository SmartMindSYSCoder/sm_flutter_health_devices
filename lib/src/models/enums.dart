/// Device provider/manufacturer enum
/// Represents the source of health device data
enum DeviceProvider {
  /// Omron healthcare devices (BP, Weight, SpO2, Temperature, Activity)
  omron,

  /// Lepu Medical devices (AOJ-20A, PC60FW, PC-102, ICOMON)
  lepu,

  /// Fitrus body composition device
  fitrus,

  /// AccuChek glucometer devices
  accucheck,

  /// Raycome devices (future support)
  raycome,

  /// Unknown provider
  unknown;

  /// Get display name for the provider
  String get displayName {
    switch (this) {
      case DeviceProvider.omron:
        return 'Omron';
      case DeviceProvider.lepu:
        return 'Lepu Medical';
      case DeviceProvider.fitrus:
        return 'Fitrus';
      case DeviceProvider.accucheck:
        return 'AccuChek';
      case DeviceProvider.raycome:
        return 'Raycome';
      case DeviceProvider.unknown:
        return 'Unknown';
    }
  }
}

/// Measurement type enum
/// Represents the type of health measurement
enum MeasurementType {
  /// Body weight measurement
  weight,

  /// Blood pressure measurement (systolic/diastolic)
  bloodPressure,

  /// Body temperature measurement
  temperature,

  /// Blood oxygen saturation (SpO2)
  spo2,

  /// Body composition analysis (fat %, muscle mass, etc.)
  bodyComposition,

  /// Activity tracking (steps, calories, distance)
  activity,

  /// Wheeze detection
  wheeze,

  /// Blood glucose measurement (glucometer)
  glucometer,

  /// Unknown measurement type
  unknown;

  /// Get display name
  String get displayName {
    switch (this) {
      case MeasurementType.weight:
        return 'Weight';
      case MeasurementType.bloodPressure:
        return 'Blood Pressure';
      case MeasurementType.temperature:
        return 'Temperature';
      case MeasurementType.spo2:
        return 'SpO2';
      case MeasurementType.bodyComposition:
        return 'Body Composition';
      case MeasurementType.activity:
        return 'Activity';
      case MeasurementType.wheeze:
        return 'Wheeze';
      case MeasurementType.glucometer:
        return 'Blood Glucose';
      case MeasurementType.unknown:
        return 'Unknown';
    }
  }

  /// Get supported providers for this measurement type
  List<DeviceProvider> get supportedProviders {
    switch (this) {
      case MeasurementType.weight:
        return [DeviceProvider.omron, DeviceProvider.lepu];
      case MeasurementType.bloodPressure:
        return [
          DeviceProvider.omron,
          DeviceProvider.lepu,
          DeviceProvider.raycome,
        ];
      case MeasurementType.temperature:
        return [DeviceProvider.omron, DeviceProvider.lepu];
      case MeasurementType.spo2:
        return [DeviceProvider.omron, DeviceProvider.lepu];
      case MeasurementType.bodyComposition:
        return [DeviceProvider.fitrus];
      case MeasurementType.activity:
        return [DeviceProvider.omron];
      case MeasurementType.wheeze:
        return [DeviceProvider.omron];
      case MeasurementType.glucometer:
        return [DeviceProvider.accucheck];
      case MeasurementType.unknown:
        return [];
    }
  }
}

/// Connection state for health devices
enum HealthConnectionState {
  /// Device is disconnected
  disconnected,

  /// Scanning for devices
  scanning,

  /// Connecting to device
  connecting,

  /// Connected to device
  connected,

  /// Device services discovered (ready for measurement)
  ready,

  /// Measurement in progress
  measuring,
  recording,

  /// Measurement completed successfully
  completed,

  /// Error occurred
  error,

  /// Unknown or unmapped state
  unknown;

  /// Check if currently connected or better
  bool get isConnected =>
      this == HealthConnectionState.connected ||
      this == HealthConnectionState.ready ||
      this == HealthConnectionState.measuring ||
      this == HealthConnectionState.recording ||
      this == HealthConnectionState.completed;

  /// Check if measurement is complete
  bool get isCompleted => this == HealthConnectionState.completed;

  /// Check if in error state
  bool get hasError => this == HealthConnectionState.error;

  /// Human-readable status message
  String get statusMessage {
    switch (this) {
      case HealthConnectionState.disconnected:
        return 'Disconnected';
      case HealthConnectionState.scanning:
        return 'Scanning...';
      case HealthConnectionState.connecting:
        return 'Connecting...';
      case HealthConnectionState.connected:
        return 'Connected';
      case HealthConnectionState.ready:
        return 'Ready';
      case HealthConnectionState.measuring:
        return 'Measuring...';
      case HealthConnectionState.recording:
        return 'Recording...';
      case HealthConnectionState.completed:
        return 'Completed';
      case HealthConnectionState.error:
        return 'Error';
      case HealthConnectionState.unknown:
        return 'Unknown';
    }
  }
}

/// Gender enum for body composition measurements
enum Gender {
  male,
  female;

  /// Convert to Fitrus API format
  String toFitrusFormat() => this == Gender.male ? 'M' : 'F';
}

/// Temperature unit enum
enum TemperatureUnit {
  celsius,
  fahrenheit;

  /// Get symbol
  String get symbol => this == TemperatureUnit.celsius ? '°C' : '°F';
}

/// Permission status result
enum PermissionState {
  granted,
  denied,
  permanentlyDenied,
  restricted,
  limited,
  unknown;

  bool get isGranted => this == PermissionState.granted;
}
