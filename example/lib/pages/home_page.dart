import 'package:flutter/material.dart';
import 'package:sm_flutter_health_devices/sm_flutter_health_devices.dart';
import '../controllers/health_controller.dart';
import '../dialogs/dialogs.dart';
import '../widgets/widgets.dart';
import 'demo_usage_page.dart';

/// Main home page with professional UI/UX
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final HealthController _controller;
  MeasurementType? _activeMeasurement;
  bool _isMeasuring = false;

  static const String _kFitrusApiKey =
      'vrmCquCRjqTKGQNt3b9pEYy6NhjOL45Mi3d56I16RGTuCAeDNXW53kDaJGn7KUii5SAnHAdtcNoIlnJUk5M5HIj3mJpKAzsIIDilz0bKwdIekWot5X1KyCBMUXBGmICS';

  @override
  void initState() {
    super.initState();
    _controller = HealthController();
    _controller.addListener(_onControllerChanged);
  }

  void _onControllerChanged() {
    if (!mounted) return;

    // Check for completion or error to reset UI
    // Also check if we have a result (failsafe)
    final isComplete = _checkLatestEventForCompletion();
    final hasResult = _controller.lastResult != null;

    if (_isMeasuring && (isComplete || hasResult)) {
      setState(() {
        _isMeasuring = false;
        _activeMeasurement = null;
      });
    }

    // Just refresh UI (e.g., for progress updates)
    setState(() {});
  }

  bool _checkLatestEventForCompletion() {
    final events = _controller.events;
    if (events.isEmpty) return false;
    final latest = events.first;
    return latest.isCompleted || latest.hasError;
  }

  Future<void> _cancelMeasurement() async {
    setState(() {
      _isMeasuring = false;
      _activeMeasurement = null;
    });
    // Call native stop through controller
    await _controller.cancelMeasurement();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Measurement cancelled'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        title: const Text(
          'Health Devices',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: Icon(Icons.settings_outlined, color: colors.primary),
            tooltip: 'Measurement Settings',
            onPressed: () {
              final theme = Theme.of(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SmHealthSettingsPage(
                    style: SmHealthSettingsStyle(
                      primaryColor: theme.primaryColor,
                      cardShape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: theme.dividerColor.withOpacity(0.1),
                        ),
                      ),
                      backgroundColor: theme.scaffoldBackgroundColor,
                    ),
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.info_outline, color: colors.primary),
            tooltip: 'View Widget Demo',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DemoUsagePage()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),

              // Init Button or Main Content
              if (!_controller.isInitialized)
                _buildInitButton(colors)
              else ...[
                // Active Measurement Status Card
                if (_isMeasuring && _controller.events.isNotEmpty)
                  _buildMeasurementStatusCard(colors),

                // Result Card
                if (_controller.lastResult != null && !_isMeasuring) ...[
                  const SizedBox(height: 16),
                  ResultCard(
                    result: _controller.lastResult!,
                    onDismiss: _controller.clearLastResult,
                  ),
                ],

                const SizedBox(height: 20),

                // Section Title
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Measurements',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: colors.onSurface,
                      ),
                    ),
                    if (_isMeasuring)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: colors.primaryContainer,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colors.primary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Measuring...',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: colors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // Measurement Buttons Grid
                MeasurementButtonsGrid(
                  activeMeasurement: _activeMeasurement,
                  onMeasurementTap:
                      _isMeasuring ? (_) {} : _handleMeasurementTap,
                ),
              ],

              const Spacer(),

              // Permission chips at bottom
              if (_controller.permissions != null) _buildPermissionRow(colors),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMeasurementStatusCard(ColorScheme colors) {
    final latest = _controller.events.first;
    final progress = latest.progress;
    final safeMax = latest.maxProgress > 0 ? latest.maxProgress : 100;
    final hasProgress = progress > 0 && progress < safeMax;

    return Card(
      elevation: 0,
      color: colors.primaryContainer.withAlpha(100),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.primary.withAlpha(50)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colors.primary.withAlpha(30),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _getMeasurementIcon(_activeMeasurement),
                    color: colors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _activeMeasurement?.displayName ?? 'Measuring',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: colors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        latest.message,
                        style: TextStyle(
                          fontSize: 13,
                          color: colors.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Progress bar
            if (hasProgress) ...[
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress / safeMax,
                  minHeight: 8,
                  backgroundColor: colors.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation(colors.primary),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    safeMax == 100 ? '$progress%' : '$progress',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: colors.primary,
                    ),
                  ),
                  if (safeMax != 100)
                    Text(
                      'Max: $safeMax',
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ],

            const SizedBox(height: 16),

            // Cancel Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _cancelMeasurement,
                icon: const Icon(Icons.close, size: 18),
                label: const Text('Cancel Measurement'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colors.error,
                  side: BorderSide(color: colors.error.withAlpha(100)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getMeasurementIcon(MeasurementType? type) {
    switch (type) {
      case MeasurementType.weight:
        return Icons.monitor_weight_outlined;
      case MeasurementType.bloodPressure:
        return Icons.favorite_outline;
      case MeasurementType.temperature:
        return Icons.thermostat_outlined;
      case MeasurementType.spo2:
        return Icons.air_outlined;
      case MeasurementType.bodyComposition:
        return Icons.accessibility_new_outlined;
      case MeasurementType.glucometer:
        return Icons.water_drop_outlined;
      default:
        return Icons.health_and_safety_outlined;
    }
  }

  Widget _buildInitButton(ColorScheme colors) {
    return FilledButton.icon(
      onPressed: _controller.isLoading ? null : _controller.initialize,
      icon: _controller.isLoading
          ? SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colors.onPrimary,
              ),
            )
          : const Icon(Icons.bluetooth),
      label:
          Text(_controller.isLoading ? 'Initializing...' : 'Connect Devices'),
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Widget _buildPermissionRow(ColorScheme colors) {
    final perms = _controller.permissions!;

    return Wrap(
      spacing: 8,
      runSpacing: 6,
      alignment: WrapAlignment.center,
      children: [
        _buildMiniChip('BT', perms.isBluetoothGranted, colors),
        _buildMiniChip('GPS', perms.isLocationServiceEnabled, colors),
        _buildMiniChip('LOC', perms.location.isGranted, colors),
      ],
    );
  }

  Widget _buildMiniChip(String label, bool ok, ColorScheme colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: ok ? colors.primaryContainer : colors.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            ok ? Icons.check : Icons.close,
            size: 12,
            color: ok ? colors.onPrimaryContainer : colors.onErrorContainer,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: ok ? colors.onPrimaryContainer : colors.onErrorContainer,
            ),
          ),
        ],
      ),
    );
  }

  void _handleMeasurementTap(MeasurementType type) {
    switch (type) {
      case MeasurementType.bodyComposition:
        _startBodyComposition();
        break;
      case MeasurementType.glucometer:
        _startGlucose();
        break;
      default:
        _startMeasurement(type, null);
    }
  }

  Future<void> _startMeasurement(
      MeasurementType type, DeviceProvider? provider) async {
    final activeProvider = provider ??
        _controller.healthDevices.settingsManager.getPreferredProvider(type);

    setState(() {
      _activeMeasurement = type;
      _isMeasuring = true; // Show status card
    });

    try {
      if (activeProvider == DeviceProvider.omron) {
        await _handleOmronMeasurement(type);
      } else {
        await _controller.startMeasurement(type, activeProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
      setState(() {
        _isMeasuring = false;
        _activeMeasurement = null;
      });
    }
  }

  Future<void> _handleOmronMeasurement(MeasurementType type) async {
    // 1. Map type to Omron Category
    final category = OmronAdapter.toDeviceCategory(type);
    if (category == null) {
      throw 'Measurement type not supported by Omron';
    }

    // 2. Check for saved device of this category
    final savedDevices = await _controller.getSavedOmronDevices();

    // Find first device matching the category
    // Note: MC-280B-E might be used for temp, which is category temperature
    ScannedDevice? targetDevice;

    for (var device in savedDevices) {
      if (_isDeviceCategoryMatch(device, category)) {
        targetDevice = device;
        break;
      }
    }

    // 3. If no device, show selector dialog
    if (targetDevice == null) {
      if (!mounted) return;

      final selectedModel = await OmronDeviceSelectorDialog.show(
        context,
        categoryFilter: category,
        backgroundColor: Theme.of(context).colorScheme.surface,
        contentBackgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      );

      if (selectedModel == null) {
        // User cancelled
        setState(() {
          _isMeasuring = false;
          _activeMeasurement = null;
        });
        return;
      }

      // 4. Scan and Pair
      // The controller generates events during this process so UI updates
      targetDevice = await _controller.scanAndPairOmron(selectedModel);

      if (targetDevice == null) {
        // Failed to pair or find
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Device not found or pairing failed')),
          );
        }
        setState(() {
          _isMeasuring = false;
          _activeMeasurement = null;
        });
        return;
      }
    }

    // 5. Start Measurement with the device
    if (mounted) {
      await _controller.startOmronMeasurement(type, targetDevice);
    }
  }

  bool _isDeviceCategoryMatch(ScannedDevice device, DeviceCategory category) {
    // Helper to check category match loosely (string/int) or strictly
    // ScannedDevice.category is dynamic or String usually "1", "2" etc.
    // deviceCategory maps it to enum
    return device.deviceCategory == category;
  }

  /// Body composition with ONE-TAP measurement (auto-init)
  Future<void> _startBodyComposition() async {
    await BodyCompositionDialog.show(
      context,
      onStart: (height, weight, gender, birthDate) async {
        setState(() {
          _activeMeasurement = MeasurementType.bodyComposition;
          _isMeasuring = true;
        });

        await _controller.startBodyComposition(
          apiKey: _kFitrusApiKey,
          heightCm: height,
          weightKg: weight,
          gender: gender,
          birthDate: birthDate,
        );
      },
    );
  }

  Future<void> _startGlucose() async {
    setState(() {
      _activeMeasurement = MeasurementType.glucometer;
      _isMeasuring = true;
    });

    await _controller.startGlucose();
  }
}
