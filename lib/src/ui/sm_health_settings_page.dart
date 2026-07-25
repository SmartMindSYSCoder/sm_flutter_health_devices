import 'package:flutter/material.dart';

import '../../sm_flutter_health_devices.dart';
import 'sm_omron_devices_page.dart';

/// Theme overrides for [SmHealthSettingsPage] and its related pages.
///
/// The page uses a built-in modern light theme by default. Pass only the
/// overrides that your application needs.
class SmHealthSettingsThemeData {
  /// Page title shown in the settings app bar.
  ///
  /// Defaults to `Measurement Settings`.
  final String? title;

  /// Main page background color for the settings and Omron devices pages.
  final Color backgroundColor;

  /// Background color for measurement cards, Omron device cards, and dialogs.
  final Color cardColor;

  /// Accent color for selected provider chips, icons, loading indicators,
  /// buttons, and the add-device floating action button.
  final Color primaryColor;

  /// Main text color for page titles, card titles, and device names.
  final Color textColor;

  /// Muted text color for descriptions, labels, serial numbers, and captions.
  final Color secondaryTextColor;

  /// Border color for cards, chips, status badges, and icon containers.
  final Color borderColor;

  /// Background color for unselected provider chips and serial-number labels.
  final Color chipColor;

  /// Optional style for page and dialog titles.
  ///
  /// When null, a bold 20px style using [textColor] is applied.
  final TextStyle? titleTextStyle;

  /// Optional style for measurement names, Omron device names, and card titles.
  ///
  /// When null, a bold 17px style using [textColor] is applied.
  final TextStyle? itemTitleTextStyle;

  /// Optional style for descriptions and secondary labels.
  ///
  /// When null, a 13px style using [secondaryTextColor] is applied.
  final TextStyle? bodyTextStyle;

  /// Elevation for measurement setting cards.
  final double cardElevation;

  /// Inner padding for measurement setting cards.
  final EdgeInsetsGeometry cardPadding;

  /// Corner radius for settings cards and Omron device cards.
  final double cardBorderRadius;

  /// Corner radius for provider selection chips.
  final double chipBorderRadius;

  const SmHealthSettingsThemeData({
    this.title,
    this.backgroundColor = const Color(0xFFF8FAFC),
    this.cardColor = Colors.white,
    this.primaryColor = const Color(0xFF2563EB),
    this.textColor = const Color(0xFF172033),
    this.secondaryTextColor = const Color(0xFF64748B),
    this.borderColor = const Color(0xFFE2E8F0),
    this.chipColor = const Color(0xFFF1F5F9),
    this.titleTextStyle,
    this.itemTitleTextStyle,
    this.bodyTextStyle,
    this.cardElevation = 0,
    this.cardPadding = const EdgeInsets.all(20),
    this.cardBorderRadius = 20,
    this.chipBorderRadius = 14,
  });

  Color get primarySoftColor =>
      Color.alphaBlend(primaryColor.withValues(alpha: 0.14), cardColor);

  Color get dangerColor => const Color(0xFFDC2626);

  Color get dangerSoftColor => const Color(0xFFFEE2E2);

  Color get successColor => const Color(0xFF16A34A);

  TextStyle get resolvedTitleTextStyle =>
      titleTextStyle ??
      TextStyle(
        color: textColor,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      );

  TextStyle get resolvedItemTitleTextStyle =>
      itemTitleTextStyle ??
      TextStyle(
        color: textColor,
        fontSize: 17,
        fontWeight: FontWeight.w700,
      );

  TextStyle get resolvedBodyTextStyle =>
      bodyTextStyle ??
      TextStyle(
        color: secondaryTextColor,
        fontSize: 13,
      );
}

/// A highly customizable Settings Page for health device provider selection.
/// This is part of the plugin UI and can be used directly in any application.
class SmHealthSettingsPage extends StatefulWidget {
  final SmHealthSettingsThemeData theme;
  final SmHealthInitConfig initConfig;

  const SmHealthSettingsPage({
    super.key,
    this.theme = const SmHealthSettingsThemeData(),
    this.initConfig = const SmHealthInitConfig(),
  });

  /// Static method to easily open the settings page.
  static Future<void> open(
    BuildContext context, {
    SmHealthSettingsThemeData theme = const SmHealthSettingsThemeData(),
    SmHealthInitConfig initConfig = const SmHealthInitConfig(),
  }) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SmHealthSettingsPage(
          theme: theme,
          initConfig: initConfig,
        ),
      ),
    );
  }

  @override
  State<SmHealthSettingsPage> createState() => _SmHealthSettingsPageState();
}

class _SmHealthSettingsPageState extends State<SmHealthSettingsPage> {
  final SmHealthDevices _healthDevices = SmHealthDevices();

  SmHealthSettingsTranslations get _translations =>
      SmHealthSettingsTranslations(widget.initConfig.lang);

  final List<MeasurementType> _configurableTypes = [
    MeasurementType.weight,
    MeasurementType.bloodPressure,
    MeasurementType.spo2,
    MeasurementType.temperature,
    MeasurementType.glucometer,
    MeasurementType.bodyComposition,
  ];

  @override
  void initState() {
    super.initState();
    // Ensure settings are loaded before first build
    _healthDevices
        .init(
      config: HealthDevicesConfig(
        fitrusApiKey: widget.initConfig.fitrusApiKey,
        omronApiKey: widget.initConfig.omronApiKey,
        timeout: widget.initConfig.timeout,
        measuringTimeout: widget.initConfig.measuringTimeout,
      ),
    )
        .then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final settingsTheme = widget.theme;
    final translations = _translations;

    if (!_healthDevices.isInitialized) {
      return Directionality(
        textDirection: translations.textDirection,
        child: Scaffold(
          backgroundColor: settingsTheme.backgroundColor,
          appBar: AppBar(
            title: Text(
              settingsTheme.title ?? translations.measurementSettings,
              style: settingsTheme.resolvedTitleTextStyle,
            ),
            centerTitle: true,
            elevation: 0,
            backgroundColor: Colors.transparent,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: translations.resetToDefaults,
                onPressed: () async {
                  final confirm = await _showResetConfirmation(context);
                  if (confirm == true) {
                    await _healthDevices.settingsManager.resetToDefaults();
                    if (mounted) setState(() {});
                  }
                },
              ),
            ],
          ),
          body: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return Directionality(
      textDirection: translations.textDirection,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: Text(
            settingsTheme.title ?? translations.measurementSettings,
            style: settingsTheme.resolvedTitleTextStyle,
          ),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          iconTheme: IconThemeData(color: settingsTheme.primaryColor),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: translations.resetToDefaults,
              onPressed: () async {
                final confirm = await _showResetConfirmation(context);
                if (confirm == true) {
                  await _healthDevices.settingsManager.resetToDefaults();
                  if (mounted) setState(() {});
                }
              },
            ),
          ],
        ),
        body: Container(
          decoration: BoxDecoration(
            color: settingsTheme.backgroundColor,
          ),
          child: SafeArea(
            bottom: false,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              physics: const BouncingScrollPhysics(),
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 600),
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 20 * (1 - value)),
                        child: child,
                      ),
                    );
                  },
                  child: _buildOmronDevicesCard(settingsTheme),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 12),
                  child: Text(
                    translations.preferences,
                    style: settingsTheme.resolvedBodyTextStyle.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
                ..._configurableTypes.asMap().entries.map((entry) {
                  final index = entry.key;
                  final type = entry.value;
                  return TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: Duration(milliseconds: 600 + (index * 100)),
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset(0, 30 * (1 - value)),
                          child: child,
                        ),
                      );
                    },
                    child: _buildMeasurementSettingCard(
                      type,
                      settingsTheme,
                    ),
                  );
                }),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<bool?> _showResetConfirmation(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: _translations.textDirection,
        child: AlertDialog(
          title: Text(_translations.resetToDefaultsQuestion),
          content: Text(_translations.resetToDefaultsDescription),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(_translations.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(_translations.reset),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOmronDevicesCard(SmHealthSettingsThemeData settingsTheme) {
    final borderRadius = BorderRadius.circular(settingsTheme.cardBorderRadius);

    return Container(
      decoration: BoxDecoration(
        color: settingsTheme.primarySoftColor,
        borderRadius: borderRadius,
        border: Border.all(color: settingsTheme.borderColor),
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Material(
          color: Colors.transparent,
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            leading: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: settingsTheme.primaryColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.bluetooth_searching_rounded,
                color: settingsTheme.primaryColor,
                size: 28,
              ),
            ),
            title: Text(
              _translations.omronDevices,
              style: settingsTheme.resolvedItemTitleTextStyle,
            ),
            subtitle: Text(
              _translations.managePairedEquipment,
              style: settingsTheme.resolvedBodyTextStyle,
            ),
            trailing: Icon(
              Icons.chevron_right_rounded,
              color: settingsTheme.textColor,
            ),
            onTap: () => SmOmronDevicesPage.open(
              context,
              theme: settingsTheme,
              initConfig: widget.initConfig,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMeasurementSettingCard(
      MeasurementType type, SmHealthSettingsThemeData settingsTheme) {
    final currentProvider =
        _healthDevices.settingsManager.getPreferredProvider(type);
    final supportedProviders = type.supportedProviders;

    final defaultShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(settingsTheme.cardBorderRadius),
      side: BorderSide(color: settingsTheme.borderColor),
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: settingsTheme.cardColor,
      elevation: settingsTheme.cardElevation,
      shape: defaultShape,
      child: Padding(
        padding: settingsTheme.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: settingsTheme.primarySoftColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    _getMeasurementIcon(type),
                    color: settingsTheme.primaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  _translations.measurementType(type),
                  style: settingsTheme.resolvedItemTitleTextStyle,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              _translations.preferredProvider,
              style: settingsTheme.resolvedBodyTextStyle.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: supportedProviders.map((provider) {
                final isSelected = currentProvider == provider;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _healthDevices.settingsManager
                          .setPreferredProvider(type, provider);
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? settingsTheme.primaryColor
                          : settingsTheme.chipColor,
                      borderRadius:
                          BorderRadius.circular(settingsTheme.chipBorderRadius),
                      border: Border.all(
                        color: isSelected
                            ? settingsTheme.primaryColor
                            : settingsTheme.borderColor,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: settingsTheme.primaryColor
                                    .withValues(alpha: 0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              )
                            ]
                          : [],
                    ),
                    child: Text(
                      _translations.provider(provider),
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : settingsTheme.secondaryTextColor,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getMeasurementIcon(MeasurementType type) {
    switch (type) {
      case MeasurementType.weight:
        return Icons.monitor_weight_outlined;
      case MeasurementType.bloodPressure:
        return Icons.favorite_outline;
      case MeasurementType.temperature:
        return Icons.thermostat_outlined;
      case MeasurementType.spo2:
        return Icons.air_outlined;
      case MeasurementType.glucometer:
        return Icons.water_drop_outlined;
      case MeasurementType.bodyComposition:
        return Icons.accessibility_new_outlined;
      default:
        return Icons.health_and_safety_outlined;
    }
  }
}
