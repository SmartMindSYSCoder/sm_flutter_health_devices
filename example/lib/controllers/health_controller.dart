import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:sm_flutter_health_devices/sm_flutter_health_devices.dart';

/// Controller for managing health devices state
class HealthController extends ChangeNotifier {
  final SmHealthDevices _healthDevices = SmHealthDevices();

  final List<HealthEventData> _events = [];
  PermissionResult? _permissions;
  bool _isInitialized = false;
  bool _isLoading = false;
  String _statusMessage = 'Tap to initialize';

  HealthVitalResult? _lastResult;
  StreamSubscription? _eventSubscription;

  // Track active measurement for proper cleanup
  MeasurementType? _activeMeasurementType;
  DeviceProvider? _activeProvider;

  // Getters
  SmHealthDevices get healthDevices => _healthDevices;
  List<HealthEventData> get events => List.unmodifiable(_events);
  PermissionResult? get permissions => _permissions;
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  String get statusMessage => _statusMessage;
  HealthVitalResult? get lastResult => _lastResult;

  HealthController() {
    _setupEventListener();
  }

  void _setupEventListener() {
    _eventSubscription = _healthDevices.getEvents().listen((event) {
      _events.insert(0, event);
      if (_events.length > 50) _events.removeLast();
      _statusMessage = event.message;

      // Automatically capture completion results
      if (event.connectionState == HealthConnectionState.completed &&
          event.vitalResult != null) {
        _lastResult = event.vitalResult;
      }

      notifyListeners();
    });
  }

  /// Initialize the plugin and request permissions
  Future<void> initialize() async {
    _isLoading = true;
    _lastResult = null;
    notifyListeners();

    try {
      // Request base permissions (Bluetooth + GPS + Location)
      // Microphone and Network are requested only when needed
      _permissions = await _healthDevices.permissions.requestBasePermissions();

      // Initialize plugin
      _isInitialized = await _healthDevices.init();
      _statusMessage = _isInitialized ? 'Ready' : 'Initialization failed';
    } catch (e) {
      _statusMessage = 'Error: $e';
      _isInitialized = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Initialize Fitrus for body composition


  /// Start a measurement
  Future<HealthVitalResult?> startMeasurement(
    MeasurementType type,
    DeviceProvider provider,
  ) async {
    _events.clear(); // Clear previous session events to reset UI state
    _statusMessage = 'Starting ${type.displayName}...';
    _lastResult = null;
    _activeMeasurementType = type;
    _activeProvider = provider;
    notifyListeners();

    // Check for specific permissions
    if (type == MeasurementType.temperature &&
        provider == DeviceProvider.omron) {
      _permissions = await _healthDevices.permissions.requestPermissionsFor(
        type,
        provider: provider,
      );
    }

    HealthVitalResult? result;
    switch (type) {
      case MeasurementType.weight:
        result = await _healthDevices.readWeight(provider: provider);
        break;
      case MeasurementType.bloodPressure:
        result = await _healthDevices.readBloodPressure(provider: provider);
        break;
      case MeasurementType.temperature:
        result = await _healthDevices.readTemperature(provider: provider);
        break;
      case MeasurementType.spo2:
        result = await _healthDevices.readSpo2(provider: provider);
        break;
      default:
        break;
    }

    if (result != null && result.hasData) {
      _lastResult = result;
      notifyListeners();
    }
    return result;
  }

  /// Start body composition with automatic init (one-tap measurement)
  ///
  /// Handles permissions, init, and start measurement in a single call.
  Future<void> startBodyComposition({
    required String apiKey,
    required double heightCm,
    required double weightKg,
    required Gender gender,
    required String birthDate,
  }) async {
    _events.clear(); // Clear previous session events
    _statusMessage = 'Starting body composition...';
    _lastResult = null;
    _activeMeasurementType = MeasurementType.bodyComposition;
    _activeProvider = DeviceProvider.fitrus;
    notifyListeners();

    await _healthDevices.startBodyComposition(
      apiKey: apiKey,
      heightCm: heightCm,
      weightKg: weightKg,
      gender: gender,
      birthDate: birthDate,
    );
  }

  /// Start Omron measurement with specific device
  Future<HealthVitalResult?> startOmronMeasurement(
    MeasurementType type,
    ScannedDevice device,
  ) async {
    _events.clear();
    _statusMessage = 'Connecting to ${device.modelName}...';
    _lastResult = null;
    _activeMeasurementType = type;
    _activeProvider = DeviceProvider.omron;
    notifyListeners();

    HealthVitalResult? result;

    try {
      if (type == MeasurementType.temperature) {
        _permissions = await _healthDevices.permissions.requestPermissionsFor(
          type,
          provider: DeviceProvider.omron,
        );
        result = await _healthDevices.readTemperature(
          provider: DeviceProvider.omron,
          // Omron temp device is looked up internally by plugin
        );
      } else {
        switch (type) {
          case MeasurementType.weight:
            result = await _healthDevices.readWeight(
                provider: DeviceProvider.omron, omronDevice: device);
            break;
          case MeasurementType.bloodPressure:
            result = await _healthDevices.readBloodPressure(
                provider: DeviceProvider.omron, omronDevice: device);
            break;
          case MeasurementType.spo2:
            result = await _healthDevices.readSpo2(
                provider: DeviceProvider.omron, omronDevice: device);
            break;
          case MeasurementType.activity:
            result = await _healthDevices.readActivity(device: device);
            break;
          default:
            return null;
        }
      }
    } catch (e) {
      _statusMessage = 'Error: $e';
    }

    if (result != null && result.hasData) {
      _lastResult = result;
      notifyListeners();
    }
    return result;
  }

  /// Get saved Omron devices
  Future<List<ScannedDevice>> getSavedOmronDevices() async {
    return await _healthDevices.getSavedOmronDevices();
  }

  /// Scan and pair an Omron device
  Future<ScannedDevice?> scanAndPairOmron(DeviceModel model) async {
    _statusMessage = 'Scanning for ${model.modelName}...';
    notifyListeners();

    try {
      final deviceIdentifier = DeviceIdentifier.fromKey(model.identifier ?? '');

      final scanned = await _healthDevices.scanOmronBleDevice(
        deviceIdentifier: deviceIdentifier,
        timeout: const Duration(seconds: 30),
      );

      if (scanned != null) {
        _statusMessage = 'Pairing with ${scanned.localName}...';
        notifyListeners();

        final success =
            await _healthDevices.pairOmronBleDevice(device: scanned);
        if (success) {
          await _healthDevices.saveOmronDevice(scanned);
          _statusMessage = 'Paired and Saved';
          notifyListeners();
          return scanned;
        } else {
          _statusMessage = 'Pairing Failed';
          notifyListeners();
        }
      } else {
        _statusMessage = 'Device not found';
        notifyListeners();
      }
    } catch (e) {
      _statusMessage = 'Error: $e';
      notifyListeners();
    }
    return null;
  }

  /// Start glucose measurement
  Future<HealthVitalResult?> startGlucose() async {
    _events.clear(); // Clear previous session events
    _statusMessage = 'Scanning for AccuChek...';
    _lastResult = null;
    _activeMeasurementType = MeasurementType.glucometer;
    _activeProvider = DeviceProvider.accucheck;
    notifyListeners();

    final result = await _healthDevices.readGlucose();

    if (result != null && result.hasData) {
      _lastResult = result;
      notifyListeners();
    }
    return result;
  }

  /// Reset last result manually
  void clearLastResult() {
    _lastResult = null;
    notifyListeners();
  }

  /// Cancel current measurement and reset state
  Future<void> cancelMeasurement() async {
    // Call native stop if we have an active measurement
    if (_activeMeasurementType != null && _activeProvider != null) {
      try {
        await _healthDevices.stopMeasurement(
          provider: _activeProvider!,
          measurementType: _activeMeasurementType!,
        );
      } catch (e) {
        debugPrint('Error stopping measurement: $e');
      }
    }

    _events.clear();
    _lastResult = null;
    _statusMessage = 'Cancelled';
    _isLoading = false;
    _activeMeasurementType = null;
    _activeProvider = null;
    notifyListeners();
  }

  /// Clear all events
  void clearEvents() {
    _events.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    _healthDevices.dispose();
    super.dispose();
  }
}
