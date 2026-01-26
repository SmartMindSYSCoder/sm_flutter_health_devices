import 'package:flutter/material.dart';
import 'package:sm_flutter_health_devices/sm_flutter_health_devices.dart';
import '../app/theme.dart';

/// Data class for measurement card configuration
class MeasurementCardData {
  final MeasurementType type;
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const MeasurementCardData({
    required this.type,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  /// All available measurements
  static List<MeasurementCardData> get all => [
        const MeasurementCardData(
          type: MeasurementType.weight,
          icon: Icons.monitor_weight_outlined,
          title: 'Weight',
          subtitle: 'Omron, Lepu',
          color: AppTheme.weightColor,
        ),
        const MeasurementCardData(
          type: MeasurementType.bloodPressure,
          icon: Icons.favorite_outline,
          title: 'Blood Pressure',
          subtitle: 'Omron, Lepu',
          color: AppTheme.bloodPressureColor,
        ),
        const MeasurementCardData(
          type: MeasurementType.temperature,
          icon: Icons.thermostat_outlined,
          title: 'Temperature',
          subtitle: 'Omron, Lepu',
          color: AppTheme.temperatureColor,
        ),
        const MeasurementCardData(
          type: MeasurementType.spo2,
          icon: Icons.air_outlined,
          title: 'SpO2',
          subtitle: 'Omron, Lepu',
          color: AppTheme.spo2Color,
        ),
        const MeasurementCardData(
          type: MeasurementType.bodyComposition,
          icon: Icons.accessibility_new_outlined,
          title: 'Body Composition',
          subtitle: 'Fitrus',
          color: AppTheme.bodyCompColor,
        ),
        const MeasurementCardData(
          type: MeasurementType.glucometer,
          icon: Icons.bloodtype_outlined,
          title: 'Blood Glucose',
          subtitle: 'AccuChek',
          color: AppTheme.glucoseColor,
        ),
      ];
}

/// Simple card widget for a measurement type
class MeasurementCard extends StatelessWidget {
  final MeasurementCardData data;
  final VoidCallback onTap;

  const MeasurementCard({
    super.key,
    required this.data,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: data.color.withAlpha(38),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(data.icon, color: data.color, size: 24),
              ),
              const Spacer(),
              // Title
              Text(
                data.title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              // Subtitle
              Text(
                data.subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Grid of all measurement cards
class MeasurementsGrid extends StatelessWidget {
  final void Function(MeasurementCardData data) onMeasurementTap;

  const MeasurementsGrid({
    super.key,
    required this.onMeasurementTap,
  });

  @override
  Widget build(BuildContext context) {
    final measurements = MeasurementCardData.all;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.3,
      ),
      itemCount: measurements.length,
      itemBuilder: (context, index) {
        final data = measurements[index];
        return MeasurementCard(
          data: data,
          onTap: () => onMeasurementTap(data),
        );
      },
    );
  }
}
