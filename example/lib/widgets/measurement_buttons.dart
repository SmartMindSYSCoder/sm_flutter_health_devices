import 'package:flutter/material.dart';
import 'package:sm_flutter_health_devices/sm_flutter_health_devices.dart';
import '../app/theme.dart';

/// Simple measurement button for quick access
class MeasurementButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isLoading;
  final VoidCallback onTap;

  const MeasurementButton({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    this.isLoading = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: color.withAlpha(25),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withAlpha(40),
                  shape: BoxShape.circle,
                ),
                child: isLoading
                    ? SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: color,
                        ),
                      )
                    : Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// All measurement buttons in a nice grid
class MeasurementButtonsGrid extends StatelessWidget {
  final MeasurementType? activeMeasurement;
  final void Function(MeasurementType type) onMeasurementTap;

  const MeasurementButtonsGrid({
    super.key,
    this.activeMeasurement,
    required this.onMeasurementTap,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 0.85,
      children: [
        MeasurementButton(
          icon: Icons.monitor_weight_rounded,
          label: 'Weight',
          color: AppTheme.weightColor,
          isLoading: activeMeasurement == MeasurementType.weight,
          onTap: () => onMeasurementTap(MeasurementType.weight),
        ),
        MeasurementButton(
          icon: Icons.favorite_rounded,
          label: 'Blood\nPressure',
          color: AppTheme.bloodPressureColor,
          isLoading: activeMeasurement == MeasurementType.bloodPressure,
          onTap: () => onMeasurementTap(MeasurementType.bloodPressure),
        ),
        MeasurementButton(
          icon: Icons.thermostat_rounded,
          label: 'Temp',
          color: AppTheme.temperatureColor,
          isLoading: activeMeasurement == MeasurementType.temperature,
          onTap: () => onMeasurementTap(MeasurementType.temperature),
        ),
        MeasurementButton(
          icon: Icons.air_rounded,
          label: 'SpO2',
          color: AppTheme.spo2Color,
          isLoading: activeMeasurement == MeasurementType.spo2,
          onTap: () => onMeasurementTap(MeasurementType.spo2),
        ),
        MeasurementButton(
          icon: Icons.accessibility_new_rounded,
          label: 'Body\nComp',
          color: AppTheme.bodyCompColor,
          isLoading: activeMeasurement == MeasurementType.bodyComposition,
          onTap: () => onMeasurementTap(MeasurementType.bodyComposition),
        ),
        MeasurementButton(
          icon: Icons.bloodtype_rounded,
          label: 'Glucose',
          color: AppTheme.glucoseColor,
          isLoading: activeMeasurement == MeasurementType.glucometer,
          onTap: () => onMeasurementTap(MeasurementType.glucometer),
        ),
      ],
    );
  }
}
