import 'package:flutter/material.dart';
import 'package:sm_flutter_health_devices/sm_flutter_health_devices.dart';

/// Card displaying the latest measurement result
class ResultCard extends StatelessWidget {
  final HealthVitalResult result;
  final VoidCallback? onDismiss;

  const ResultCard({
    super.key,
    required this.result,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      color: colors.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getIcon(),
                  color: colors.onPrimaryContainer,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    result.measurementType.displayName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colors.onPrimaryContainer,
                    ),
                  ),
                ),
                if (onDismiss != null)
                  IconButton(
                    onPressed: onDismiss,
                    icon: Icon(
                      Icons.close,
                      color: colors.onPrimaryContainer,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _buildResultContent(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildResultContent(ColorScheme colors) {
    switch (result.measurementType) {
      case MeasurementType.weight:
        return _buildValueRow(
          '${result.weight?.toStringAsFixed(1) ?? '--'} kg',
          result.bmi != null ? 'BMI: ${result.bmi!.toStringAsFixed(1)}' : null,
          colors,
        );

      case MeasurementType.bloodPressure:
        return _buildValueRow(
          '${result.systolic ?? '--'}/${result.diastolic ?? '--'} mmHg',
          result.pulse != null ? '${result.pulse} BPM' : null,
          colors,
        );

      case MeasurementType.temperature:
        return _buildValueRow(
          '${result.temperature?.toStringAsFixed(1) ?? '--'}${result.temperatureUnit.symbol}',
          null,
          colors,
        );

      case MeasurementType.spo2:
        return _buildValueRow(
          '${result.spo2 ?? '--'}%',
          result.heartRate != null ? '${result.heartRate} BPM' : null,
          colors,
        );

      case MeasurementType.bodyComposition:
        return Column(
          children: [
            _buildSmallValue('Fat',
                '${result.fatPercentage?.toStringAsFixed(1) ?? '--'}%', colors),
            const SizedBox(height: 8),
            _buildSmallValue('Muscle',
                '${result.muscleMass?.toStringAsFixed(1) ?? '--'} kg', colors),
            const SizedBox(height: 8),
            _buildSmallValue(
                'Water',
                '${result.waterPercentage?.toStringAsFixed(1) ?? '--'}%',
                colors),
          ],
        );

      case MeasurementType.glucometer:
        return _buildValueRow(
          '${result.glucoseLevel ?? '--'} mg/dL',
          null,
          colors,
        );

      default:
        return Text(
          'Measurement complete',
          style: TextStyle(color: colors.onPrimaryContainer),
        );
    }
  }

  Widget _buildValueRow(
      String mainValue, String? secondary, ColorScheme colors) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          mainValue,
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: colors.onPrimaryContainer,
          ),
        ),
        if (secondary != null) ...[
          const Spacer(),
          Text(
            secondary,
            style: TextStyle(
              fontSize: 18,
              color: colors.onPrimaryContainer.withAlpha(180),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSmallValue(String label, String value, ColorScheme colors) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: colors.onPrimaryContainer.withAlpha(180),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: colors.onPrimaryContainer,
          ),
        ),
      ],
    );
  }

  IconData _getIcon() {
    switch (result.measurementType) {
      case MeasurementType.weight:
        return Icons.monitor_weight;
      case MeasurementType.bloodPressure:
        return Icons.favorite;
      case MeasurementType.temperature:
        return Icons.thermostat;
      case MeasurementType.spo2:
        return Icons.air;
      case MeasurementType.bodyComposition:
        return Icons.accessibility_new;
      case MeasurementType.glucometer:
        return Icons.bloodtype;
      default:
        return Icons.check_circle;
    }
  }
}

/// Simple connection status indicator
class ConnectionStatusBar extends StatelessWidget {
  final HealthEventData? currentEvent;

  const ConnectionStatusBar({super.key, this.currentEvent});

  @override
  Widget build(BuildContext context) {
    if (currentEvent == null) return const SizedBox.shrink();

    final colors = Theme.of(context).colorScheme;
    final state = currentEvent!.connectionState;
    final stateColor = _getStateColor(state, colors);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: stateColor.withAlpha(25), // More subtle background
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: stateColor.withAlpha(50),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          if (state == HealthConnectionState.scanning ||
              state == HealthConnectionState.connecting ||
              state == HealthConnectionState.measuring)
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: stateColor,
              ),
            )
          else
            Icon(_getStateIcon(state), color: stateColor, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              currentEvent!.message.isNotEmpty
                  ? currentEvent!.message
                  : state.name,
              style: TextStyle(
                color: stateColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (currentEvent!.progress > 0 && currentEvent!.progress < 100)
            Text(
              '${currentEvent!.progress}%',
              style: TextStyle(
                color: stateColor,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }

  Color _getStateColor(HealthConnectionState state, ColorScheme colors) {
    switch (state) {
      case HealthConnectionState.disconnected:
        return colors.outline;
      case HealthConnectionState.scanning:
      case HealthConnectionState.connecting:
        return const Color(0xFFF59E0B); // Amber
      case HealthConnectionState.connected:
      case HealthConnectionState.ready:
        return const Color(0xFF10B981); // Teal
      case HealthConnectionState.measuring:
      case HealthConnectionState.recording:
        return const Color(0xFF6366F1); // Indigo
      case HealthConnectionState.completed:
        return const Color(0xFF059669); // Emerald
      case HealthConnectionState.error:
        return colors.error;
      case HealthConnectionState.unknown:
        return colors.outline;
    }
  }

  IconData _getStateIcon(HealthConnectionState state) {
    switch (state) {
      case HealthConnectionState.disconnected:
        return Icons.bluetooth_disabled;
      case HealthConnectionState.scanning:
        return Icons.bluetooth_searching;
      case HealthConnectionState.connecting:
        return Icons.bluetooth_connected;
      case HealthConnectionState.connected:
      case HealthConnectionState.ready:
        return Icons.bluetooth_connected;
      case HealthConnectionState.measuring:
      case HealthConnectionState.recording:
        return Icons.pending;
      case HealthConnectionState.completed:
        return Icons.check_circle;
      case HealthConnectionState.error:
        return Icons.error;
      case HealthConnectionState.unknown:
        return Icons.help_outline;
    }
  }
}
