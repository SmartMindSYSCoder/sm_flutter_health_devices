import 'dart:async';
import 'package:flutter/material.dart';
import '../../sm_flutter_health_devices.dart';
import 'package:sm_omron/sm_omron.dart' as omron;

class SmOmronDevicesPage extends StatefulWidget {
  final SmHealthSettingsStyle style;

  const SmOmronDevicesPage({
    super.key,
    required this.style,
  });

  static Future<void> open(BuildContext context, SmHealthSettingsStyle style) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SmOmronDevicesPage(style: style),
      ),
    );
  }

  @override
  State<SmOmronDevicesPage> createState() => _SmOmronDevicesPageState();
}

class _SmOmronDevicesPageState extends State<SmOmronDevicesPage> {
  final SmHealthDevices _healthDevices = SmHealthDevices();
  List<omron.ScannedDevice> _savedDevices = [];
  bool _isLoading = true;

  // State for scanning/pairing feedback
  omron.OmronConnectionState _connectionState = omron.OmronConnectionState.idle;
  String? _statusMessage;
  bool _isOperationInProgress = false;
  StreamSubscription<omron.OmronConnectionState>? _stateSubscription;

  @override
  void initState() {
    super.initState();
    _initPlugin();
  }

  Future<void> _initPlugin() async {
    await _healthDevices.init();
    _loadDevices();

    // Listen to connection state changes from Omron
    _stateSubscription =
        _healthDevices.omronPlugin.connectionStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _connectionState = state;
          if (_isOperationInProgress) {
            _statusMessage = _getStatusDescription(state);
          }
        });
      }
    });
  }

  String _getStatusDescription(omron.OmronConnectionState state) {
    switch (state) {
      case omron.OmronConnectionState.scanning:
        return "Searching for device...";
      case omron.OmronConnectionState.connecting:
        return "Connecting...";
      case omron.OmronConnectionState.connected:
        return "Connected! Finalizing...";
      case omron.OmronConnectionState.disconnecting:
        return "Disconnecting...";
      case omron.OmronConnectionState.disconnected:
        return "Disconnected.";
      case omron.OmronConnectionState.idle:
        return "Idle.";
      default:
        return state.statusMessage;
    }
  }

  @override
  void dispose() {
    _stateSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadDevices() async {
    setState(() => _isLoading = true);
    try {
      final devices = await _healthDevices.getSavedOmronDevices();
      setState(() {
        _savedDevices = devices;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Error loading devices: $e');
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _addDevice() async {
    // 1. Check Permissions and Services
    final permissions = _healthDevices.permissions;

    // Bluetooth check
    bool btGranted = await permissions.checkBluetoothPermissions();
    if (!btGranted) {
      final result = await permissions.requestBasePermissions();
      btGranted = result.isBluetoothGranted;
    }

    if (!btGranted) {
      _showError("Bluetooth permission is required to scan for devices.");
      return;
    }

    bool btEnabled = await permissions.isBluetoothEnabled();
    if (!btEnabled) {
      _showError("Please turn on Bluetooth to scan for devices.");
      return;
    }

    // Location check (required for BLE on many Android versions)
    bool locGranted = await permissions.checkLocationPermission();
    if (!locGranted) {
      // requestBasePermissions also handles location
      final result = await permissions.requestBasePermissions();
      locGranted = result.location.isGranted;
    }

    if (!locGranted) {
      _showError("Location permission is required to scan for BLE devices.");
      return;
    }

    bool locEnabled = await permissions.isLocationServiceEnabled();
    if (!locEnabled) {
      _showError("Please enable Location services to scan for BLE devices.");
      return;
    }

    // 2. Show Selector
    final deviceModel = await omron.OmronDeviceSelectorDialog.show(
      context,
      title: const Text("Select Omron Device"),
    );

    if (deviceModel == null) return;

    setState(() {
      _isOperationInProgress = true;
      _statusMessage = "Starting...";
    });

    try {
      omron.ScannedDevice? scannedDevice;

      // Show progress overlay
      _showProgressDialog(deviceModel.modelName ?? "Device");

      if (deviceModel.isRecordingWave) {
        scannedDevice = _healthDevices.createOmronRecordingDevice(deviceModel);
      } else if (deviceModel.deviceIdentifier != null) {
        setState(
            () => _statusMessage = "Scanning for ${deviceModel.modelName}...");
        scannedDevice = await _healthDevices.scanOmronBleDevice(
          deviceIdentifier: deviceModel.deviceIdentifier!,
          timeout: const Duration(seconds: 30),
        );
      }

      if (scannedDevice != null) {
        if (!deviceModel.isRecordingWave) {
          setState(() =>
              _statusMessage = "Pairing with ${scannedDevice?.modelName}...");
          final paired =
              await _healthDevices.pairOmronBleDevice(device: scannedDevice!);
          if (!paired) {
            _closeProgressDialog();
            _showError('Pairing failed. Please try again.');
            return;
          }
        }

        await _healthDevices.saveOmronDevice(scannedDevice);
        _closeProgressDialog();
        _loadDevices();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Device added successfully!'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        _closeProgressDialog();
        _showError('Device not found. Ensure it is in pairing mode.');
      }
    } catch (e) {
      _closeProgressDialog();
      _showError('Error adding device: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isOperationInProgress = false;
          _statusMessage = null;
        });
      }
    }
  }

  void _showProgressDialog(String modelName) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                const CircularProgressIndicator(),
                const SizedBox(height: 24),
                Text(
                  "Configuring $modelName",
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 12),
                Text(
                  _statusMessage ?? "Processing...",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _closeProgressDialog() {
    if (mounted) Navigator.of(context, rootNavigator: true).pop();
  }

  Future<void> _deleteDevice(omron.ScannedDevice device) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Device?'),
        content: Text(
            'This will unpair and remove ${device.modelName} from your saved devices.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _healthDevices.removeOmronDevice(device);
      _loadDevices();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final style = widget.style;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Omron Devices',
          style: style.titleTextStyle ??
              const TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: Colors.white),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          _buildBluetoothStatus(colors),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              style.primaryColor?.withOpacity(0.8) ?? colors.primary,
              style.secondaryColor?.withOpacity(0.6) ?? colors.tertiary,
              colors.surface.withOpacity(0.95),
            ],
            stops: const [0.0, 0.4, 1.0],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.white))
              : _savedDevices.isEmpty
                  ? _buildEmptyState(colors, style)
                  : _buildDeviceList(colors, style),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addDevice,
        backgroundColor: Colors.white,
        foregroundColor: style.primaryColor ?? colors.primary,
        elevation: 4,
        highlightElevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: const Icon(Icons.add_rounded, weight: 800),
        label: const Text(
          'Add New Device',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
      ),
    );
  }

  Widget _buildBluetoothStatus(ColorScheme colors) {
    bool isActive = _connectionState != omron.OmronConnectionState.idle &&
        _connectionState != omron.OmronConnectionState.disconnected;

    if (!isActive) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.greenAccent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _connectionState.statusMessage.toUpperCase(),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colors, SmHealthSettingsStyle style) {
    return Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 800),
        builder: (context, value, child) {
          return Opacity(
            opacity: value,
            child: Transform.scale(
              scale: 0.8 + (0.2 * value),
              child: child,
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Icon(
                  Icons.bluetooth_searching_rounded,
                  size: 80,
                  color: Colors.white.withOpacity(0.5),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'No Devices Yet',
                style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              const SizedBox(height: 16),
              Text(
                'Connect your Omron health equipment to start tracking your vitals magically.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 16,
                    height: 1.5),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: 240,
                child: ElevatedButton(
                  onPressed: _addDevice,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.2),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: Colors.white.withOpacity(0.3)),
                    ),
                  ),
                  child: const Text(
                    'Pair New Device',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeviceList(ColorScheme colors, SmHealthSettingsStyle style) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      physics: const BouncingScrollPhysics(),
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 16),
          child: Text(
            "YOUR EQUIPMENT",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
              color: Colors.white.withOpacity(0.5),
            ),
          ),
        ),
        ..._savedDevices.asMap().entries.map((entry) {
          final index = entry.key;
          final device = entry.value;
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 600 + (index * 150)),
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: child,
                ),
              );
            },
            child: _buildDeviceCard(device, colors, style),
          );
        }),
        const SizedBox(height: 100), // Space for FAB
      ],
    );
  }

  Widget _buildDeviceCard(omron.ScannedDevice device, ColorScheme colors,
      SmHealthSettingsStyle style) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {},
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(
                      _getCategoryIcon(device.deviceCategory),
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          device.modelName ?? 'Unknown Device',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'SN: ${device.localName ?? "N/A"}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.delete_sweep_rounded,
                          color: Colors.redAccent, size: 24),
                      onPressed: () => _deleteDevice(device),
                      tooltip: "Remove device",
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(omron.DeviceCategory category) {
    switch (category) {
      case omron.DeviceCategory.bloodPressure:
        return Icons.favorite_outline;
      case omron.DeviceCategory.weight:
        return Icons.monitor_weight_outlined;
      case omron.DeviceCategory.pulseOximeter:
        return Icons.air_outlined;
      case omron.DeviceCategory.temperature:
        return Icons.thermostat_outlined;
      case omron.DeviceCategory.activity:
        return Icons.directions_walk;
      default:
        return Icons.device_hub;
    }
  }
}
