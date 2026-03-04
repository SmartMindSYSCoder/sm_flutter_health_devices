import 'package:get_storage/get_storage.dart';
import '../models/enums.dart';

/// Manager for handling health device settings and provider preferences
class SettingsManager {
  static final SettingsManager _instance = SettingsManager._internal();
  factory SettingsManager() => _instance;
  SettingsManager._internal();

  final GetStorage _box = GetStorage('sm_health_settings');
  bool _initialized = false;

  /// Initialize the settings manager
  Future<void> init() async {
    if (_initialized) return;
    await GetStorage.init('sm_health_settings');
    _initialized = true;
  }

  /// Get the preferred provider for a given measurement type
  DeviceProvider getPreferredProvider(MeasurementType type) {
    if (!_initialized) return _getDefaultProvider(type);

    final key = _getProviderKey(type);
    final value = _box.read<String>(key);

    if (value == null) return _getDefaultProvider(type);

    return DeviceProvider.values.firstWhere(
      (p) => p.name == value,
      orElse: () => _getDefaultProvider(type),
    );
  }

  /// Set the preferred provider for a given measurement type
  Future<void> setPreferredProvider(
      MeasurementType type, DeviceProvider provider) async {
    if (!_initialized) await init();
    final key = _getProviderKey(type);
    await _box.write(key, provider.name);
  }

  /// Reset all settings to defaults
  Future<void> resetToDefaults() async {
    if (!_initialized) await init();
    await _box.erase();
    // Re-initialize isn't strictly necessary for GetStorage after erase,
    // but we want to ensure any cached state is cleared.
  }

  /// Get the key for storing the provider for a measurement type
  String _getProviderKey(MeasurementType type) => 'pref_provider_${type.name}';

  /// Get default provider for each measurement type
  DeviceProvider _getDefaultProvider(MeasurementType type) {
    switch (type) {
      case MeasurementType.weight:
        return DeviceProvider.lepu;
      case MeasurementType.bloodPressure:
        return DeviceProvider.raycome;
      case MeasurementType.temperature:
        return DeviceProvider.lepu;
      case MeasurementType.spo2:
        return DeviceProvider.lepu;
      case MeasurementType.bodyComposition:
        return DeviceProvider.fitrus;
      case MeasurementType.activity:
        return DeviceProvider.omron;
      case MeasurementType.wheeze:
        return DeviceProvider.omron;
      case MeasurementType.glucometer:
        return DeviceProvider.accucheck;
      default:
        return DeviceProvider.unknown;
    }
  }
}
