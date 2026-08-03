import 'dart:async';
import 'package:flutter/material.dart';
import '../../sm_flutter_health_devices.dart';
import 'package:sm_omron/sm_omron.dart' as omron;

class SmOmronDevicesPage extends StatefulWidget {
  final SmHealthSettingsThemeData theme;
  final SmHealthInitConfig initConfig;

  const SmOmronDevicesPage({
    super.key,
    this.theme = const SmHealthSettingsThemeData(),
    this.initConfig = const SmHealthInitConfig(),
  });

  static Future<void> open(
    BuildContext context, {
    SmHealthSettingsThemeData theme = const SmHealthSettingsThemeData(),
    SmHealthInitConfig initConfig = const SmHealthInitConfig(),
  }) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SmOmronDevicesPage(
          theme: theme,
          initConfig: initConfig,
        ),
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

  SmHealthSettingsTranslations get _translations =>
      SmHealthSettingsTranslations(widget.initConfig.lang);

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
    await _healthDevices.init(
      config: HealthDevicesConfig(
        fitrusApiKey: widget.initConfig.fitrusApiKey,
        omronApiKey: widget.initConfig.omronApiKey,
        timeout: widget.initConfig.timeout,
        measuringTimeout: widget.initConfig.measuringTimeout,
      ),
    );
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
    return _translations.omronStatus(state);
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
      _showError(_translations.errorLoadingDevices(e));
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: widget.theme.dangerColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _addDevice() async {
    final settingsTheme = widget.theme;

    // 1. Check Permissions and Services
    final permissions = _healthDevices.permissions;

    // Bluetooth check
    bool btGranted = await permissions.checkBluetoothPermissions();
    if (!btGranted) {
      final result = await permissions.requestBasePermissions();
      btGranted = result.isBluetoothGranted;
    }

    if (!btGranted) {
      _showError(_translations.bluetoothPermissionRequired);
      return;
    }

    bool btEnabled = await permissions.isBluetoothEnabled();
    if (!btEnabled) {
      _showError(_translations.enableBluetooth);
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
      _showError(_translations.locationPermissionRequired);
      return;
    }

    bool locEnabled = await permissions.isLocationServiceEnabled();
    if (!locEnabled) {
      _showError(_translations.enableLocation);
      return;
    }

    if (!mounted) return;

    // 2. Show Selector
    final deviceModel = await _showDeviceSelector(settingsTheme);

    if (deviceModel == null) return;

    setState(() {
      _isOperationInProgress = true;
      _statusMessage = _translations.starting;
    });

    try {
      omron.ScannedDevice? scannedDevice;

      // Show progress overlay
      _showProgressDialog(deviceModel.modelName ?? _translations.unknownDevice);

      if (deviceModel.isRecordingWave) {
        scannedDevice = _healthDevices.createOmronRecordingDevice(deviceModel);
      } else if (deviceModel.deviceIdentifier != null) {
        setState(() =>
            _statusMessage = _translations.scanningFor(deviceModel.modelName));
        scannedDevice = await _healthDevices.scanOmronBleDevice(
          deviceIdentifier: deviceModel.deviceIdentifier!,
          timeout: widget.initConfig.timeout,
        );
      }

      if (scannedDevice != null) {
        if (!deviceModel.isRecordingWave) {
          final scannedDeviceName = scannedDevice.modelName;
          setState(() =>
              _statusMessage = _translations.pairingWith(scannedDeviceName));

          omron.PersonalInfo? personalInfo;
          if (widget.initConfig.userProfile != null) {
            final profile = widget.initConfig.userProfile!;
            DateTime dob;
            try {
              if (profile.birthDate.length == 8) {
                final year = int.parse(profile.birthDate.substring(0, 4));
                final month = int.parse(profile.birthDate.substring(4, 6));
                final day = int.parse(profile.birthDate.substring(6, 8));
                dob = DateTime(year, month, day);
              } else {
                dob = DateTime.parse(profile.birthDate);
              }
            } catch (_) {
              dob = DateTime(1990, 1, 1);
            }
            personalInfo = omron.PersonalInfo(
              heightCm: profile.heightCm,
              weightKg: profile.weightKg,
              strideCm: profile.heightCm * 0.415,
              dateOfBirth: dob,
              gender: profile.gender == Gender.male
                  ? omron.Gender.male
                  : omron.Gender.female,
            );
          }

          final paired = await _healthDevices.pairOmronBleDevice(
            device: scannedDevice,
            personalInfo: personalInfo,
          );
          if (!paired) {
            _closeProgressDialog();
            _showError(_translations.pairingFailed);
            return;
          }
        }

        await _healthDevices.saveOmronDevice(scannedDevice);
        _closeProgressDialog();
        _loadDevices();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_translations.deviceAddedSuccessfully),
              backgroundColor: widget.theme.successColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        _closeProgressDialog();
        _showError(_translations.deviceNotFound);
      }
    } catch (e) {
      _closeProgressDialog();
      _showError(_translations.errorAddingDevice(e));
    } finally {
      if (mounted) {
        setState(() {
          _isOperationInProgress = false;
          _statusMessage = null;
        });
      }
    }
  }

  Future<omron.DeviceModel?> _showDeviceSelector(
      SmHealthSettingsThemeData settingsTheme) {
    final colors = _buildColorScheme(settingsTheme);
    final textTheme = _buildTextTheme(settingsTheme);
    final translations = _translations;
    final smOmron = omron.SMOmron();
    var devicesFuture = smOmron.getSupportedDevices();

    return showDialog<omron.DeviceModel>(
      context: context,
      builder: (dialogContext) => Directionality(
        textDirection: translations.textDirection,
        child: Theme(
          data: ThemeData(
            useMaterial3: true,
            colorScheme: colors,
            textTheme: textTheme,
            dividerColor: colors.outlineVariant,
          ),
          child: Dialog(
            clipBehavior: Clip.antiAlias,
            backgroundColor: colors.surfaceContainer,
            surfaceTintColor: Colors.transparent,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 500, maxWidth: 400),
              child: StatefulBuilder(
                builder: (context, setDialogState) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              translations.selectOmronDevice,
                              style: textTheme.titleLarge,
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.close_rounded,
                              color: colors.onSurfaceVariant,
                            ),
                            onPressed: () => Navigator.of(dialogContext).pop(),
                          ),
                        ],
                      ),
                    ),
                    Divider(height: 1, color: colors.outlineVariant),
                    Flexible(
                      child: FutureBuilder<List<omron.DeviceModel>>(
                        future: devicesFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState !=
                              ConnectionState.done) {
                            return Center(
                              child: CircularProgressIndicator(
                                  color: colors.primary),
                            );
                          }

                          if (snapshot.hasError) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.error_outline,
                                        color: settingsTheme.dangerColor,
                                        size: 48),
                                    const SizedBox(height: 12),
                                    Text(
                                      translations
                                          .errorLoadingDevices(snapshot.error!),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 12),
                                    ElevatedButton(
                                      onPressed: () => setDialogState(() {
                                        devicesFuture =
                                            smOmron.getSupportedDevices();
                                      }),
                                      child: Text(translations.retry),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          final devices = snapshot.data ?? [];
                          if (devices.isEmpty) {
                            return Center(
                              child: Text(translations.noDevicesAvailable),
                            );
                          }

                          return ListView.separated(
                            itemCount: devices.length,
                            separatorBuilder: (context, index) => Divider(
                                height: 1, color: colors.outlineVariant),
                            itemBuilder: (context, index) {
                              final device = devices[index];
                              return ListTile(
                                leading: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: colors.primaryContainer,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    _getCategoryIcon(
                                        _getDeviceModelCategory(device)),
                                    color: colors.primary,
                                  ),
                                ),
                                title: Text(
                                  device.modelDisplayName ??
                                      device.modelName ??
                                      translations.unknownDevice,
                                  style: textTheme.titleSmall,
                                ),
                                subtitle: Text(
                                  device.identifier ?? '',
                                  style: textTheme.bodySmall,
                                ),
                                trailing: Icon(
                                  Icons.chevron_right_rounded,
                                  color: colors.outline,
                                ),
                                onTap: () =>
                                    Navigator.of(dialogContext).pop(device),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  omron.DeviceCategory _getDeviceModelCategory(omron.DeviceModel device) {
    return omron.DeviceCategory.fromValue(int.tryParse(device.category) ?? 1);
  }

  ColorScheme _buildColorScheme(SmHealthSettingsThemeData settingsTheme) {
    return ColorScheme.light(
      primary: settingsTheme.primaryColor,
      onPrimary: Colors.white,
      primaryContainer: settingsTheme.primarySoftColor,
      onPrimaryContainer: settingsTheme.textColor,
      surface: settingsTheme.backgroundColor,
      onSurface: settingsTheme.textColor,
      surfaceContainer: settingsTheme.cardColor,
      surfaceContainerHighest: settingsTheme.chipColor,
      onSurfaceVariant: settingsTheme.secondaryTextColor,
      outline: settingsTheme.secondaryTextColor,
      outlineVariant: settingsTheme.borderColor,
      error: settingsTheme.dangerColor,
    );
  }

  TextTheme _buildTextTheme(SmHealthSettingsThemeData settingsTheme) {
    return TextTheme(
      titleLarge: settingsTheme.resolvedTitleTextStyle,
      titleMedium: settingsTheme.resolvedItemTitleTextStyle,
      titleSmall: settingsTheme.resolvedItemTitleTextStyle.copyWith(
        fontSize: 14,
      ),
      bodySmall: settingsTheme.resolvedBodyTextStyle,
    );
  }

  void _showProgressDialog(String modelName) {
    final settingsTheme = widget.theme;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Directionality(
        textDirection: _translations.textDirection,
        child: AlertDialog(
          backgroundColor: settingsTheme.cardColor,
          surfaceTintColor: Colors.transparent,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              CircularProgressIndicator(color: settingsTheme.primaryColor),
              const SizedBox(height: 24),
              Text(
                _translations.configuring(modelName),
                style: settingsTheme.resolvedItemTitleTextStyle,
              ),
              const SizedBox(height: 12),
              Text(
                _statusMessage ?? _translations.processing,
                textAlign: TextAlign.center,
                style: settingsTheme.resolvedBodyTextStyle,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _closeProgressDialog() {
    if (mounted) Navigator.of(context, rootNavigator: true).pop();
  }

  Future<void> _deleteDevice(omron.ScannedDevice device) async {
    final settingsTheme = widget.theme;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: _translations.textDirection,
        child: AlertDialog(
          backgroundColor: settingsTheme.cardColor,
          surfaceTintColor: Colors.transparent,
          title: Text(
            _translations.removeDeviceQuestion,
            style: settingsTheme.resolvedTitleTextStyle,
          ),
          content: Text(
            _translations.removeDeviceDescription(device.modelName),
            style: settingsTheme.resolvedBodyTextStyle,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                _translations.cancel,
                style: TextStyle(color: settingsTheme.secondaryTextColor),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                _translations.remove,
                style: TextStyle(color: settingsTheme.dangerColor),
              ),
            ),
          ],
        ),
      ),
    );

    if (confirm == true) {
      await _healthDevices.removeOmronDevice(device);
      _loadDevices();
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsTheme = widget.theme;

    return Directionality(
      textDirection: _translations.textDirection,
      child: Scaffold(
        backgroundColor: settingsTheme.backgroundColor,
        appBar: AppBar(
          title: Text(
            _translations.omronDevices,
            style: settingsTheme.resolvedTitleTextStyle,
          ),
          centerTitle: true,
          elevation: 0,
          backgroundColor: settingsTheme.backgroundColor,
          surfaceTintColor: Colors.transparent,
          iconTheme: IconThemeData(color: settingsTheme.primaryColor),
          actions: [
            _buildBluetoothStatus(settingsTheme),
          ],
        ),
        body: SafeArea(
          bottom: false,
          child: _isLoading
              ? Center(
                  child: CircularProgressIndicator(
                      color: settingsTheme.primaryColor))
              : _savedDevices.isEmpty
                  ? _buildEmptyState(settingsTheme)
                  : _buildDeviceList(settingsTheme),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _addDevice,
          backgroundColor: settingsTheme.primaryColor,
          foregroundColor: Colors.white,
          elevation: 4,
          highlightElevation: 8,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          icon: const Icon(Icons.add_rounded, weight: 800),
          label: Text(
            _translations.addNewDevice,
            style: const TextStyle(
                fontWeight: FontWeight.bold, letterSpacing: 0.5),
          ),
        ),
      ),
    );
  }

  Widget _buildBluetoothStatus(SmHealthSettingsThemeData settingsTheme) {
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
            color: settingsTheme.primarySoftColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: settingsTheme.borderColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 8,
                height: 8,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: settingsTheme.successColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _getStatusDescription(_connectionState).toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: settingsTheme.textColor,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(SmHealthSettingsThemeData settingsTheme) {
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
                  color: settingsTheme.primarySoftColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: settingsTheme.borderColor),
                ),
                child: Icon(
                  Icons.bluetooth_searching_rounded,
                  size: 80,
                  color: settingsTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                _translations.noDevicesYet,
                style: settingsTheme.resolvedTitleTextStyle.copyWith(
                  fontSize: 26,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _translations.connectOmronEquipment,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: settingsTheme.secondaryTextColor,
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: 240,
                child: ElevatedButton(
                  onPressed: _addDevice,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: settingsTheme.primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text(
                    _translations.pairNewDevice,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeviceList(SmHealthSettingsThemeData settingsTheme) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      physics: const BouncingScrollPhysics(),
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 16),
          child: Text(
            _translations.yourEquipment,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
              color: settingsTheme.secondaryTextColor,
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
            child: _buildDeviceCard(device, settingsTheme),
          );
        }),
        const SizedBox(height: 100), // Space for FAB
      ],
    );
  }

  Widget _buildDeviceCard(
      omron.ScannedDevice device, SmHealthSettingsThemeData settingsTheme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: settingsTheme.cardColor,
        borderRadius: BorderRadius.circular(settingsTheme.cardBorderRadius),
        border: Border.all(color: settingsTheme.borderColor),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.06),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(settingsTheme.cardBorderRadius),
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
                      color: settingsTheme.primarySoftColor,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(
                      _getCategoryIcon(device.deviceCategory),
                      color: settingsTheme.primaryColor,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          device.modelName ?? _translations.unknownDevice,
                          style: settingsTheme.resolvedItemTitleTextStyle,
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: settingsTheme.chipColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _translations.serialNumber(
                                device.localName ?? _translations.notAvailable),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: settingsTheme.secondaryTextColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    decoration: BoxDecoration(
                      color: settingsTheme.dangerSoftColor,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.delete_sweep_rounded,
                        color: settingsTheme.dangerColor,
                        size: 24,
                      ),
                      onPressed: () => _deleteDevice(device),
                      tooltip: _translations.removeDevice,
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
