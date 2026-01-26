import '../models/enums.dart';
import '../models/health_event_data.dart';
import '../models/health_vital_result.dart';

/// Adapter to convert AccuCheck glucometer data to unified health format
class AccuCheckAdapter {
  /// Convert glucose reading to HealthVitalResult
  static HealthVitalResult toHealthVitalResult(int glucoseLevel) {
    return HealthVitalResult(
      provider: DeviceProvider.accucheck,
      measurementType: MeasurementType.glucometer,
      measurementDate: DateTime.now(),
      hasData: true,
      glucoseLevel: glucoseLevel,
    );
  }

  /// Create a connecting event
  static HealthEventData connectingEvent() {
    return HealthEventData.connecting(
      provider: DeviceProvider.accucheck,
      measurementType: MeasurementType.glucometer,
      message: 'Connecting to AccuChek glucometer...',
    );
  }

  /// Create a scanning event
  static HealthEventData scanningEvent() {
    return HealthEventData.scanning(
      provider: DeviceProvider.accucheck,
      measurementType: MeasurementType.glucometer,
      message: 'Scanning for AccuChek device...',
    );
  }

  /// Create a completed event with result
  static HealthEventData completedEvent(int glucoseLevel) {
    return HealthEventData.completed(
      provider: DeviceProvider.accucheck,
      measurementType: MeasurementType.glucometer,
      vitalResult: toHealthVitalResult(glucoseLevel),
      message: 'Blood glucose reading complete',
    );
  }

  /// Create an error event
  static HealthEventData errorEvent(String message) {
    return HealthEventData.error(
      provider: DeviceProvider.accucheck,
      measurementType: MeasurementType.glucometer,
      message: message,
    );
  }
}
