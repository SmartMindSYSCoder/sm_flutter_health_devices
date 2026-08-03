import '../../sm_flutter_health_devices.dart';

/// Functional configuration for SmHealthDeviceWidget initialization.
/// Handles behavior, automated flows, and specialized measurement requirements.
class SmHealthInitConfig {
  /// Automatically start scanning when the widget builds.
  final bool autoStartScan;

  /// Whether to show a detailed success dialog on completion.
  /// If false, simply triggers onResult callback.
  final bool showResultDialog;

  /// Automatically trigger onResult and exit when measurement is successful.
  final bool autoSave;

  /// Optional user profile for specialized measurements (e.g. Fitrus body composition)
  final SmUserProfile? userProfile;

  /// Optional API Key for Fitrus provider
  final String? fitrusApiKey;

  /// Optional API Key for Omron provider
  final String? omronApiKey;

  /// Language used by plugin settings pages.
  ///
  /// Defaults to [SmHealthSettingsLanguage.en].
  final SmHealthSettingsLanguage lang;

  /// Optional timeout for measurement/scan operations before timing out.
  /// Defaults to 30 seconds.
  final Duration timeout;

  /// Optional timeout for when the device is in measuring mode.
  /// Defaults to 90 seconds.
  final Duration measuringTimeout;

  const SmHealthInitConfig({
    this.autoStartScan = true,
    this.showResultDialog = false,
    this.autoSave = false,
    this.userProfile,
    this.fitrusApiKey,
    this.omronApiKey,
    this.lang = SmHealthSettingsLanguage.en,
    this.timeout = const Duration(seconds: 30),
    this.measuringTimeout = const Duration(seconds: 90),
  });
}
