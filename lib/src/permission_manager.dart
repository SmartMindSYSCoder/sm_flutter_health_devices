import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

import 'models/enums.dart';

/// Permission result containing all permission states
class PermissionResult {
  final PermissionState bluetooth;
  final PermissionState bluetoothScan;
  final PermissionState bluetoothConnect;
  final PermissionState location;
  final PermissionState microphone;
  final bool isLocationServiceEnabled;
  final bool isNetworkConnected;

  const PermissionResult({
    this.bluetooth = PermissionState.unknown,
    this.bluetoothScan = PermissionState.unknown,
    this.bluetoothConnect = PermissionState.unknown,
    this.location = PermissionState.unknown,
    this.microphone = PermissionState.unknown,
    this.isLocationServiceEnabled = false,
    this.isNetworkConnected = false,
  });

  /// Check if all Bluetooth permissions are granted
  bool get isBluetoothGranted =>
      bluetooth.isGranted ||
      (bluetoothScan.isGranted && bluetoothConnect.isGranted);

  /// Check if all required permissions for BLE are granted
  bool get isBleReady =>
      isBluetoothGranted && (location.isGranted || !_needsLocationForBle);

  /// Check if microphone is granted (for Omron temperature)
  bool get isMicrophoneGranted => microphone.isGranted;

  /// Check if all permissions are granted
  bool get isAllGranted =>
      isBleReady && isMicrophoneGranted && isLocationServiceEnabled;

  /// Android 12+ doesn't need location for BLE
  bool get _needsLocationForBle {
    if (Platform.isAndroid) {
      // Android 12 (API 31) and above don't need location for BLE
      // This is a simplified check; in production you'd check actual API level
      return true; // Conservative: always request location on Android
    }
    return false;
  }

  @override
  String toString() {
    return 'PermissionResult('
        'bluetooth: $bluetooth, '
        'bluetoothScan: $bluetoothScan, '
        'bluetoothConnect: $bluetoothConnect, '
        'location: $location, '
        'microphone: $microphone, '
        'locationService: $isLocationServiceEnabled, '
        'network: $isNetworkConnected'
        ')';
  }
}

/// Manages all permissions required for health device plugins
class HealthPermissionManager {
  /// Request base permissions (Bluetooth + Location + GPS)
  /// These are required for ALL health devices
  Future<PermissionResult> requestBasePermissions() async {
    final bluetooth = await _requestBluetoothPermissions();
    final location = await _requestLocationPermission();
    final locationService = await isLocationServiceEnabled();

    return PermissionResult(
      bluetooth: bluetooth['bluetooth'] ?? PermissionState.unknown,
      bluetoothScan: bluetooth['bluetoothScan'] ?? PermissionState.unknown,
      bluetoothConnect:
          bluetooth['bluetoothConnect'] ?? PermissionState.unknown,
      location: location,
      isLocationServiceEnabled: locationService,
    );
  }

  /// Request permissions for a specific measurement type and provider
  ///
  /// - Base (BT/GPS/Location): Always required
  /// - Microphone: Only for Omron temperature
  /// - Network: Only for Fitrus body composition
  Future<PermissionResult> requestPermissionsFor(
    MeasurementType type, {
    DeviceProvider? provider,
  }) async {
    // Always request base permissions
    final bluetooth = await _requestBluetoothPermissions();
    final location = await _requestLocationPermission();
    final locationService = await isLocationServiceEnabled();

    PermissionState microphone = PermissionState.unknown;
    bool network = false;

    // Microphone only for Omron temperature
    if (type == MeasurementType.temperature &&
        provider == DeviceProvider.omron) {
      microphone = await _requestMicrophonePermission();
    }

    // Network only for Fitrus body composition
    if (type == MeasurementType.bodyComposition) {
      network = await isNetworkConnected();
    }

    return PermissionResult(
      bluetooth: bluetooth['bluetooth'] ?? PermissionState.unknown,
      bluetoothScan: bluetooth['bluetoothScan'] ?? PermissionState.unknown,
      bluetoothConnect:
          bluetooth['bluetoothConnect'] ?? PermissionState.unknown,
      location: location,
      microphone: microphone,
      isLocationServiceEnabled: locationService,
      isNetworkConnected: network,
    );
  }

  /// Request microphone permission (for Omron audio temperature)
  Future<PermissionResult> requestMicrophonePermission() async {
    final microphone = await _requestMicrophonePermission();
    return PermissionResult(microphone: microphone);
  }

  /// Check network connectivity (for Fitrus)
  Future<PermissionResult> requestNetworkCheck() async {
    final network = await isNetworkConnected();
    return PermissionResult(isNetworkConnected: network);
  }

  /// Request all permissions at once (legacy - not recommended)
  /// Prefer using requestBasePermissions() or requestPermissionsFor()
  Future<PermissionResult> requestAllPermissions() async {
    final bluetooth = await _requestBluetoothPermissions();
    final location = await _requestLocationPermission();
    final microphone = await _requestMicrophonePermission();
    final locationService = await isLocationServiceEnabled();
    final network = await isNetworkConnected();

    return PermissionResult(
      bluetooth: bluetooth['bluetooth'] ?? PermissionState.unknown,
      bluetoothScan: bluetooth['bluetoothScan'] ?? PermissionState.unknown,
      bluetoothConnect:
          bluetooth['bluetoothConnect'] ?? PermissionState.unknown,
      location: location,
      microphone: microphone,
      isLocationServiceEnabled: locationService,
      isNetworkConnected: network,
    );
  }

  /// Check if Bluetooth permissions are granted
  Future<bool> checkBluetoothPermissions() async {
    if (Platform.isAndroid) {
      final scanStatus = await Permission.bluetoothScan.status;
      final connectStatus = await Permission.bluetoothConnect.status;
      return scanStatus.isGranted && connectStatus.isGranted;
    } else if (Platform.isIOS) {
      final status = await Permission.bluetooth.status;
      return status.isGranted;
    }
    return false;
  }

  /// Check if location permission is granted
  Future<bool> checkLocationPermission() async {
    final status = await Permission.locationWhenInUse.status;
    return status.isGranted;
  }

  /// Check if location service is enabled
  Future<bool> isLocationServiceEnabled() async {
    try {
      final serviceStatus = await Permission.location.serviceStatus;
      return serviceStatus == ServiceStatus.enabled;
    } catch (e) {
      debugPrint('Error checking location service: $e');
      return false;
    }
  }

  /// Request to enable location service
  Future<bool> requestLocationService() async {
    try {
      // Open location settings
      return await openAppSettings();
    } catch (e) {
      debugPrint('Error opening location settings: $e');
      return false;
    }
  }

  /// Check if microphone permission is granted
  Future<bool> checkMicrophonePermission() async {
    final status = await Permission.microphone.status;
    return status.isGranted;
  }

  /// Check network connectivity
  Future<bool> isNetworkConnected() async {
    try {
      final connectivity = await Connectivity().checkConnectivity();
      return !connectivity.contains(ConnectivityResult.none);
    } catch (e) {
      debugPrint('Error checking connectivity: $e');
      return false;
    }
  }

  /// Open app settings
  Future<bool> openSettings() async {
    return await openAppSettings();
  }

  // === Private Methods ===

  Future<Map<String, PermissionState>> _requestBluetoothPermissions() async {
    final result = <String, PermissionState>{};

    if (Platform.isAndroid) {
      // Android 12+ requires separate scan and connect permissions
      final scanStatus = await Permission.bluetoothScan.request();
      final connectStatus = await Permission.bluetoothConnect.request();

      result['bluetoothScan'] = _mapPermissionStatus(scanStatus);
      result['bluetoothConnect'] = _mapPermissionStatus(connectStatus);
      result['bluetooth'] = (scanStatus.isGranted && connectStatus.isGranted)
          ? PermissionState.granted
          : PermissionState.denied;
    } else if (Platform.isIOS) {
      final status = await Permission.bluetooth.request();
      result['bluetooth'] = _mapPermissionStatus(status);
    }

    return result;
  }

  Future<PermissionState> _requestLocationPermission() async {
    final status = await Permission.locationWhenInUse.request();
    return _mapPermissionStatus(status);
  }

  Future<PermissionState> _requestMicrophonePermission() async {
    final status = await Permission.microphone.request();
    return _mapPermissionStatus(status);
  }

  PermissionState _mapPermissionStatus(PermissionStatus status) {
    switch (status) {
      case PermissionStatus.granted:
        return PermissionState.granted;
      case PermissionStatus.denied:
        return PermissionState.denied;
      case PermissionStatus.permanentlyDenied:
        return PermissionState.permanentlyDenied;
      case PermissionStatus.restricted:
        return PermissionState.restricted;
      case PermissionStatus.limited:
        return PermissionState.limited;
      default:
        return PermissionState.unknown;
    }
  }
}
