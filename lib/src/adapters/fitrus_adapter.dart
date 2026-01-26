import 'package:sm_fitrus/fitrus_model.dart';
import '../models/health_event_data.dart';
import '../models/health_vital_result.dart';
import '../models/enums.dart';

class FitrusAdapter {
  /// Maps Fitrus events to HealthEventData
  static HealthEventData toHealthEvent(FitrusModel event) {
    if (event.hasData && event.bodyFat != null) {
      return HealthEventData.completed(
        provider: DeviceProvider.fitrus,
        measurementType: MeasurementType.bodyComposition,
        vitalResult: toHealthVitalResult(event.bodyFat!),
      );
    }

    if (event.hasProgress) {
      return HealthEventData(
        provider: DeviceProvider.fitrus,
        measurementType: MeasurementType.bodyComposition,
        connectionState:
            HealthConnectionState.measuring, // Progress implies measuring
        isConnected: true,
        progress: event.progress,
        maxProgress: 100,
        message: 'Measuring... ${event.progress}%',
      );
    }

    return HealthEventData(
      provider: DeviceProvider.fitrus,
      measurementType: MeasurementType.bodyComposition,
      connectionState: _mapConnectionState(event.connectionState),
      isConnected: event.isConnected, // Carry over connected state
      message: 'Status: ${event.connectionState.name}',
    );
  }

  /// Helper to map FitrusConnectionState to HealthConnectionState
  static HealthConnectionState _mapConnectionState(
      FitrusConnectionState state) {
    switch (state) {
      case FitrusConnectionState.disconnected:
        return HealthConnectionState.disconnected;
      case FitrusConnectionState.scanning:
        return HealthConnectionState.connecting;
      case FitrusConnectionState.connecting:
        return HealthConnectionState.connecting;
      case FitrusConnectionState.connected:
        return HealthConnectionState.connected;
      case FitrusConnectionState.discoveringServices:
        return HealthConnectionState.connected;
      case FitrusConnectionState.scanFailed:
        return HealthConnectionState.disconnected;
      case FitrusConnectionState.dataAvailable:
        return HealthConnectionState.connected;
      default:
        return HealthConnectionState.unknown;
    }
  }

  /// Maps Fitrus BodyFat model to HealthVitalResult
  static HealthVitalResult toHealthVitalResult(BodyFat body) {
    return HealthVitalResult(
      provider: DeviceProvider.fitrus,
      measurementType: MeasurementType.bodyComposition,
      bmi: _round(body.bmi),
      bmr: _round(body.bmr),
      fatPercentage: _round(body.fatPercentage),
      fatMass: _round(body.fatMass),
      muscleMass: _round(body.muscleMass),
      waterPercentage: _round(body.waterPercentage),
      protein: _round(body.protein),
      minerals: _round(body.minerals),
      calorie: _round(body.calorie),
    );
  }

  static double? _round(double? value) {
    if (value == null) return null;
    return double.parse(value.toStringAsFixed(2));
  }
}
