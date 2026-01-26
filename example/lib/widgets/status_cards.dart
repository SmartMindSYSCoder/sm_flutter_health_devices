import 'package:flutter/material.dart';
import 'package:sm_flutter_health_devices/sm_flutter_health_devices.dart';

/// Card showing plugin initialization status
class StatusCard extends StatelessWidget {
  final bool isInitialized;
  final bool isLoading;
  final String statusMessage;
  final VoidCallback onTap;

  const StatusCard({
    super.key,
    required this.isInitialized,
    required this.isLoading,
    required this.statusMessage,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      color: isInitialized
          ? colors.primaryContainer
          : colors.surfaceContainerHighest,
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              _buildIcon(colors),
              const SizedBox(width: 16),
              Expanded(child: _buildText(colors)),
              if (!isInitialized && !isLoading)
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: colors.outline,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(ColorScheme colors) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isInitialized ? colors.primary : colors.outline.withAlpha(51),
        borderRadius: BorderRadius.circular(12),
      ),
      child: isLoading
          ? SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colors.onPrimary,
              ),
            )
          : Icon(
              isInitialized ? Icons.check_circle : Icons.power_settings_new,
              color: isInitialized ? colors.onPrimary : colors.outline,
            ),
    );
  }

  Widget _buildText(ColorScheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isInitialized ? 'Plugin Ready' : 'Initialize Plugin',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: isInitialized ? colors.onPrimaryContainer : colors.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          statusMessage,
          style: TextStyle(
            color: isInitialized
                ? colors.onPrimaryContainer.withAlpha(179)
                : colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// Card showing permission status
class PermissionCard extends StatelessWidget {
  final PermissionResult permissions;

  const PermissionCard({
    super.key,
    required this.permissions,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.security, color: colors.primary),
                const SizedBox(width: 8),
                Text(
                  'Permissions',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _PermissionChip(
                  label: 'Bluetooth',
                  granted: permissions.isBluetoothGranted,
                ),
                _PermissionChip(
                  label: 'Location',
                  granted: permissions.location.isGranted,
                ),
                _PermissionChip(
                  label: 'GPS',
                  granted: permissions.isLocationServiceEnabled,
                ),
                _PermissionChip(
                  label: 'Microphone',
                  granted: permissions.isMicrophoneGranted,
                ),
                _PermissionChip(
                  label: 'Network',
                  granted: permissions.isNetworkConnected,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PermissionChip extends StatelessWidget {
  final String label;
  final bool granted;

  const _PermissionChip({
    required this.label,
    required this.granted,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: granted ? colors.primaryContainer : colors.errorContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            granted ? Icons.check : Icons.close,
            size: 16,
            color:
                granted ? colors.onPrimaryContainer : colors.onErrorContainer,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color:
                  granted ? colors.onPrimaryContainer : colors.onErrorContainer,
            ),
          ),
        ],
      ),
    );
  }
}
