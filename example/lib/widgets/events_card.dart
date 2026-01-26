import 'package:flutter/material.dart';
import 'package:sm_flutter_health_devices/sm_flutter_health_devices.dart';

/// Card showing live events from health devices
class EventsCard extends StatelessWidget {
  final List<HealthEventData> events;
  final int maxEvents;

  const EventsCard({
    super.key,
    required this.events,
    this.maxEvents = 10,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    if (events.isEmpty) {
      return _buildEmptyState(colors);
    }

    return Card(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: events.length.clamp(0, maxEvents),
        separatorBuilder: (_, __) => Divider(
          height: 1,
          color: colors.outlineVariant,
        ),
        itemBuilder: (context, index) {
          return EventTile(event: events[index]);
        },
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colors) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.bluetooth_searching,
                size: 48,
                color: colors.outline.withAlpha(128),
              ),
              const SizedBox(height: 12),
              Text(
                'No events yet',
                style: TextStyle(color: colors.onSurfaceVariant),
              ),
              const SizedBox(height: 4),
              Text(
                'Start a measurement to see live events',
                style: TextStyle(
                  fontSize: 12,
                  color: colors.outline,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Single event tile
class EventTile extends StatelessWidget {
  final HealthEventData event;

  const EventTile({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final stateColor = _getStateColor(event.connectionState, colors);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: stateColor.withAlpha(38),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          _getProviderIcon(event.provider),
          color: stateColor,
          size: 20,
        ),
      ),
      title: Text(
        event.measurementType.displayName,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        event.message.isNotEmpty ? event.message : event.connectionState.name,
        style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
      ),
      trailing: _buildTrailing(colors, stateColor),
    );
  }

  Widget _buildTrailing(ColorScheme colors, Color stateColor) {
    if (event.progress > 0 && event.progress < 100) {
      return SizedBox(
        width: 40,
        height: 40,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CircularProgressIndicator(
              value: event.progress / 100,
              strokeWidth: 3,
              color: stateColor,
            ),
            Text(
              '${event.progress}%',
              style: const TextStyle(fontSize: 10),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: stateColor.withAlpha(38),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        event.connectionState.name,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: stateColor,
        ),
      ),
    );
  }

  Color _getStateColor(HealthConnectionState state, ColorScheme colors) {
    switch (state) {
      case HealthConnectionState.disconnected:
        return colors.outline;
      case HealthConnectionState.scanning:
      case HealthConnectionState.connecting:
        // Amber/Orange for work in progress
        return const Color(0xFFF59E0B);
      case HealthConnectionState.connected:
      case HealthConnectionState.ready:
        // Teal/Emerald for secure connection
        return const Color(0xFF10B981);
      case HealthConnectionState.measuring:
      case HealthConnectionState.recording:
        // Indigo for active measurement
        return const Color(0xFF6366F1);
      case HealthConnectionState.completed:
        return const Color(0xFF059669);
      case HealthConnectionState.error:
        return colors.error;
      case HealthConnectionState.unknown:
        return colors.outline;
    }
  }

  IconData _getProviderIcon(DeviceProvider provider) {
    switch (provider) {
      case DeviceProvider.omron:
        return Icons.medical_services_outlined;
      case DeviceProvider.lepu:
        return Icons.bluetooth_connected;
      case DeviceProvider.fitrus:
        return Icons.accessibility;
      case DeviceProvider.accucheck:
        return Icons.bloodtype;
      case DeviceProvider.raycome:
        return Icons.devices;
      case DeviceProvider.unknown:
        return Icons.device_unknown;
    }
  }
}
