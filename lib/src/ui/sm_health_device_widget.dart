import 'dart:async';

import 'package:flutter/material.dart';

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

  /// Required provider
  final DeviceProvider provider;

  /// Callback when a measurement is successfully completed
  /// Note: This is NOT called automatically on success. You must call it
  /// manually in your [successBuilder] (e.g. via a "Save" button).
  final Function(HealthVitalResult) onResult;

  /// Optional callback for errors
  final Function(dynamic error)? onError;

  /// Optional callback for cancellation
  final VoidCallback? onCancel;

  /// Optional builder to customize the initial view before starting measurement.
  /// [onStart]: Function to call to start the scan and measurement process.
  /// [onCancel]: Function to call to cancel/exit.
  /// If not provided, measurement will auto-start based on [config.autoStartScan].
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

  /// Optional custom AppBar. If provided, overrides the default AppBar.
  final PreferredSizeWidget? appBar;

  /// Configuration for behavior (autoStartScan, animationDuration).
  /// Note: Styling properties in [SmDeviceConfig] are ignored as UI is fully custom.
  final SmDeviceConfig config;

  /// Optional user profile for specialized measurements (e.g. Fitrus body composition)
  final SmUserProfile? userProfile;

  /// Optional API Key for Fitrus provider
  final String? fitrusApiKey;

  const SmHealthDeviceWidget({
    Key? key,
    required this.measurementType,
    required this.provider,
    required this.onResult,
    required this.stateBuilder,
    required this.successBuilder,
    required this.errorBuilder,
    this.initBuilder,
    this.onError,
    this.onCancel,
    this.appBar,
    this.config = const SmDeviceConfig(),
    this.userProfile,
    this.fitrusApiKey,
  }) : super(key: key);

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
  String? _errorMessage;
  HealthEventData? _lastEvent;

  @override
  void initState() {
    super.initState();
    // If no initBuilder provided, use autoStartScan behavior
    if (widget.initBuilder == null && widget.config.autoStartScan) {
      _isInInitState = false;
      _initAndStart();
    } else if (widget.initBuilder == null) {
      // No initBuilder and no autoStart, go directly to ready state
      _isInInitState = false;
    }
  }

  Future<void> _initAndStart() async {
    setState(() {
      _isInInitState = false;
      _isInitializing = true;
      _errorMessage = null;
      _hasStopped = false;
      _hasReachedSuccess = false; // Reset success flag
    });

    try {
      // 1. Initialize Plugin (if needed)
      await _smHealthDevices.init();

      // 2. Start Flow
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

    // Listen to events
    _subscription?.cancel();
    _subscription = _smHealthDevices.getEvents().listen(_onEvent);

    final provider = widget.provider;

    // Call specific start method
    try {
      if (provider == DeviceProvider.raycome) {
        _smHealthDevices.readBloodPressure(provider: DeviceProvider.raycome);
      } else if (provider == DeviceProvider.omron) {
        _startOmronFlow();
      } else if (provider == DeviceProvider.accucheck) {
        _smHealthDevices.readGlucose();
      } else if (provider == DeviceProvider.fitrus) {
        // Handle Fitrus measurement via unified method
        if (widget.measurementType == MeasurementType.bodyComposition &&
            widget.userProfile != null &&
            widget.fitrusApiKey != null) {
          _smHealthDevices.startBodyComposition(
            apiKey: widget.fitrusApiKey!,
            heightCm: widget.userProfile!.heightCm,
            weightKg: widget.userProfile!.weightKg,
            gender: widget.userProfile!.gender,
            birthDate: widget.userProfile!.birthDate,
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
          timeout: const Duration(seconds: 30),
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

  void _dispatchOmronMeasurement(ScannedDevice device) {
    switch (widget.measurementType) {
      case MeasurementType.bloodPressure:
        _smHealthDevices.readBloodPressure(
            provider: DeviceProvider.omron, omronDevice: device);
        break;
      case MeasurementType.weight:
        _smHealthDevices.readWeight(
            provider: DeviceProvider.omron, omronDevice: device);
        break;
      case MeasurementType.activity:
        _smHealthDevices.readActivity(device: device);
        break;
      case MeasurementType.spo2:
        _smHealthDevices.readSpo2(
            provider: DeviceProvider.omron, omronDevice: device);
        break;
      case MeasurementType.temperature:
        _smHealthDevices.readTemperature(provider: DeviceProvider.omron);
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
        _smHealthDevices.readBloodPressure(provider: widget.provider);
        break;
      case MeasurementType.weight:
        // if (widget.provider == DeviceProvider.lepu) {
        _smHealthDevices.readWeight(provider: widget.provider);
        // }
        break;
      case MeasurementType.spo2:
        // if (widget.provider == DeviceProvider.lepu) {
        _smHealthDevices.readSpo2(provider: widget.provider);
        // }
        break;
      case MeasurementType.temperature:
        if (widget.provider == DeviceProvider.lepu) {
          _smHealthDevices.readTemperature(provider: widget.provider);
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
    if (event.provider != widget.provider) {
      return;
    }

    // If we've already reached success, ignore all further events
    // This prevents returning to stateBuilder when device disconnects
    if (_hasReachedSuccess) {
      return;
    }

    setState(() {
      _lastEvent = event;
      final state = event.connectionState;

      _isScanning = state == HealthConnectionState.scanning;
      _isConnecting = state == HealthConnectionState.connecting ||
          state == HealthConnectionState.connected;
      _isMeasuring = state == HealthConnectionState.measuring;

      // Check if we've reached success state
      final isCompleted = event.isCompleted == true ||
          event.connectionState == HealthConnectionState.completed;
      if (isCompleted && event.vitalResult != null) {
        _hasReachedSuccess = true; // Lock in success state
      }
    });

    if (event.hasError) {
      _setError(event.message);
      return;
    }

    // Success check:
    // If completed, we just stay in this state. The builder logic in build()
    // will pick up the "completed" state and render the success view.
  }

  void _setError(String msg) {
    if (!mounted) return;
    setState(() {
      _errorMessage = msg;
      _isScanning = false;
      _isConnecting = false;
      _isMeasuring = false;
      _hasReachedSuccess = false; // Reset success flag on error
    });
    widget.onError?.call(msg);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _stopActiveMeasurement();
    super.dispose();
  }

  void _stopActiveMeasurement() {
    if (_hasStopped) return;
    _hasStopped = true;

    try {
      _smHealthDevices.stopMeasurement(
        provider: widget.provider,
        measurementType: widget.measurementType,
      );
    } catch (e) {
      debugPrint('SmHealthDeviceWidget: Error stopping measurement: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Wrap with PopScope to intercept back button
    final content = PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) return;
        _handleBackAttempt();
      },
      child: AnimatedSwitcher(
        duration: widget.config.animationDuration,
        child: _buildContent(),
      ),
    );

    if (widget.appBar != null || widget.config.showAppBar) {
      return Scaffold(
        backgroundColor: widget.config.backgroundColor ??
            Theme.of(context).scaffoldBackgroundColor,
        appBar: widget.appBar ??
            AppBar(
              title: Text(
                widget.config.title ?? widget.measurementType.displayName,
                style: widget.config.titleTextStyle,
              ),
              backgroundColor: Colors.transparent,
              elevation: 0,
              centerTitle: true,
              leading: IconButton(
                icon: Icon(Icons.arrow_back,
                    color: widget.config.textColor ?? Colors.black),
                onPressed: _handleBackAttempt,
              ),
            ),
        body: content,
      );
    } else {
      return SizedBox(
        child: ColoredBox(
            color: widget.config.backgroundColor ??
                Theme.of(context).scaffoldBackgroundColor,
            child: content),
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

    // 1. Error State
    if (_errorMessage != null) {
      return widget.errorBuilder(
        context,
        _errorMessage!,
        _initAndStart, // On Retry
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
                ? widget.config.scanningText
                : widget.config.connectingText,
            provider: widget.provider);

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

  void _retryMeasurement() {
    setState(() {
      _lastEvent = null;
      _errorMessage = null;
      _hasReachedSuccess = false; // Reset success flag
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
