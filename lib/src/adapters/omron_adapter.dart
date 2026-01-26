import 'package:sm_omron/sm_omron.dart' as omron;

import '../models/enums.dart';
import '../models/health_event_data.dart';
import '../models/health_vital_result.dart';

/// Adapter to convert Omron data to unified health format
class OmronAdapter {
  /// Convert VitalResult from Omron to HealthVitalResult
  static HealthVitalResult toHealthVitalResult(omron.VitalResult omronResult) {
    final measurementType = _mapVitalType(omronResult.type);

    return HealthVitalResult(
      provider: DeviceProvider.omron,
      measurementType: measurementType,
      measurementDate: omronResult.measurementDate,
      hasData: true,
      // Blood Pressure
      systolic: omronResult.systolic,
      diastolic: omronResult.diastolic,
      pulse: omronResult.pulse,
      irregularHeartbeat: omronResult.irregularHeartbeat,
      // Weight
      weight: _round(omronResult.weight),
      bmi: _round(omronResult.bmi),
      bodyFatPercentage: _round(omronResult.bodyFatPercentage),
      skeletalMusclePercentage: _round(omronResult.skeletalMusclePercentage),
      visceralFatLevel: omronResult.visceralFatLevel,
      basalMetabolicRate: omronResult.basalMetabolicRate,
      bodyAge: omronResult.bodyAge,
      // SpO2
      spo2: omronResult.spo2Level,
      heartRate: omronResult.pulseOximeterRate,
      // Temperature
      temperature: _round(omronResult.temperature),
      temperatureUnit: _mapTempUnit(omronResult.temperatureUnit),
      // Activity
      steps: omronResult.steps,
      aerobicSteps: omronResult.aerobicSteps,
      distance: _round(omronResult.distance),
      calories: omronResult.calories,
      // Wheeze
      wheezeDetected:
          omronResult.wheezeResult == omron.WheezeResult.wheezeDetected,
      // Raw
      rawData: omronResult.rawData,
    );
  }

  static double? _round(double? value) {
    if (value == null) return null;
    return double.parse(value.toStringAsFixed(2));
  }

  /// Convert list of VitalResults to list of HealthVitalResults
  static List<HealthVitalResult> toHealthVitalResults(
      List<omron.VitalResult> omronResults) {
    return omronResults.map((r) => toHealthVitalResult(r)).toList();
  }

  /// Map Omron VitalType to MeasurementType
  static MeasurementType _mapVitalType(omron.VitalType vitalType) {
    switch (vitalType) {
      case omron.VitalType.bloodPressure:
        return MeasurementType.bloodPressure;
      case omron.VitalType.weight:
        return MeasurementType.weight;
      case omron.VitalType.pulseOximeter:
        return MeasurementType.spo2;
      case omron.VitalType.temperature:
        return MeasurementType.temperature;
      case omron.VitalType.activity:
        return MeasurementType.activity;
      case omron.VitalType.wheeze:
        return MeasurementType.wheeze;
      default:
        return MeasurementType.unknown;
    }
  }

  /// Map Omron TemperatureUnit
  static TemperatureUnit _mapTempUnit(omron.TemperatureUnit? omronUnit) {
    if (omronUnit == omron.TemperatureUnit.fahrenheit) {
      return TemperatureUnit.fahrenheit;
    }
    return TemperatureUnit.celsius;
  }

  /// Map Omron DeviceCategory to MeasurementType
  static MeasurementType mapDeviceCategory(omron.DeviceCategory category) {
    switch (category) {
      case omron.DeviceCategory.bloodPressure:
        return MeasurementType.bloodPressure;
      case omron.DeviceCategory.weight:
        return MeasurementType.weight;
      case omron.DeviceCategory.pulseOximeter:
        return MeasurementType.spo2;
      case omron.DeviceCategory.temperature:
        return MeasurementType.temperature;
      case omron.DeviceCategory.activity:
        return MeasurementType.activity;
      case omron.DeviceCategory.wheeze:
        return MeasurementType.wheeze;
    }
  }

  /// Map MeasurementType to Omron DeviceCategory
  static omron.DeviceCategory? toDeviceCategory(MeasurementType type) {
    switch (type) {
      case MeasurementType.bloodPressure:
        return omron.DeviceCategory.bloodPressure;
      case MeasurementType.weight:
        return omron.DeviceCategory.weight;
      case MeasurementType.spo2:
        return omron.DeviceCategory.pulseOximeter;
      case MeasurementType.temperature:
        return omron.DeviceCategory.temperature;
      case MeasurementType.activity:
        return omron.DeviceCategory.activity;
      case MeasurementType.wheeze:
        return omron.DeviceCategory.wheeze;
      default:
        return null;
    }
  }

  /// Map Omron ConnectionState (which comes as dynamic/int) to HealthConnectionState
  static HealthConnectionState mapConnectionState(dynamic state) {
    // Assuming state can be int or generic enum index or string
    // This removes the dependency on the undefined 'omron.ConnectionState'
    final s = state.toString().toLowerCase();

    if (s.contains('connecting')) {
      return HealthConnectionState.connecting;
    }
    if (s.contains('connected')) {
      return HealthConnectionState.connected;
    }
    if (s.contains('scanning')) {
      return HealthConnectionState.scanning;
    }
    if (s.contains('disconnected')) {
      return HealthConnectionState.disconnected;
    }

    // Default fallback
    return HealthConnectionState.unknown;
  }

  /// Create a generic HealthEventData from Omron connection state
  static HealthEventData toHealthEvent(dynamic state) {
    final connectionState = mapConnectionState(state);
    String message;

    if (state is omron.OmronConnectionState) {
      message = state.statusMessage;
    } else {
      message = connectionState.statusMessage;
    }

    return HealthEventData(
      provider: DeviceProvider.omron,
      measurementType: MeasurementType.unknown, // Status is general to provider
      connectionState: connectionState,
      message: message,
    );
  }
}
