import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sm_omron/sm_omron.dart' as omron;

import '../../sm_flutter_health_devices.dart';

/// A comprehensive, expert-designed widget that handles the lifecycle of
/// connecting to and measuring from health devices.
///
/// This widget delegates all UI rendering to the provided builders:
/// - [initBuilder]: Renders the initial state before starting (optional).
/// - [stateBuilder]: Renders the active state (Scanning, Connecting, Measuring).
/// - [successBuilder]: Renders the success state (Result Ready).
/// - [errorBuilder]: Renders the error state.
class SmHealthDeviceWidget extends StatefulWidget {
  /// The type of measurement to perform
  final MeasurementType measurementType;

  /// Callback when a measurement is successfully completed
  /// Note: This is NOT called automatically on success. You must call it
  /// manually in your [successBuilder] (e.g. via a "Save" button),
  /// UNLESS [actionConfig.autoSave] is true.
  final Function(HealthVitalResult) onResult;

  /// Optional callback for errors
  final Function(dynamic error)? onError;

  /// Optional callback for cancellation
  final VoidCallback? onCancel;

  /// Optional builder to customize the initial view before starting measurement.
  /// [onStart]: Function to call to start the scan and measurement process.
  /// [onCancel]: Function to call to cancel/exit.
  /// If not provided, measurement will auto-start based on [actionConfig.autoStartScan].
  final Widget Function(
          BuildContext context, VoidCallback onStart, VoidCallback onCancel)?
      initBuilder;

  /// Builder to customize the state view (Scanning, Connecting, Measuring).
  /// [onCancel]: Function to call to cancel the measurement.
  final Widget Function(
          BuildContext context, HealthEventData event, VoidCallback onCancel)
      stateBuilder;

  /// Builder to customize the success view (Result Ready).
  /// [onSave]: Function to call to save/finalize (triggers onResult and exit).
  /// [onReset]: Function to call to reset to initial state.
  final Widget Function(BuildContext context, HealthVitalResult result,
      VoidCallback onSave, VoidCallback onReset) successBuilder;

  /// Builder to customize the error view.
  /// [onRetry]: Function to call to retry the measurement.
  /// [onCancel]: Function to call to cancel/exit.
  final Widget Function(BuildContext context, String errorMessage,
      VoidCallback onRetry, VoidCallback onCancel) errorBuilder;

  /// Optional builder to customize the retry view.
  /// If provided, this view is displayed when retry is clicked/triggered.
  /// If null, falls back to the default measurement state view.
  final Widget Function(BuildContext context, VoidCallback onRetry,
      VoidCallback onCancel)? retryBuilder;

  /// Optional custom AppBar. If provided, overrides the default AppBar.
  final PreferredSizeWidget? appBar;

  /// Configuration for UI styling (colors, strings, animations).
  final SmHealthUiConfig uiConfig;

  /// Configuration for behavior and specialized requirements (autoSave, fitrusApiKey, userProfile).
  final SmHealthInitConfig initConfig;

  const SmHealthDeviceWidget({
    super.key,
    required this.measurementType,
    required this.onResult,
    required this.stateBuilder,
    required this.successBuilder,
    required this.errorBuilder,
    this.initBuilder,
    this.retryBuilder,
    this.onError,
    this.onCancel,
    this.appBar,
    this.uiConfig = const SmHealthUiConfig(),
    this.initConfig = const SmHealthInitConfig(),
  });

  @override
  State<SmHealthDeviceWidget> createState() => _SmHealthDeviceWidgetState();
}

class _SmHealthDeviceWidgetState extends State<SmHealthDeviceWidget> {
  final _smHealthDevices = SmHealthDevices();
  StreamSubscription<HealthEventData>? _subscription;

  // State
  bool _isInInitState = true; // Start in init state
  bool _isInitializing = false;
  bool _isScanning = false;
  bool _isConnecting = false;
  bool _isMeasuring = false;
  bool _hasStopped = false;
  bool _hasReachedSuccess = false; // Lock success state
  bool _isRetrying = false;
  String? _errorMessage;
  HealthEventData? _lastEvent;
  Future<void>? _activeStopFuture;

  // Resolved provider
  late DeviceProvider _activeProvider;

  @override
  void initState() {
    super.initState();
    // Resolve provider immediately to avoid LateInitializationError in build()
    _resolveProvider();

    // If no initBuilder provided, use autoStartScan behavior
    if (widget.initBuilder == null && widget.initConfig.autoStartScan) {
      debugPrint('SmHealthDeviceWidget: No initBuilder, auto-starting...');
      _isInInitState = false;
      _initAndStart();
    } else if (widget.initBuilder == null) {
      // No initBuilder and no autoStart, go directly to ready state
      _isInInitState = false;
    }
  }

  @override
  void didUpdateWidget(covariant SmHealthDeviceWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.measurementType != widget.measurementType) {
      _resolveProvider();
    }
  }

  void _resolveProvider() {
    _activeProvider = _smHealthDevices.settingsManager
        .getPreferredProvider(widget.measurementType);
  }

  Future<void> _initAndStart() async {
    debugPrint('SmHealthDeviceWidget: _initAndStart called');
    
    // Await any pending stop operation to prevent scanner registration conflicts
    await _stopActiveMeasurement();
    _activeStopFuture = null;

    setState(() {
      _isInInitState = false;
      _isInitializing = true;
      _errorMessage = null;
      _hasStopped = false;
      _hasReachedSuccess = false; // Reset success flag
    });

    try {
      debugPrint('SmHealthDeviceWidget: Checking permissions...');
      // 1. Check Bluetooth Permission
      final hasBluetoothPermission =
          await _smHealthDevices.permissions.checkBluetoothPermissions();
      if (!hasBluetoothPermission) {
        _setError(
            "Bluetooth permission is required. Please grant Bluetooth permission in settings.");
        return;
      }

      // 2. Check Location Permission
      final hasLocationPermission =
          await _smHealthDevices.permissions.checkLocationPermission();
      if (!hasLocationPermission) {
        _setError(
            "Location permission is required for Bluetooth scanning. Please grant Location permission in settings.");
        return;
      }

      // 3. Check Bluetooth Service (Adapter enabled)
      final isBluetoothEnabled =
          await _smHealthDevices.permissions.isBluetoothEnabled();
      if (!isBluetoothEnabled) {
        _setError(
            "Bluetooth is disabled. Please enable Bluetooth in your device settings.");
        return;
      }

      // 4. Check Location Service (GPS enabled)
      final isLocationServiceEnabled =
          await _smHealthDevices.permissions.isLocationServiceEnabled();
      if (!isLocationServiceEnabled) {
        _setError(
            "Location service is disabled. Please enable Location/GPS in your device settings.");
        return;
      }

      // 2. Resolve parameters from initConfig
      final fitrusApiKey = widget.initConfig.fitrusApiKey;
      final omronApiKey = widget.initConfig.omronApiKey;
      // 5. Initialize Plugin (if needed)
      final initSuccess = await _smHealthDevices.init(
        config: HealthDevicesConfig(
          fitrusApiKey: fitrusApiKey,
          omronApiKey: omronApiKey,
          timeout: widget.initConfig.timeout,
          measuringTimeout: widget.initConfig.measuringTimeout,
        ),
      );
      if (!initSuccess) {
        _setError(
            "Failed to initialize health device system. Please restart the app.");
        return;
      }

      // 6. All checks passed - Start Flow
      _startMeasurementFlow();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _errorMessage = e.toString();
        });
        widget.onError?.call(e);
      }
    }
  }

  void _startMeasurementFlow() {
    // Reset state
    setState(() {
      _isInitializing = false;
      _isScanning = true; // Assumed start state
      _errorMessage = null;
      _lastEvent = null; // Clear previous event on restart
      _hasStopped = false;
      _hasReachedSuccess = false; // Reset success flag
    });

    // Ensure provider is resolved
    _resolveProvider();

    debugPrint(
        'SmHealthDeviceWidget: Starting flow for ${widget.measurementType} using provider: $_activeProvider');

    // Listen to events
    _subscription?.cancel();
    _subscription = _smHealthDevices.getEvents().listen(_onEvent);

    final provider = _activeProvider;

    // Call specific start method
    try {
      if (provider == DeviceProvider.raycome) {
        _smHealthDevices.readBloodPressure(
          provider: DeviceProvider.raycome,
          timeout: widget.initConfig.timeout,
          measuringTimeout: widget.initConfig.measuringTimeout,
        );
      } else if (provider == DeviceProvider.omron) {
        _startOmronFlow();
      } else if (provider == DeviceProvider.accucheck) {
        _smHealthDevices.readGlucose(
          timeout: widget.initConfig.timeout,
          measuringTimeout: widget.initConfig.measuringTimeout,
        );
      } else if (provider == DeviceProvider.fitrus) {
        // Handle Fitrus measurement via unified method
        if (widget.measurementType == MeasurementType.bodyComposition &&
            widget.initConfig.userProfile != null &&
            widget.initConfig.fitrusApiKey != null) {
          _smHealthDevices.startBodyComposition(
            apiKey: widget.initConfig.fitrusApiKey!,
            heightCm: widget.initConfig.userProfile!.heightCm,
            weightKg: widget.initConfig.userProfile!.weightKg,
            gender: widget.initConfig.userProfile!.gender,
            birthDate: widget.initConfig.userProfile!.birthDate,
            timeout: widget.initConfig.timeout,
            measuringTimeout: widget.initConfig.measuringTimeout,
          );
        } else {
          _errorMessage =
              "Fitrus requires user profile data and API key for body composition.";
          setState(() {});
        }
      } else if (provider == DeviceProvider.lepu) {
        _dispatchMeasurementCommand();
      }
    } catch (e) {
      _setError(e.toString());
    }
  }

  Future<void> _startOmronFlow() async {
    try {
      // 1. Get Category
      final category = _mapToOmronCategory(widget.measurementType);
      if (category == null) {
        _setError("Unsupported measurement type for Omron.");
        return;
      }

      // 2. Check Saved Devices
      final allSaved = await _smHealthDevices.getSavedOmronDevices();

      // Filter logic: Check if device supports the category
      final matchingDevices = allSaved.where((device) {
        // ScannedDevice has a getter 'deviceCategory' that returns the enum
        return device.deviceCategory == category;
      }).toList();

      if (matchingDevices.isEmpty) {
        await _handleOmronPairing(category);
      } else {
        // Use the first matching device
        _dispatchOmronMeasurement(matchingDevices.first);
      }
    } catch (e) {
      _setError("Omron flow error: $e");
    }
  }

  Future<void> _handleOmronPairing(DeviceCategory category) async {
    // 1. Show Selector
    final deviceModel = await OmronDeviceSelectorDialog.show(
      context,
      title: const Text("Select Device"),
      categoryFilter: category,
    );

    if (deviceModel == null) {
      // User cancelled
      _cancelAndPop();
      return;
    }

    ScannedDevice? scannedDevice;

    try {
      // 2. Scan/Create Device
      if (deviceModel.isRecordingWave) {
        scannedDevice =
            _smHealthDevices.createOmronRecordingDevice(deviceModel);
      } else if (deviceModel.deviceIdentifier != null) {
        scannedDevice = await _smHealthDevices.scanOmronBleDevice(
          deviceIdentifier: deviceModel.deviceIdentifier!,
          timeout: widget.initConfig.timeout,
        );
      }

      if (scannedDevice != null) {
        // 3. Pair (Bond)
        // Note: verify if model requires strict pairing. Most BLE do.
        if (!deviceModel.isRecordingWave) {
          final paired =
              await _smHealthDevices.pairOmronBleDevice(device: scannedDevice);
          if (!paired) {
            _setError("Pairing failed. Please try again.");
            return;
          }
        }

        // 4. Save
        await _smHealthDevices.saveOmronDevice(scannedDevice);

        // 5. Transfer
        _dispatchOmronMeasurement(scannedDevice);
      } else {
        _setError("Device not found. Ensure it is in pairing mode.");
      }
    } catch (e) {
      _setError("Pairing error: $e");
    }
  }

  omron.PersonalInfo? _getOmronPersonalInfo() {
    final profile = widget.initConfig.userProfile;
    if (profile == null) return null;

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

    return omron.PersonalInfo(
      heightCm: profile.heightCm,
      weightKg: profile.weightKg,
      strideCm: profile.heightCm * 0.415,
      dateOfBirth: dob,
      gender: profile.gender == Gender.male
          ? omron.Gender.male
          : omron.Gender.female,
    );
  }

  void _dispatchOmronMeasurement(ScannedDevice device) {
    switch (widget.measurementType) {
      case MeasurementType.bloodPressure:
        _smHealthDevices.readBloodPressure(
          provider: DeviceProvider.omron,
          omronDevice: device,
          timeout: widget.initConfig.timeout,
        );
        break;
      case MeasurementType.weight:
      case MeasurementType.bodyComposition:
        _smHealthDevices.readWeight(
          provider: DeviceProvider.omron,
          omronDevice: device,
          personalInfo: _getOmronPersonalInfo(),
          timeout: widget.initConfig.timeout,
        );
        break;
      case MeasurementType.activity:
        _smHealthDevices.readActivity(
          device: device,
          timeout: widget.initConfig.timeout,
        );
        break;
      case MeasurementType.spo2:
        _smHealthDevices.readSpo2(
          provider: DeviceProvider.omron,
          omronDevice: device,
          timeout: widget.initConfig.timeout,
        );
        break;
      case MeasurementType.temperature:
        _smHealthDevices.readTemperature(
          provider: DeviceProvider.omron,
          timeout: widget.initConfig.timeout,
        );
        break;
      default:
        _setError("Measurement type not implemented for Omron yet.");
    }
  }

  void _cancelAndPop() {
    if (widget.onCancel != null) {
      widget.onCancel!();
    } else {
      Navigator.of(context).pop();
    }
  }

  DeviceCategory? _mapToOmronCategory(MeasurementType type) {
    switch (type) {
      case MeasurementType.bloodPressure:
        return DeviceCategory.bloodPressure;
      case MeasurementType.weight:
      case MeasurementType.bodyComposition:
        return DeviceCategory.weight;
      case MeasurementType.activity:
        return DeviceCategory.activity;
      case MeasurementType.spo2:
        return DeviceCategory.pulseOximeter;
      case MeasurementType.temperature:
        return DeviceCategory.temperature;
      case MeasurementType.wheeze:
        return DeviceCategory.wheeze;
      default:
        return null;
    }
  }

  void _dispatchMeasurementCommand() {
    switch (widget.measurementType) {
      case MeasurementType.bloodPressure:
        _smHealthDevices.readBloodPressure(
          provider: _activeProvider,
          timeout: widget.initConfig.timeout,
          measuringTimeout: widget.initConfig.measuringTimeout,
        );
        break;
      case MeasurementType.weight:
        _smHealthDevices.readWeight(
          provider: _activeProvider,
          timeout: widget.initConfig.timeout,
          measuringTimeout: widget.initConfig.measuringTimeout,
        );
        break;
      case MeasurementType.spo2:
        _smHealthDevices.readSpo2(
          provider: _activeProvider,
          timeout: widget.initConfig.timeout,
          measuringTimeout: widget.initConfig.measuringTimeout,
        );
        break;
      case MeasurementType.temperature:
        if (_activeProvider == DeviceProvider.lepu ||
            _activeProvider == DeviceProvider.omron) {
          _smHealthDevices.readTemperature(
            provider: _activeProvider,
            timeout: widget.initConfig.timeout,
            measuringTimeout: widget.initConfig.measuringTimeout,
          );
        }
        break;

      default:
        _setError(
            "Unsupported measurement type for this widget: ${widget.measurementType}");
    }
  }

  void _onEvent(HealthEventData event) {
    if (!mounted) return;

    // Filter by provider
    if (event.provider != _activeProvider) {
      return;
    }

    // If we've already reached success, ignore all further events
    // This prevents returning to stateBuilder or errorBuilder when device disconnects
    if (_hasReachedSuccess) {
      return;
    }

    debugPrint(
        'SmHealthDeviceWidget: Received event from ${event.provider} - State: ${event.connectionState}, HasError: ${event.hasError}, Msg: ${event.message}');

    // 2. Track connection status
    setState(() {
      _lastEvent = event;

      if (event.connectionState == HealthConnectionState.scanning) {
        _isScanning = true;
      } else {
        _isScanning = false;
      }
    });

    // 3. Handle Errors
    if (event.hasError || event.connectionState == HealthConnectionState.error) {
      debugPrint('SmHealthDeviceWidget: Error detected in event: ${event.message}');
      _setError(event.message);
      return;
    }

    setState(() {
      _lastEvent = event;
      final state = event.connectionState;

      _isInitializing = false;
      _isScanning = state == HealthConnectionState.scanning;
      _isConnecting = state == HealthConnectionState.connecting ||
          state == HealthConnectionState.connected;
      _isMeasuring = state == HealthConnectionState.measuring;

      // Check if we've reached success state
      final isCompleted = event.isCompleted == true ||
          event.connectionState == HealthConnectionState.completed;
      if (isCompleted && event.vitalResult != null) {
        _hasReachedSuccess = true; // Lock in success state

        // Auto-save if configured
        if (widget.initConfig.autoSave) {
          debugPrint('SmHealthDeviceWidget: Auto-save enabled, exiting...');
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _saveAndExit(event.vitalResult!);
          });
        }
      }
    });

    // Success check:
    // If completed, we just stay in this state. The builder logic in build()
    // will pick up the "completed" state and render the success view.
  }

  void _setError(String? message) {
    if (!mounted) return;
    debugPrint('SmHealthDeviceWidget: Transitioning to ERROR state: $message');
    _stopActiveMeasurement();
    setState(() {
      _errorMessage = message ?? 'An error occurred';
      _isScanning = false;
      _isConnecting = false;
      _isMeasuring = false;
      _isRetrying = false;
    });
    widget.onError?.call(_errorMessage);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _stopActiveMeasurement();
    super.dispose();
  }

  Future<void> _stopActiveMeasurement() {
    if (_hasStopped) return _activeStopFuture ?? Future.value();
    _hasStopped = true;

    _activeStopFuture = _smHealthDevices.stopMeasurement(
      provider: _activeProvider,
      measurementType: widget.measurementType,
    ).catchError((e) {
      debugPrint('SmHealthDeviceWidget: Error stopping measurement: $e');
      return false;
    });

    return _activeStopFuture!;
  }

  @override
  Widget build(BuildContext context) {
    final isCompleted = _lastEvent?.isCompleted == true ||
        _lastEvent?.connectionState == HealthConnectionState.completed ||
        _hasReachedSuccess;

    final content = AnimatedSwitcher(
      duration: widget.uiConfig.animationDuration,
      child: _buildContent(),
    );

    if (widget.appBar != null || widget.uiConfig.showAppBar) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (bool didPop, dynamic result) async {
          if (didPop) return;
          _handleBackAttempt();
        },
        child: Scaffold(
          backgroundColor: widget.uiConfig.backgroundColor ??
              Theme.of(context).scaffoldBackgroundColor,
          appBar: widget.appBar ??
              AppBar(
                title: Text(
                  widget.uiConfig.title ?? widget.measurementType.displayName,
                  style: widget.uiConfig.titleTextStyle,
                ),
                backgroundColor: Colors.transparent,
                elevation: 0,
                centerTitle: true,
                automaticallyImplyLeading: false,
                leading: (isCompleted || _hasReachedSuccess)
                    ? null
                    : IconButton(
                        icon: Icon(Icons.arrow_back,
                            color: widget.uiConfig.textColor ?? Colors.black),
                        onPressed: _handleBackAttempt,
                      ),
              ),
          body: content,
        ),
      );
    } else {
      return Container(
        color: widget.uiConfig.backgroundColor ?? Colors.transparent,
        child: content,
      );
    }
  }

  Widget _buildContent() {
    // 0. Init State (if initBuilder provided)
    if (_isInInitState && widget.initBuilder != null) {
      return widget.initBuilder!(
        context,
        _initAndStart, // On Start
        _handleBackAttempt, // On Cancel
      );
    }

    // 1. Retry State (if retryBuilder provided and user triggered retry)
    if (_isRetrying && widget.retryBuilder != null) {
      return widget.retryBuilder!(
        context,
        () {
          setState(() {
            _isRetrying = false;
          });
          _retryMeasurement();
        },
        _handleBackAttempt,
      );
    }

    // 2. Error State
    if (_errorMessage != null) {
      return widget.errorBuilder(
        context,
        _errorMessage!,
        _retryMeasurement, // On Retry
        _handleBackAttempt, // On Cancel
      );
    }

    // 2. Success State
    // Check if we have a valid result and completion
    final isCompleted = _lastEvent?.isCompleted == true ||
        _lastEvent?.connectionState == HealthConnectionState.completed;

    if (isCompleted && _lastEvent?.vitalResult != null) {
      return widget.successBuilder(
        context,
        _lastEvent!.vitalResult!,
        () => _saveAndExit(_lastEvent!.vitalResult!), // On Save
        widget.initBuilder != null
            ? _resetToInit
            : _retryMeasurement, // On Reset/Retry
      );
    }

    // 3. Active State (Scanning, Connecting, Measuring)
    // Create a synthetic event for initial state if no event yet
    final currentEvent = _lastEvent ??
        HealthEventData(
            connectionState: _isScanning
                ? HealthConnectionState.scanning
                : _isConnecting
                    ? HealthConnectionState.connecting
                    : HealthConnectionState.disconnected,
            message: _isScanning
                ? widget.uiConfig.scanningText
                : widget.uiConfig.connectingText,
            provider: _activeProvider);

    return widget.stateBuilder(
      context,
      currentEvent,
      _handleBackAttempt, // On Cancel
    );
  }

  Future<void> _handleBackAttempt() async {
    // If already complete or error, just exit
    if (_lastEvent?.isCompleted == true || _errorMessage != null) {
      _finalizeAndExit();
      return;
    }

    // If initializing, just exit
    if (_isInitializing) {
      _finalizeAndExit();
      return;
    }

    // Show confirmation dialog if scanning, connecting or measuring
    final bool needsConfirmation = _isScanning || _isMeasuring || _isConnecting;
    if (!needsConfirmation) {
      _stopActiveMeasurement();
      _finalizeAndExit();
      return;
    }

    // Show confirmation dialog
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Stop Measurement?'),
        content: const Text(
            'Are you sure you want to cancel the current measurement?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Continue')),
          TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Stop', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (shouldExit == true) {
      _subscription?.cancel();
      _stopActiveMeasurement();
      _finalizeAndExit();
    }
  }

  Future<void> _retryMeasurement() async {
    // Await any pending stop operation to prevent scanner registration conflicts
    await _stopActiveMeasurement();
    _activeStopFuture = null;

    setState(() {
      _lastEvent = null;
      _errorMessage = null;
      _hasReachedSuccess = false; // Reset success flag
      _hasStopped = false; // Reset stopped flag for retry
      _isRetrying = true;
    });
    // Restart flow
    _startMeasurementFlow();
  }

  void _resetToInit() {
    setState(() {
      _isInInitState = true;
      _lastEvent = null;
      _errorMessage = null;
      _isScanning = false;
      _isConnecting = false;
      _isMeasuring = false;
      _hasStopped = false;
      _hasReachedSuccess = false; // Reset success flag
    });
    _subscription?.cancel();
  }

  void _saveAndExit(HealthVitalResult result) {
    // 1. Send Result
    widget.onResult(result);
    // 2. Exit
    if (widget.onCancel != null) {
      widget.onCancel?.call();
    } else {
      Navigator.of(context).maybePop();
    }
  }

  void _finalizeAndExit() {
    if (widget.onCancel != null) {
      widget.onCancel?.call();
    } else {
      Navigator.of(context).pop();
    }
  }
}
