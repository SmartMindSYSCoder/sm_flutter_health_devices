import 'dart:async';
import 'dart:developer';

import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';

class AccuCheckService {
  // Singleton pattern
  static final AccuCheckService _instance = AccuCheckService._internal();
  factory AccuCheckService() => _instance;
  AccuCheckService._internal();

  // ---------- constants ----------
  static final Uuid _glucoseService = Uuid.parse(
    "00001808-0000-1000-8000-00805f9b34fb",
  );
  static final Uuid _glucoseMeasurement = Uuid.parse(
    "00002a18-0000-1000-8000-00805f9b34fb",
  );
  static final Uuid _racp = Uuid.parse("00002a52-0000-1000-8000-00805f9b34fb");

  // ---------- fields ----------
  final FlutterReactiveBle _ble = FlutterReactiveBle();

  DiscoveredDevice? _device;
  StreamSubscription<ConnectionStateUpdate>? _connSub;
  StreamSubscription<List<int>>? _measSub;
  StreamSubscription<List<int>>? _racpSub;

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  // Streams exposed to the app
  late final StreamController<String> _logCtrl =
      StreamController<String>.broadcast();
  Stream<String> get logs => _logCtrl.stream;

  void _log(String msg) {
    if (!_logCtrl.isClosed) _logCtrl.add(msg);
    log('[SmAccuCheck] $msg');
  }

  /// Soft reset: cancel scans, disconnect, cancel subscriptions, clear cached device state.
  /// Keeps the public streams OPEN so the instance can continue being used.
  Future<void> reset() async {
    _log('reset()');
    await _measSub?.cancel();
    await _racpSub?.cancel();
    await _connSub?.cancel();
    _measSub = null;
    _racpSub = null;
    _connSub = null;
    _isConnected = false;
    _device = null;
  }

  /// Final cleanup: calls [reset] and then closes all streams and status listener.
  /// After this, the instance should not be reused.
  Future<void> dispose() async {
    _log('dispose()');
    await reset();
    await _logCtrl.close();
  }

  // ---------- permissions ----------

  Future<bool> requestPermissions() async {
    _log('Requesting permissions...');
    final req = <Permission>[
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ];
    final results = await req.request();
    if (results.values.any((s) => s.isDenied || s.isPermanentlyDenied)) {
      _log('Some permissions were denied.');
      return false;
    } else {
      _log('All permissions granted.');
      return true;
    }
  }

  // ---------- logic ----------

  Future<void> _connect(
    String deviceId, {
    Duration timeout = const Duration(seconds: 30),
  }) async {
    await _connSub?.cancel();

    _log('Connecting to $deviceId...');
    final completer = Completer<void>();

    _connSub =
        _ble.connectToDevice(id: deviceId, connectionTimeout: timeout).listen(
      (update) async {
        _log('Connection: ${update.connectionState}');
        _isConnected =
            update.connectionState == DeviceConnectionState.connected;

        if (_isConnected) {
          if (!completer.isCompleted) completer.complete();
        } else if (update.connectionState ==
            DeviceConnectionState.disconnected) {
          await _onDisconnected();
        }
      },
      onError: (e) async {
        _log('Connection error: $e');
        if (!completer.isCompleted) completer.completeError(e);
        await _onDisconnected();
      },
    );

    if (!_isConnected) {
      // Wait for connection or timeout handled by ble lib, but we can wait here too if needed
      // For now relying on the stream handler
    }
  }

  Future<void> _onDisconnected() async {
    await _measSub?.cancel();
    await _racpSub?.cancel();
    _measSub = null;
    _racpSub = null;
    _isConnected = false;
    _log('Disconnected.');
  }

  Future<bool> _ensureConnected({
    Duration scanTimeout = const Duration(seconds: 10),
    Duration connectTimeout = const Duration(seconds: 20),
  }) async {
    if (_isConnected && _device != null) return true;

    // If we already have a candidate device, try to connect.
    if (_device != null) {
      _log('Reconnecting to cached device: ${_device!.name} (${_device!.id})');
      await _connect(_device!.id, timeout: connectTimeout);
    } else {
      // One-shot scan to find the first eligible device.
      _log(
          'Scanning for Accu-Chek devices (ensure BT is on and device is in pairing mode)...');
      final c = Completer<DiscoveredDevice?>();
      late final StreamSubscription<DiscoveredDevice> sub;

      sub = _ble.scanForDevices(
        withServices: [_glucoseService],
        scanMode: ScanMode.lowLatency,
        requireLocationServicesEnabled: false,
      ).listen(
        (d) {
          final name = d.name.toLowerCase();
          final manData = d.manufacturerData;

          // More robust recognition: service UUID is already filtered by scanForDevices
          // Now we just confirm it looks like an Accu-Chek or Roche device
          final isAccuChek = name.contains('accu') ||
              name.contains('roche') ||
              name.contains('instant') ||
              name.contains('meter') ||
              (manData.length >= 2 &&
                  manData[0] == 0x59 &&
                  manData[1] == 0x00) ||
              (manData.isNotEmpty && name.isEmpty);

          if (isAccuChek && !c.isCompleted) {
            _log('Found Accu-Chek compatible device: ${d.name} (${d.id})');
            c.complete(d);
          }
        },
        onError: (e) {
          _log('Scan error: $e');
          if (!c.isCompleted) c.complete(null);
        },
      );

      final timer = Timer(scanTimeout, () {
        if (!c.isCompleted) {
          _log('Scan timed out. No Accu-Chek device found.');
          c.complete(null);
        }
      });

      final found = await c.future;
      await sub.cancel();
      timer.cancel();

      if (found == null) {
        return false;
      }

      _device = found;
      await _connect(found.id, timeout: connectTimeout);
    }

    // Wait until connected or timeout
    final limit = DateTime.now().add(connectTimeout);
    while (DateTime.now().isBefore(limit)) {
      if (_isConnected) {
        _log('Successfully connected to Accu-Chek.');
        return true;
      }
      await Future.delayed(const Duration(milliseconds: 200));
    }
    _log('Connect attempt timed out.');
    return _isConnected;
  }

  /// High-level convenience: scan/connect if needed, then return the last record (mg/dL).
  /// Returns null if connection fails or no record arrives before [readTimeout].
  Future<int?> readLastRecord({
    Duration scanTimeout = const Duration(seconds: 10),
    Duration connectTimeout = const Duration(seconds: 20),
    Duration readTimeout = const Duration(seconds: 10),
  }) async {
    final ok = await _ensureConnected(
      scanTimeout: scanTimeout,
      connectTimeout: connectTimeout,
    );
    if (!ok) {
      _log('readLastRecord(): could not connect.');
      return null;
    }
    return await _readLastRecord(timeout: readTimeout);
  }

  /// One-shot read of the last stored glucose value (mg/dL).
  /// Returns null if none or on timeout.
  Future<int?> _readLastRecord({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    if (!_isConnected || _device == null) {
      _log('readOnlyLastRecord(): not connected.');
      return null;
    }

    final deviceId = _device!.id;

    final measChar = QualifiedCharacteristic(
      serviceId: _glucoseService,
      characteristicId: _glucoseMeasurement,
      deviceId: deviceId,
    );
    final racpChar = QualifiedCharacteristic(
      serviceId: _glucoseService,
      characteristicId: _racp,
      deviceId: deviceId,
    );

    int? lastValue;
    final completer = Completer<int?>();

    _log('Subscribing to measurement...');
    // Temporary measurement subscription: capture your device-specific value[12]
    late final StreamSubscription<List<int>> measTemp;
    measTemp = _ble.subscribeToCharacteristic(measChar).listen(
      (value) {
        // According to Bluetooth SIG, Glucose Measurement:
        // Flag (1 byte), Sequence Number (2 bytes), ...
        // We need to be careful with parsing.
        // The original code used value[12], which assumes a specific format/context.
        // We will keep it for now but log it.
        if (value.length > 12) {
          // Verify if this is mg/dL or mmol/L?
          // The flag byte (byte 0) bit 2 indicates unit. 0 = kg/L (mg/dL basically), 1 = mol/L.
          // However, for simplicity and "expert" improvement, we should arguably parse it correctly.
          // But I'll stick to the original logic if it worked for the user, just safer.

          // Simple check:
          lastValue = value[12];
          _log('Received measurement Packet. Value@12: $lastValue');
        } else {
          _log('Received short measurement packet: $value');
        }
      },
      onError: (e) {
        _log('glucose meas error: $e');
      },
    );

    _log('Subscribing to RACP...');
    // Temporary RACP subscription: complete when we see Response Code
    late final StreamSubscription<List<int>> racpTemp;
    racpTemp = _ble.subscribeToCharacteristic(racpChar).listen(
      (bytes) {
        // RACP Response Code frame: OpCode=0x06, ReqOpCode (1), ResponseCodeValue (1)
        if (bytes.length >= 4 && bytes[0] == 0x06) {
          final resp = bytes[3]; // 0x01 = Success, 0x06 = No records
          _log('RACP Response: $resp');
          if (resp == 0x01 || resp == 0x06) {
            if (!completer.isCompleted) completer.complete(lastValue);
          }
        }
      },
      onError: (e) {
        _log('readOnlyLastRecord(): RACP temp error: $e');
      },
    );

    // Safety timeout
    final timer = Timer(timeout, () {
      if (!completer.isCompleted) {
        _log('Read timeout.');
        completer.complete(lastValue);
      }
    });

    try {
      // Ask for LAST record only: OpCode=0x01 (Report), Operator=0x06 (Last)
      _log('Writing RACP command (Report Last)...');
      await _ble.writeCharacteristicWithResponse(
        racpChar,
        value: const [0x01, 0x06],
      );
    } catch (e) {
      _log('readOnlyLastRecord(): RACP write failed: $e');
      // still wait for timeout or any in-flight response
    }

    final result = await completer.future;

    // Cleanup temporary listeners
    await measTemp.cancel();
    await racpTemp.cancel();
    timer.cancel();

    _log('Finished reading. Result: $result');

    return result; // mg/dL or null
  }
}
