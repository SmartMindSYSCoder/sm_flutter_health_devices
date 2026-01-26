import 'package:sm_lepu/sm_lepu.dart';

import '../models/enums.dart';
import '../models/health_event_data.dart';
import '../models/health_vital_result.dart';

/// Adapter to convert Lepu events to unified health events
class LepuAdapter {
  /// Convert LepuEventData to HealthEventData
  static HealthEventData toHealthEvent(LepuEventData lepuEvent) {
    final measurementType = _mapDeviceType(lepuEvent.deviceType);
    final connectionState = _mapConnectionState(lepuEvent);

    HealthVitalResult? vitalResult;
    if (lepuEvent.hasData) {
      vitalResult = toHealthVitalResult(lepuEvent);
    }

    return HealthEventData(
      provider: DeviceProvider.lepu,
      measurementType: measurementType,
      connectionState: connectionState,
      isConnected: lepuEvent.isConnected,
      isCompleted: lepuEvent.isCompleted,
      hasError: lepuEvent.hasError,
      message: lepuEvent.message,
      progress: lepuEvent.progress,
      vitalResult: vitalResult,
    );
  }

  /// Convert LepuEventData to HealthVitalResult
  static HealthVitalResult toHealthVitalResult(LepuEventData lepuEvent) {
    final measurementType = _mapDeviceType(lepuEvent.deviceType);

    return HealthVitalResult(
      provider: DeviceProvider.lepu,
      measurementType: measurementType,
      measurementDate: DateTime.now(),
      hasData: lepuEvent.hasData,
      // Temperature
      temperature:
          lepuEvent.temperature > 0 ? _round(lepuEvent.temperature) : null,
      // SpO2
      spo2: lepuEvent.spo2 > 0 ? lepuEvent.spo2 : null,
      heartRate: lepuEvent.heartRate > 0 ? lepuEvent.heartRate : null,
      // Blood Pressure
      systolic: lepuEvent.systolic > 0 ? lepuEvent.systolic : null,
      diastolic: lepuEvent.diastolic > 0 ? lepuEvent.diastolic : null,
      // Weight
      weight: lepuEvent.weight > 0 ? _round(lepuEvent.weight) : null,
    );
  }

  static double? _round(double? value) {
    if (value == null) return null;
    return double.parse(value.toStringAsFixed(2));
  }

  /// Map LepuDeviceType to MeasurementType
  static MeasurementType _mapDeviceType(LepuDeviceType deviceType) {
    switch (deviceType) {
      case LepuDeviceType.temperature:
        return MeasurementType.temperature;
      case LepuDeviceType.spo2:
        return MeasurementType.spo2;
      case LepuDeviceType.bloodPressure:
        return MeasurementType.bloodPressure;
      case LepuDeviceType.weight:
        return MeasurementType.weight;
      case LepuDeviceType.unknown:
        return MeasurementType.unknown;
    }
  }

  /// Map Lepu connection state to HealthConnectionState
  static HealthConnectionState _mapConnectionState(LepuEventData lepuEvent) {
    if (lepuEvent.hasError) {
      return HealthConnectionState.error;
    }

    switch (lepuEvent.state) {
      case LepuConnectionState.disconnected:
        return HealthConnectionState.disconnected;
      case LepuConnectionState.connecting:
        return HealthConnectionState.connecting;
      case LepuConnectionState.connected:
        return HealthConnectionState.connected;
      case LepuConnectionState.measuring:
        return HealthConnectionState.measuring;
      case LepuConnectionState.completed:
        return HealthConnectionState.completed;
      case LepuConnectionState.error:
        return HealthConnectionState.error;
    }
  }
}
