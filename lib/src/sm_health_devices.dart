import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';
import 'package:sm_fitrus/sm_fitrus.dart' as fitrus;
import 'package:sm_fitrus/fitrus_model.dart' as fitrus;
import 'package:sm_lepu/sm_lepu.dart' as lepu;
import 'package:sm_omron/sm_omron.dart' as omron;
import 'package:sm_raycome/sm_raycome.dart' as raycome;

import 'adapters/accu_check_adapter.dart';
import 'adapters/fitrus_adapter.dart';
import 'adapters/lepu_adapter.dart';
import 'adapters/omron_adapter.dart';
import 'adapters/raycome_adapter.dart';
import 'services/accu_check_service.dart';
import 'models/enums.dart';
import 'models/health_event_data.dart';
import 'models/health_vital_result.dart';
import 'permission_manager.dart';

export 'package:sm_fitrus/sm_fitrus.dart' show FitrusGender;
export 'package:sm_fitrus/fitrus_model.dart' show FitrusConnectionState;

export 'models/enums.dart';
export 'models/health_event_data.dart';
export 'models/health_vital_result.dart';
export 'permission_manager.dart';

/// Configuration for SmHealthDevices plugin
class HealthDevicesConfig {
  /// API key for Fitrus (required for body composition)
  final String? fitrusApiKey;

  const HealthDevicesConfig({
    this.fitrusApiKey,
  });
}

/// Unified Flutter plugin for health devices
///
/// Wraps sm_fitrus, sm_lepu, and sm_omron plugins into a single API
/// with permission management and unified event streaming.
class SmHealthDevices {
  // Singleton pattern
  static final SmHealthDevices _instance = SmHealthDevices._internal();
  factory SmHealthDevices() => _instance;
  SmHealthDevices._internal();

  // Plugin instances - made lazy to avoid constructor side-effects on startup
  late final fitrus.SmFitrus _fitrus = _initFitrus();
  late final lepu.SmLepu _lepu = _initLepu();
  late final omron.SMOmron _omron = _initOmron();
  late final raycome.SmRaycome _raycome = _initRaycome();

  fitrus.SmFitrus _initFitrus() {
    debugPrint('SmHealthDevices: Instantiating Fitrus plugin...');
    debugPrint(
        'SmHealthDevices: Fitrus instantiation stack trace:\n${StackTrace.current}');
    return fitrus.SmFitrus();
  }

  lepu.SmLepu _initLepu() {
    debugPrint('SmHealthDevices: Instantiating Lepu plugin...');
    debugPrint(
        'SmHealthDevices: Lepu instantiation stack trace:\n${StackTrace.current}');
    return lepu.SmLepu();
  }

  omron.SMOmron _initOmron() {
    debugPrint('SmHealthDevices: Instantiating Omron plugin...');
    debugPrint(
        'SmHealthDevices: Omron instantiation stack trace:\n${StackTrace.current}');
    return omron.SMOmron();
  }

  raycome.SmRaycome _initRaycome() {
    debugPrint('SmHealthDevices: Instantiating Raycome plugin...');
    return raycome.SmRaycome();
  }

  late final AccuCheckService _accuCheck = _initAccuCheck();

  AccuCheckService _initAccuCheck() {
    debugPrint('SmHealthDevices: Instantiating AccuCheck service...');
    return AccuCheckService();
  }

  /// Permission manager instance
  final HealthPermissionManager permissions = HealthPermissionManager();

  // Stream controllers
  StreamController<HealthEventData>? _eventController;
  StreamSubscription? _lepuSubscription;
  StreamSubscription? _fitrusSubscription;
  StreamSubscription? _omronSubscription;
  StreamSubscription? _raycomeSubscription;

  // Configuration
  bool _isInitialized = false;
  bool _isFitrusInitialized = false;
  bool _isFitrusMeasuring = false; // Mutex to prevent concurrent measurements
  String? _fitrusApiKey;
  HealthConnectionState _lastFitrusState = HealthConnectionState.disconnected;

  /// Check if the plugin is initialized
  bool get isInitialized => _isInitialized;

  // ============================================================
  // INITIALIZATION
  // ============================================================

  Future<bool> init({HealthDevicesConfig? config}) async {
    debugPrint('SmHealthDevices: init called with config: $config');

    try {
      // Ensure event controller is ready
      _eventController ??= StreamController<HealthEventData>.broadcast();

      // Initialize Omron storage (critical for saving/pairing)
      await _omron.initialize();

      _isInitialized = true;
      debugPrint('SmHealthDevices: Core system initialized successfully');
      return true;
    } catch (e) {
      debugPrint('SmHealthDevices: Initialization failed - $e');
      return false;
    }
  }

  /// Stop all active subscriptions except for the specified provider
  void _stopSubscriptions({DeviceProvider? except}) {
    if (except != DeviceProvider.lepu) {
      _lepuSubscription?.cancel();
      _lepuSubscription = null;
    }
    if (except != DeviceProvider.fitrus) {
      _fitrusSubscription?.cancel();
      _fitrusSubscription = null;
    }
    if (except != DeviceProvider.omron) {
      _omronSubscription?.cancel();
      _omronSubscription = null;
    }
    if (except != DeviceProvider.raycome) {
      _raycomeSubscription?.cancel();
      _raycomeSubscription = null;
    }
  }

  void _ensureLepuSubscription() {
    if (_lepuSubscription != null) return;

    _stopSubscriptions(except: DeviceProvider.lepu);
    _eventController ??= StreamController<HealthEventData>.broadcast();

    debugPrint('SmHealthDevices: Starting Lepu subscription...');
    _lepuSubscription = _lepu.getEvents().listen(
      (lepuEvent) {
        debugPrint('SmHealthDevices: Lepu Event - ${lepuEvent.deviceType}');
        final healthEvent = LepuAdapter.toHealthEvent(lepuEvent);
        _eventController?.add(healthEvent);
      },
      onError: (error) {
        _eventController?.add(HealthEventData.error(
          provider: DeviceProvider.lepu,
          message: error.toString(),
        ));
      },
    );
  }

  void _ensureFitrusSubscription() {
    if (_fitrusSubscription != null) return;

    _stopSubscriptions(except: DeviceProvider.fitrus);
    _eventController ??= StreamController<HealthEventData>.broadcast();

    debugPrint('SmHealthDevices: Starting Fitrus subscription...');
    _fitrusSubscription = _fitrus.getEvents().listen(
      (fitrusModel) {
        debugPrint(
            'SmHealthDevices: Fitrus Event - ${fitrusModel.connectionState}');
        final healthEvent = FitrusAdapter.toHealthEvent(fitrusModel);
        _lastFitrusState = healthEvent.connectionState;

        // Clear measuring flag when measurement completes or errors
        if (healthEvent.connectionState == HealthConnectionState.completed ||
            healthEvent.connectionState == HealthConnectionState.error) {
          _isFitrusMeasuring = false;
          debugPrint(
              'SmHealthDevices: Fitrus measurement finished, clearing mutex flag');
        }

        _eventController?.add(healthEvent);
      },
      onError: (error) {
        _isFitrusMeasuring = false;
        debugPrint('SmHealthDevices: Fitrus error, clearing mutex flag');
        _eventController?.add(HealthEventData.error(
          provider: DeviceProvider.fitrus,
          message: error.toString(),
        ));
      },
    );
  }

  void _ensureOmronSubscription() {
    if (_omronSubscription != null) return;

    _stopSubscriptions(except: DeviceProvider.omron);
    _eventController ??= StreamController<HealthEventData>.broadcast();

    debugPrint('SmHealthDevices: Starting Omron subscription...');
    _omronSubscription = _omron.connectionStateStream.listen(
      (state) {
        debugPrint('SmHealthDevices: Omron Connection State - $state');
        final healthEvent = OmronAdapter.toHealthEvent(state);
        _eventController?.add(healthEvent);
      },
      onError: (error) {
        debugPrint('SmHealthDevices: Omron Error - $error');
        _eventController?.add(HealthEventData.error(
          provider: DeviceProvider.omron,
          message: error.toString(),
        ));
      },
    );
  }

  void _ensureRaycomeSubscription() {
    if (_raycomeSubscription != null) return;

    _stopSubscriptions(except: DeviceProvider.raycome);
    _eventController ??= StreamController<HealthEventData>.broadcast();

    debugPrint('SmHealthDevices: Starting Raycome subscription...');
    _raycomeSubscription = _raycome.events.listen(
      (state) {
        debugPrint('SmHealthDevices: Raycome State - ${state.displayStatus}');
        final healthEvent = RaycomeAdapter.toHealthEvent(state);
        _eventController?.add(healthEvent);
      },
      onError: (error) {
        debugPrint('SmHealthDevices: Raycome Error - $error');
        _eventController?.add(HealthEventData.error(
          provider: DeviceProvider.raycome,
          message: error.toString(),
        ));
      },
    );
  }

  /// Initialize Fitrus for scanning
  /// Required before starting body composition measurements
  /// Call this first (Connect button), then call startBodyComposition (Start Measurement button)

  // ============================================================
  // WEIGHT MEASUREMENT
  // ============================================================

  /// Read weight measurement
  ///
  /// [provider] - Device provider (omron or lepu)
  /// [omronDevice] - Required for Omron: the saved ScannedDevice
  Future<HealthVitalResult?> readWeight({
    required DeviceProvider provider,
    omron.ScannedDevice? omronDevice,
  }) async {
    if (!_validateProvider(provider, MeasurementType.weight)) {
      return HealthVitalResult.error(
        provider: provider,
        measurementType: MeasurementType.weight,
        message: 'Provider ${provider.displayName} does not support weight',
      );
    }

    switch (provider) {
      case DeviceProvider.lepu:
        return await _readLepuWeight();
      case DeviceProvider.omron:
        return await _readOmronWeight(omronDevice);
      default:
        return null;
    }
  }

  Future<HealthVitalResult?> _readLepuWeight() async {
    try {
      _ensureLepuSubscription();
      // Inject immediate scanning status
      _eventController?.add(HealthEventData(
        provider: DeviceProvider.lepu,
        measurementType: MeasurementType.weight,
        connectionState: HealthConnectionState.scanning,
        message: 'Scanning for weight scale...',
      ));
      await _lepu.initWeight();
      // Weight data comes through the event stream
      return null; // Data will be received via getEvents()
    } catch (e) {
      return HealthVitalResult.error(
        provider: DeviceProvider.lepu,
        measurementType: MeasurementType.weight,
        message: e.toString(),
      );
    }
  }

  Future<HealthVitalResult?> _readOmronWeight(
      omron.ScannedDevice? device) async {
    if (device == null) {
      return HealthVitalResult.error(
        provider: DeviceProvider.omron,
        measurementType: MeasurementType.weight,
        message: 'Omron device not provided',
      );
    }

    try {
      _ensureOmronSubscription();
      // Inject immediate connecting status
      _eventController?.add(HealthEventData(
        provider: DeviceProvider.omron,
        measurementType: MeasurementType.weight,
        connectionState: HealthConnectionState.connecting,
        message: 'Connecting to Omron scale...',
      ));
      final results = await _omron.transferFromBleDevice(device: device);
      if (results.isNotEmpty) {
        final result = OmronAdapter.toHealthVitalResult(results.last);

        // Emit completion event so UI updates
        _eventController?.add(HealthEventData.completed(
          provider: DeviceProvider.omron,
          measurementType: MeasurementType.weight,
          vitalResult: result,
          message: 'Measurement completed',
        ));

        return result;
      }
      return null;
    } catch (e) {
      return HealthVitalResult.error(
        provider: DeviceProvider.omron,
        measurementType: MeasurementType.weight,
        message: e.toString(),
      );
    }
  }

  // ============================================================
  // BLOOD PRESSURE MEASUREMENT
  // ============================================================

  /// Read blood pressure measurement
  ///
  /// [provider] - Device provider (omron, lepu, or raycome)
  /// [omronDevice] - Required for Omron: the saved ScannedDevice
  Future<HealthVitalResult?> readBloodPressure({
    required DeviceProvider provider,
    omron.ScannedDevice? omronDevice,
  }) async {
    if (!_validateProvider(provider, MeasurementType.bloodPressure)) {
      return HealthVitalResult.error(
        provider: provider,
        measurementType: MeasurementType.bloodPressure,
        message:
            'Provider ${provider.displayName} does not support blood pressure',
      );
    }

    switch (provider) {
      case DeviceProvider.lepu:
        return await _readLepuBloodPressure();
      case DeviceProvider.omron:
        return await _readOmronBloodPressure(omronDevice);
      case DeviceProvider.raycome:
        return await _readRaycomeBloodPressure();
      default:
        return null;
    }
  }

  Future<HealthVitalResult?> _readLepuBloodPressure() async {
    try {
      _ensureLepuSubscription();
      // Inject immediate scanning status
      _eventController?.add(HealthEventData(
        provider: DeviceProvider.lepu,
        measurementType: MeasurementType.bloodPressure,
        connectionState: HealthConnectionState.scanning,
        message: 'Scanning for BP monitor...',
      ));
      await _lepu.initBP();
      await _lepu.startBP();
      // BP data comes through the event stream
      return null;
    } catch (e) {
      return HealthVitalResult.error(
        provider: DeviceProvider.lepu,
        measurementType: MeasurementType.bloodPressure,
        message: e.toString(),
      );
    }
  }

  Future<HealthVitalResult?> _readOmronBloodPressure(
      omron.ScannedDevice? device) async {
    if (device == null) {
      return HealthVitalResult.error(
        provider: DeviceProvider.omron,
        measurementType: MeasurementType.bloodPressure,
        message: 'Omron device not provided',
      );
    }

    try {
      _ensureOmronSubscription();
      // Inject immediate connecting status
      _eventController?.add(HealthEventData(
        provider: DeviceProvider.omron,
        measurementType: MeasurementType.bloodPressure,
        connectionState: HealthConnectionState.connecting,
        message: 'Connecting to Omron BP monitor...',
      ));
      final results = await _omron.transferFromBleDevice(device: device);
      if (results.isNotEmpty) {
        final result = OmronAdapter.toHealthVitalResult(results.last);

        // Emit completion event
        _eventController?.add(HealthEventData.completed(
          provider: DeviceProvider.omron,
          measurementType: MeasurementType.bloodPressure,
          vitalResult: result,
          message: 'Measurement completed',
        ));

        return result;
      }
      return null;
    } catch (e) {
      return HealthVitalResult.error(
        provider: DeviceProvider.omron,
        measurementType: MeasurementType.bloodPressure,
        message: e.toString(),
      );
    }
  }

  Future<HealthVitalResult?> _readRaycomeBloodPressure() async {
    try {
      _ensureRaycomeSubscription();

      // Initialize if needed
      await _raycome.init();

      // Start measurement (this handles scanning and connecting)
      await _raycome.start();

      // Data comes through the event stream
      return null;
    } catch (e) {
      return HealthVitalResult.error(
        provider: DeviceProvider.raycome,
        measurementType: MeasurementType.bloodPressure,
        message: e.toString(),
      );
    }
  }

  /// Stop a measurement in progress (Lepu, Fitrus, or Raycome)
  Future<bool> stopMeasurement({
    required DeviceProvider provider,
    required MeasurementType measurementType,
  }) async {
    try {
      // 2. Cancel provider-specific stream subscription
      if (provider == DeviceProvider.lepu) {
        await _lepuSubscription?.cancel();
        _lepuSubscription = null;
      } else if (provider == DeviceProvider.fitrus) {
        await _fitrusSubscription?.cancel();
        _fitrusSubscription = null;
      } else if (provider == DeviceProvider.omron) {
        await _omronSubscription?.cancel();
        _omronSubscription = null;
      } else if (provider == DeviceProvider.raycome) {
        await _raycomeSubscription?.cancel();
        _raycomeSubscription = null;
      }

      // 2. Call native stop/dispose
      if (provider == DeviceProvider.raycome) {
        if (measurementType == MeasurementType.bloodPressure) {
          final result = await _raycome.stop();
          return result ?? false;
        }
      }

      if (provider == DeviceProvider.lepu) {
        if (measurementType == MeasurementType.bloodPressure) {
          return await _lepu.stopBP();
        } else if (measurementType == MeasurementType.weight) {
          return await _lepu.stopWeightScan();
        } else {
          // For SpO2 and Temperature, Lepu uses dispose to clear connections/scanning
          await _lepu.dispose();
          return true;
        }
      }

      if (provider == DeviceProvider.fitrus) {
        if (measurementType == MeasurementType.bodyComposition) {
          // Reset internal state for next measurement
          _lastFitrusState = HealthConnectionState.disconnected;

          // CRITICAL: Clear the measuring flag to allow future measurements
          _isFitrusMeasuring = false;

          if (_isFitrusInitialized) {
            // Give an additional buffer before final dispose
            await Future.delayed(const Duration(milliseconds: 300));
            await _fitrus.cancelMeasurement();
            _isFitrusInitialized = false;
          }
          return true;
        }
      }

      return true;
    } catch (e) {
      debugPrint('SmHealthDevices: stopMeasurement failed - $e');
      return false;
    }
  }

  // ============================================================
  // TEMPERATURE MEASUREMENT
  // ============================================================

  /// Read temperature measurement
  ///
  /// [provider] - Device provider (omron or lepu)
  Future<HealthVitalResult?> readTemperature({
    required DeviceProvider provider,
  }) async {
    if (!_validateProvider(provider, MeasurementType.temperature)) {
      return HealthVitalResult.error(
        provider: provider,
        measurementType: MeasurementType.temperature,
        message:
            'Provider ${provider.displayName} does not support temperature',
      );
    }

    switch (provider) {
      case DeviceProvider.lepu:
        return await _readLepuTemperature();
      case DeviceProvider.omron:
        return await _readOmronTemperature();
      default:
        return null;
    }
  }

  Future<HealthVitalResult?> _readLepuTemperature() async {
    try {
      _ensureLepuSubscription();
      // Inject immediate scanning status
      _eventController?.add(HealthEventData(
        provider: DeviceProvider.lepu,
        measurementType: MeasurementType.temperature,
        connectionState: HealthConnectionState.scanning,
        message: 'Scanning for thermometer...',
      ));
      await _lepu.readTemp();
      // Temperature data comes through the event stream
      return null;
    } catch (e) {
      return HealthVitalResult.error(
        provider: DeviceProvider.lepu,
        measurementType: MeasurementType.temperature,
        message: e.toString(),
      );
    }
  }

  Future<HealthVitalResult?> _readOmronTemperature() async {
    try {
      _ensureOmronSubscription();
      // Inject immediate recording status
      _eventController?.add(HealthEventData(
        provider: DeviceProvider.omron,
        measurementType: MeasurementType.temperature,
        connectionState: HealthConnectionState.recording,
        message: 'Listening for thermometer audio...',
      ));
      final result = await _omron.recordTemperature();
      if (result != null) {
        final healthResult = OmronAdapter.toHealthVitalResult(result);

        // Emit completion event
        _eventController?.add(HealthEventData.completed(
          provider: DeviceProvider.omron,
          measurementType: MeasurementType.temperature,
          vitalResult: healthResult,
          message: 'Measurement completed',
        ));

        return healthResult;
      }
      return null;
    } catch (e) {
      return HealthVitalResult.error(
        provider: DeviceProvider.omron,
        measurementType: MeasurementType.temperature,
        message: e.toString(),
      );
    }
  }

  // ============================================================
  // SPO2 MEASUREMENT
  // ============================================================

  /// Read SpO2 (blood oxygen) measurement
  ///
  /// [provider] - Device provider (omron or lepu)
  /// [omronDevice] - Required for Omron: the saved ScannedDevice
  Future<HealthVitalResult?> readSpo2({
    required DeviceProvider provider,
    omron.ScannedDevice? omronDevice,
  }) async {
    if (!_validateProvider(provider, MeasurementType.spo2)) {
      return HealthVitalResult.error(
        provider: provider,
        measurementType: MeasurementType.spo2,
        message: 'Provider ${provider.displayName} does not support SpO2',
      );
    }

    switch (provider) {
      case DeviceProvider.lepu:
        return await _readLepuSpo2();
      case DeviceProvider.omron:
        return await _readOmronSpo2(omronDevice);
      default:
        return null;
    }
  }

  Future<HealthVitalResult?> _readLepuSpo2() async {
    try {
      _ensureLepuSubscription();
      // Inject immediate scanning status
      _eventController?.add(HealthEventData(
        provider: DeviceProvider.lepu,
        measurementType: MeasurementType.spo2,
        connectionState: HealthConnectionState.scanning,
        message: 'Scanning for Oximeter...',
      ));
      await _lepu.readSpo2();
      // SpO2 data comes through the event stream
      return null;
    } catch (e) {
      return HealthVitalResult.error(
        provider: DeviceProvider.lepu,
        measurementType: MeasurementType.spo2,
        message: e.toString(),
      );
    }
  }

  Future<HealthVitalResult?> _readOmronSpo2(omron.ScannedDevice? device) async {
    if (device == null) {
      return HealthVitalResult.error(
        provider: DeviceProvider.omron,
        measurementType: MeasurementType.spo2,
        message: 'Omron device not provided',
      );
    }

    try {
      _ensureOmronSubscription();
      // Inject immediate connecting status
      _eventController?.add(HealthEventData(
        provider: DeviceProvider.omron,
        measurementType: MeasurementType.spo2,
        connectionState: HealthConnectionState.connecting,
        message: 'Connecting to Omron Oximeter...',
      ));
      final results = await _omron.transferFromBleDevice(device: device);
      if (results.isNotEmpty) {
        final result = OmronAdapter.toHealthVitalResult(results.last);

        // Emit completion event
        _eventController?.add(HealthEventData.completed(
          provider: DeviceProvider.omron,
          measurementType: MeasurementType.spo2,
          vitalResult: result,
          message: 'Measurement completed',
        ));

        return result;
      }
      return null;
    } catch (e) {
      return HealthVitalResult.error(
        provider: DeviceProvider.omron,
        measurementType: MeasurementType.spo2,
        message: e.toString(),
      );
    }
  }

  // ============================================================
  // BODY COMPOSITION (FITRUS)
  // ============================================================

  /// Read body composition measurement (Fitrus only)
  ///
  /// Requires calling [initFitrus] first.
  Future<HealthVitalResult?> readBodyComposition({
    required String apiKey,
    required double heightCm,
    required double weightKg,
    required Gender gender,
    required String birthDate, // Format: yyyyMMdd
  }) async {
    if (!_isFitrusInitialized) {
      debugPrint(
          'SmHealthDevices: Error - Fitrus not initialized. Use ${_fitrusApiKey ?? "API Key"} to init first.');
      return HealthVitalResult.error(
        provider: DeviceProvider.fitrus,
        measurementType: MeasurementType.bodyComposition,
        message: 'Fitrus not initialized',
      );
    }

    try {
      debugPrint('SmHealthDevices: Starting Fitrus measurement...');
      // Inject immediate connecting status
      _eventController?.add(HealthEventData(
        provider: DeviceProvider.fitrus,
        measurementType: MeasurementType.bodyComposition,
        connectionState: HealthConnectionState.connecting,
        message: 'Connecting to Fitrus...',
      ));
      debugPrint(
          'SmHealthDevices: Fitrus measurement parameters: height: $heightCm cm, weight: $weightKg kg, gender: $gender, birthDate: $birthDate');

      debugPrint('SmHealthDevices: Calling Fitrus startBFP...');
      await _fitrus.measureBFP(
        apiKey: apiKey,
        heightCm: heightCm,
        weightKg: weightKg,
        gender: gender == Gender.male
            ? fitrus.FitrusGender.male
            : fitrus.FitrusGender.female,
        birth: birthDate,
      );
      debugPrint('SmHealthDevices: Fitrus startBFP called.');

      // Data comes through the event stream
      return null;
    } catch (e) {
      debugPrint('SmHealthDevices: readBodyComposition exception: $e');
      return HealthVitalResult.error(
        provider: DeviceProvider.fitrus,
        measurementType: MeasurementType.bodyComposition,
        message: e.toString(),
      );
    }
  }

  /// Start body composition measurement
  ///
  /// IMPORTANT: You must call [initFitrus] first and wait for connection before calling this method.
  /// This follows the two-step pattern:
  /// 1. Call initFitrus() and wait for device to connect (show "Connect" button in UI)
  /// 2. Call startBodyComposition() to begin measurement (show "Start Measurement" button in UI)
  ///
  /// Events are streamed through [getEvents()].
  Future<void> startBodyComposition({
    required String apiKey,
    required double heightCm,
    required double weightKg,
    required Gender gender,
    required String birthDate, // Format: yyyyMMdd
  }) async {
    _isFitrusMeasuring = true;

    try {
      // Ensure we are listening to events!
      _ensureFitrusSubscription();

      // Optional short delay for extra stability
      debugPrint('SmHealthDevices: Waiting 500ms for service stability...');
      await Future.delayed(const Duration(milliseconds: 500));

      // Start measurement
      debugPrint('SmHealthDevices: Starting BFP measurement...');
      // Inject immediate measuring status
      _eventController?.add(HealthEventData(
        provider: DeviceProvider.fitrus,
        measurementType: MeasurementType.bodyComposition,
        connectionState: HealthConnectionState.measuring,
        message: 'Starting Fitrus measurement...',
      ));

      try {
        await _fitrus.measureBFP(
          apiKey: apiKey,
          heightCm: heightCm,
          weightKg: weightKg,
          gender: gender == Gender.male
              ? fitrus.FitrusGender.male
              : fitrus.FitrusGender.female,
          birth: birthDate,
        );
        debugPrint('SmHealthDevices: Fitrus startBFP called successfully.');
      } catch (e) {
        debugPrint('SmHealthDevices: Fitrus startBFP failed - $e');
        _eventController?.add(HealthEventData.error(
          provider: DeviceProvider.fitrus,
          message: 'Failed to start Fitrus measurement: $e',
        ));
        _isFitrusMeasuring = false; // Only clear on error starting
      }
    } catch (e) {
      _isFitrusMeasuring = false;
      rethrow;
    }
  }

  // ============================================================
  // GLUCOMETER (ACCUCHECK)
  // ============================================================

  /// Read blood glucose measurement (AccuChek only)
  ///
  /// Scans for AccuChek device, connects, and reads the last glucose record.
  /// Returns null if no device found or no records available.
  Future<HealthVitalResult?> readGlucose({
    Duration scanTimeout = const Duration(seconds: 15),
    Duration connectTimeout = const Duration(seconds: 20),
    Duration readTimeout = const Duration(seconds: 15),
  }) async {
    // Listener for detailed logs to push to the unified event stream for UI status
    final logSub = _accuCheck.logs.listen((logMsg) {
      final lowerMsg = logMsg.toLowerCase();
      HealthConnectionState state = HealthConnectionState.disconnected;

      // Simple mapping of log messages to UI status states
      if (lowerMsg.contains('scanning')) {
        state = HealthConnectionState.scanning;
      } else if (lowerMsg.contains('connecting')) {
        state = HealthConnectionState.connecting;
      } else if (lowerMsg.contains('connected')) {
        state = HealthConnectionState.connected;
      } else if (lowerMsg.contains('finished') ||
          lowerMsg.contains('received')) {
        // Keep as connected or dataAvailable
        state = HealthConnectionState.connected;
      } else {
        // Ignore other verbose logs to prevent spamming the UI stream excessively
        // or default to 'connecting' if it's an intermediate step
        return;
      }

      _eventController?.add(HealthEventData(
        provider: DeviceProvider.accucheck,
        measurementType: MeasurementType.glucometer,
        connectionState: state,
        message: logMsg, // Pass the actual log message for UI details
      ));
    });

    try {
      // Emit initial scanning event immediately
      _eventController?.add(HealthEventData(
        provider: DeviceProvider.accucheck,
        measurementType: MeasurementType.glucometer,
        connectionState: HealthConnectionState.scanning,
        message: 'Scanning for Accu-Chek...',
      ));

      final glucoseLevel = await _accuCheck.readLastRecord(
        scanTimeout: scanTimeout,
        connectTimeout: connectTimeout,
        readTimeout: readTimeout,
      );

      if (glucoseLevel == null) {
        const errorMsg =
            'Could not find or connect to device. Ensure your Accu-Chek is in pairing mode (holding button until BT flashes).';
        _eventController?.add(AccuCheckAdapter.errorEvent(errorMsg));
        return HealthVitalResult.error(
          provider: DeviceProvider.accucheck,
          measurementType: MeasurementType.glucometer,
          message: errorMsg,
        );
      }

      final result = AccuCheckAdapter.toHealthVitalResult(glucoseLevel);
      _eventController?.add(AccuCheckAdapter.completedEvent(glucoseLevel));
      return result;
    } catch (e) {
      _eventController?.add(AccuCheckAdapter.errorEvent(e.toString()));
      return HealthVitalResult.error(
        provider: DeviceProvider.accucheck,
        measurementType: MeasurementType.glucometer,
        message: e.toString(),
      );
    } finally {
      await logSub.cancel();
    }
  }

  /// Get AccuCheck log stream for debugging
  Stream<String> get accuCheckLogs => _accuCheck.logs;

  /// Check if AccuChek device is connected
  bool get isAccuCheckConnected => _accuCheck.isConnected;

  /// Reset AccuCheck service (disconnect, clear state)
  Future<void> resetAccuCheck() async {
    await _accuCheck.reset();
  }

  // ============================================================
  // ACTIVITY TRACKING (OMRON)
  // ============================================================

  /// Read activity data (Omron only)
  ///
  /// [device] - The saved Omron activity tracker device
  Future<HealthVitalResult?> readActivity({
    required omron.ScannedDevice device,
  }) async {
    return await _readOmronActivity(device);
  }

  Future<HealthVitalResult?> _readOmronActivity(
      omron.ScannedDevice? device) async {
    if (device == null) return null;

    try {
      _ensureOmronSubscription();
      final results = await _omron.transferFromBleDevice(device: device);
      if (results.isNotEmpty) {
        return OmronAdapter.toHealthVitalResult(results.last);
      }
      return null;
    } catch (e) {
      return HealthVitalResult.error(
        provider: DeviceProvider.omron,
        measurementType: MeasurementType.activity,
        message: e.toString(),
      );
    }
  }

  // ============================================================
  // UNIFIED EVENT STREAM
  // ============================================================

  /// Get unified event stream from all health device plugins
  ///
  /// This combines events from sm_lepu and sm_fitrus into a single stream.
  /// Omron events are not streamed but returned from transfer methods.
  Stream<HealthEventData> getEvents() {
    _eventController ??= StreamController<HealthEventData>.broadcast();
    return _eventController!.stream;
  }

  /// Get combined stream from Lepu and Fitrus as merged Rx stream
  Stream<HealthEventData> getCombinedEventStream() {
    final lepuStream =
        _lepu.getEvents().map<HealthEventData>(LepuAdapter.toHealthEvent);
    final fitrusStream = _fitrus.getEvents().map(FitrusAdapter.toHealthEvent);

    return Rx.merge<HealthEventData>([lepuStream, fitrusStream]);
  }

  // ============================================================
  // OMRON DEVICE MANAGEMENT
  // ============================================================

  // OMRON DEVICE MANAGEMENT
  // ============================================================

  /// Get list of supported Omron devices models (from plugin)
  Future<List<omron.DeviceModel>> getSupportedOmronDevices({
    omron.DeviceCategory? category,
  }) async {
    return await _omron.getSupportedDevices(category: category);
  }

  /// Get saved Omron devices
  Future<List<omron.ScannedDevice>> getSavedOmronDevices() async {
    return await _omron.getSavedDevices();
  }

  /// Save an Omron device
  Future<void> saveOmronDevice(omron.ScannedDevice device) async {
    await _omron.saveDevice(device);
  }

  /// Remove an Omron device
  Future<void> removeOmronDevice(omron.ScannedDevice device) async {
    await _omron.removeDevice(device);
  }

  /// Scan for a specific Omron BLE device model
  Future<omron.ScannedDevice?> scanOmronBleDevice({
    required omron.DeviceIdentifier deviceIdentifier,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    // Inject scanning status
    _eventController?.add(HealthEventData(
      provider: DeviceProvider.omron,
      // Use unknown or general for scanning phase if type is not strictly known here
      measurementType: MeasurementType.unknown,
      connectionState: HealthConnectionState.scanning,
      message: 'Scanning for Omron device...',
    ));

    return await _omron.scanBleDevice(
      deviceIdentifier: deviceIdentifier,
      timeout: timeout,
    );
  }

  /// Pair with a specific Omron BLE device
  Future<bool> pairOmronBleDevice({
    required omron.ScannedDevice device,
  }) async {
    _eventController?.add(HealthEventData(
      provider: DeviceProvider.omron,
      measurementType: MeasurementType.unknown,
      connectionState: HealthConnectionState.connecting,
      message: 'Pairing Omron device...',
    ));

    final success = await _omron.pairBleDevice(device: device);

    if (success) {
      _eventController?.add(HealthEventData(
        provider: DeviceProvider.omron,
        measurementType: MeasurementType.unknown,
        connectionState: HealthConnectionState.connected,
        message: 'Omron device paired successfully',
      ));
    } else {
      _eventController?.add(HealthEventData(
        provider: DeviceProvider.omron,
        measurementType: MeasurementType.unknown,
        connectionState: HealthConnectionState.error,
        message: 'Pairing failed',
      ));
    }
    return success;
  }

  /// Helper to create manual recording device (for Temperature)
  omron.ScannedDevice createOmronRecordingDevice(omron.DeviceModel model) {
    return _omron.addRecordingWaveDevice(model);
  }

  // ============================================================
  // DIRECT PLUGIN ACCESS
  // ============================================================

  /// Get direct access to SmFitrus plugin
  fitrus.SmFitrus get fitrusPlugin => _fitrus;

  /// Get direct access to SmLepu plugin
  lepu.SmLepu get lepuPlugin => _lepu;

  /// Get direct access to SMOmron plugin
  omron.SMOmron get omronPlugin => _omron;

  // ============================================================
  // CLEANUP
  // ============================================================

  /// Dispose all resources
  Future<void> dispose() async {
    _lepuSubscription?.cancel();
    _lepuSubscription = null;
    _fitrusSubscription?.cancel();
    _fitrusSubscription = null;
    _omronSubscription?.cancel();
    _omronSubscription = null;

    await _fitrus.cancelMeasurement();
    await _lepu.dispose();
    _omron.dispose();
    await _accuCheck.dispose();

    _isInitialized = false;
    debugPrint('SmHealthDevices: Disposed');
  }

  // ============================================================
  // PRIVATE HELPERS
  // ============================================================

  bool _validateProvider(DeviceProvider provider, MeasurementType type) {
    return type.supportedProviders.contains(provider);
  }
}
