import 'enums.dart';
import 'health_vital_result.dart';

/// Unified event data model for health device events
/// Provides real-time updates from all three plugins
class HealthEventData {
  /// Device provider that generated this event
  final DeviceProvider provider;

  /// Type of measurement (if applicable)
  final MeasurementType measurementType;

  /// Current connection state
  final HealthConnectionState connectionState;

  /// Whether device is currently connected
  final bool isConnected;

  /// Whether measurement is complete
  final bool isCompleted;

  /// Whether an error occurred
  final bool hasError;

  /// Status message or error description
  final String message;

  /// Measurement progress (0-100) for devices that support it
  final int progress;

  /// Max progress value (e.g., 100 for percentage, 300 for pressure)
  final int maxProgress;

  /// Vital result data (populated when measurement is complete)
  final HealthVitalResult? vitalResult;

  /// Raw connection state string from the native plugin
  final String? rawConnectionState;

  const HealthEventData({
    required this.provider,
    this.measurementType = MeasurementType.unknown,
    this.connectionState = HealthConnectionState.disconnected,
    this.isConnected = false,
    this.isCompleted = false,
    this.hasError = false,
    this.message = '',
    this.progress = 0,
    this.maxProgress = 100,
    this.vitalResult,
    this.rawConnectionState,
  });

  /// Create an error event
  factory HealthEventData.error({
    required DeviceProvider provider,
    MeasurementType measurementType = MeasurementType.unknown,
    required String message,
  }) {
    return HealthEventData(
      provider: provider,
      measurementType: measurementType,
      connectionState: HealthConnectionState.error,
      hasError: true,
      message: message,
    );
  }

  /// Create a connecting event
  factory HealthEventData.connecting({
    required DeviceProvider provider,
    MeasurementType measurementType = MeasurementType.unknown,
    String message = 'Connecting...',
  }) {
    return HealthEventData(
      provider: provider,
      measurementType: measurementType,
      connectionState: HealthConnectionState.connecting,
      message: message,
    );
  }

  /// Create a scanning event
  factory HealthEventData.scanning({
    required DeviceProvider provider,
    MeasurementType measurementType = MeasurementType.unknown,
    String message = 'Scanning for devices...',
  }) {
    return HealthEventData(
      provider: provider,
      measurementType: measurementType,
      connectionState: HealthConnectionState.scanning,
      message: message,
    );
  }

  /// Create a completed event with vital result
  factory HealthEventData.completed({
    required DeviceProvider provider,
    required MeasurementType measurementType,
    required HealthVitalResult vitalResult,
    String message = 'Measurement complete',
  }) {
    return HealthEventData(
      provider: provider,
      measurementType: measurementType,
      connectionState: HealthConnectionState.completed,
      isConnected: true,
      isCompleted: true,
      progress: 100,
      maxProgress: 100,
      message: message,
      vitalResult: vitalResult,
    );
  }

  /// Check if this event has valid measurement data
  bool get hasData => vitalResult?.hasData ?? false;

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
        'provider': provider.name,
        'measurementType': measurementType.name,
        'connectionState': connectionState.name,
        'isConnected': isConnected,
        'isCompleted': isCompleted,
        'hasError': hasError,
        'message': message,
        'progress': progress,
        'maxProgress': maxProgress,
        'vitalResult': vitalResult?.toJson(),
        'rawConnectionState': rawConnectionState,
      };

  @override
  String toString() {
    return 'HealthEventData('
        'provider: ${provider.displayName}, '
        'type: ${measurementType.displayName}, '
        'state: ${connectionState.name}, '
        'progress: $progress/$maxProgress, '
        'message: $message'
        ')';
  }

  /// Copy with modified fields
  HealthEventData copyWith({
    DeviceProvider? provider,
    MeasurementType? measurementType,
    HealthConnectionState? connectionState,
    bool? isConnected,
    bool? isCompleted,
    bool? hasError,
    String? message,
    int? progress,
    int? maxProgress,
    HealthVitalResult? vitalResult,
    String? rawConnectionState,
  }) {
    return HealthEventData(
      provider: provider ?? this.provider,
      measurementType: measurementType ?? this.measurementType,
      connectionState: connectionState ?? this.connectionState,
      isConnected: isConnected ?? this.isConnected,
      isCompleted: isCompleted ?? this.isCompleted,
      hasError: hasError ?? this.hasError,
      message: message ?? this.message,
      progress: progress ?? this.progress,
      maxProgress: maxProgress ?? this.maxProgress,
      vitalResult: vitalResult ?? this.vitalResult,
      rawConnectionState: rawConnectionState ?? this.rawConnectionState,
    );
  }
}
