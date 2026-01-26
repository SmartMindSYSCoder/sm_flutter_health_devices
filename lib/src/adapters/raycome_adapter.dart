import 'package:sm_raycome/sm_raycome.dart' as raycome;
import 'package:sm_raycome/models/blood_pressure_result.dart' as raycome_result;

import '../models/enums.dart';
import '../models/health_event_data.dart';
import '../models/health_vital_result.dart';

/// Adapter to convert Raycome data to unified health format
class RaycomeAdapter {
  /// Convert RaycomeState to HealthEventData
  static HealthEventData toHealthEvent(raycome.RaycomeState state) {
    final connectionState =
        _mapConnectionState(state.connectionState, state.measurementStatus);

    return HealthEventData(
      provider: DeviceProvider.raycome,
      measurementType: MeasurementType.bloodPressure,
      connectionState: connectionState,
      isConnected:
          state.connectionState == raycome.RaycomeConnectionState.connected,
      isCompleted:
          state.measurementStatus == raycome.RaycomeMeasurementStatus.success,
      message: _mapStatusMessage(state),
      progress: state.runningPressure, // Use pressure as progress value
      maxProgress: 200,
      vitalResult: state.lastResult != null
          ? toHealthVitalResult(state.lastResult!)
          : null,
      hasError: state.errorMessage != null,
    );
  }

  /// Convert BloodPressureResult to HealthVitalResult
  static HealthVitalResult toHealthVitalResult(
      raycome_result.BloodPressureResult result) {
    return HealthVitalResult(
      provider: DeviceProvider.raycome,
      measurementType: MeasurementType.bloodPressure,
      // createTime is an int (timestamp)
      measurementDate: DateTime.fromMillisecondsSinceEpoch(result.createTime > 0
          ? result.createTime
          : DateTime.now().millisecondsSinceEpoch),
      hasData: true,
      systolic: result.systolic,
      diastolic: result.diastolic,
      pulse: result.heartRate,
    );
  }

  /// Map internal Raycome states to unified HealthConnectionState
  static HealthConnectionState _mapConnectionState(
      raycome.RaycomeConnectionState connState,
      raycome.RaycomeMeasurementStatus measureStatus) {
    if (measureStatus == raycome.RaycomeMeasurementStatus.error) {
      return HealthConnectionState.error;
    }
    if (measureStatus == raycome.RaycomeMeasurementStatus.success) {
      return HealthConnectionState.completed;
    }
    if (measureStatus == raycome.RaycomeMeasurementStatus.measuring) {
      return HealthConnectionState.measuring;
    }
    if (measureStatus == raycome.RaycomeMeasurementStatus.scanning) {
      return HealthConnectionState.scanning;
    }

    switch (connState) {
      case raycome.RaycomeConnectionState.connected:
        return HealthConnectionState.connected;
      case raycome.RaycomeConnectionState.disconnected:
        return HealthConnectionState.disconnected;
      case raycome.RaycomeConnectionState.unknown:
        return HealthConnectionState.unknown;
    }
  }

  static String _mapStatusMessage(raycome.RaycomeState state) {
    if (state.errorMessage != null) return state.errorMessage!;
    if (state.measurementStatus == raycome.RaycomeMeasurementStatus.measuring) {
      return 'Measuring... ${state.runningPressure} mmHg';
    }
    return state.displayStatus;
  }
}
