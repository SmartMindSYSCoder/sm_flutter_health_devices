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

  /// Optional custom callback when the user taps "Test Device".
  /// If null, a built-in modern centered live measurement dialog will open.
  final void Function(
    BuildContext context,
    MeasurementType type,
    DeviceProvider provider,
  )? onTestMeasurement;

  const SmHealthSettingsPage({
    super.key,
    this.theme = const SmHealthSettingsThemeData(),
    this.initConfig = const SmHealthInitConfig(),
    this.onTestMeasurement,
  });

  /// Static method to easily open the settings page.
  static Future<void> open(
    BuildContext context, {
    SmHealthSettingsThemeData theme = const SmHealthSettingsThemeData(),
    SmHealthInitConfig initConfig = const SmHealthInitConfig(),
    void Function(
      BuildContext context,
      MeasurementType type,
      DeviceProvider provider,
    )? onTestMeasurement,
  }) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SmHealthSettingsPage(
          theme: theme,
          initConfig: initConfig,
          onTestMeasurement: onTestMeasurement,
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

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: settingsTheme.cardColor,
        borderRadius: BorderRadius.circular(settingsTheme.cardBorderRadius),
        border: Border.all(color: settingsTheme.borderColor),
        boxShadow: settingsTheme.cardElevation > 0
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Padding(
        padding: settingsTheme.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card Header Row: Icon, Title & Active Provider, Trailing Test Action Button
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: settingsTheme.primarySoftColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    _getMeasurementIcon(type),
                    color: settingsTheme.primaryColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _translations.measurementType(type),
                        style: settingsTheme.resolvedItemTitleTextStyle,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: settingsTheme.primaryColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _translations.provider(currentProvider),
                            style: settingsTheme.resolvedBodyTextStyle.copyWith(
                              fontSize: 12,
                              color: settingsTheme.primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                // Trailing Action Button: "Test Device"
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      if (widget.onTestMeasurement != null) {
                        widget.onTestMeasurement!(
                            context, type, currentProvider);
                      } else {
                        _openTestMeasurementDialog(
                            context, type, currentProvider);
                      }
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Ink(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: settingsTheme.primarySoftColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: settingsTheme.primaryColor
                              .withValues(alpha: 0.35),
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.sensors_rounded,
                            size: 16,
                            color: settingsTheme.primaryColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _translations.testDevice,
                            style: TextStyle(
                              color: settingsTheme.primaryColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
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
            const SizedBox(height: 12),
            // Provider Cards/Chips
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
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 11),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? settingsTheme.primaryColor
                          : settingsTheme.chipColor,
                      borderRadius: BorderRadius.circular(
                          settingsTheme.chipBorderRadius),
                      border: Border.all(
                        color: isSelected
                            ? settingsTheme.primaryColor
                            : settingsTheme.borderColor,
                        width: isSelected ? 1.5 : 1.0,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: settingsTheme.primaryColor
                                    .withValues(alpha: 0.25),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              )
                            ]
                          : [],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isSelected) ...[
                          const Icon(
                            Icons.check_circle_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 6),
                        ],
                        Text(
                          _translations.provider(provider),
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : settingsTheme.textColor,
                            fontWeight:
                                isSelected ? FontWeight.bold : FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ],
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

  void _openTestMeasurementDialog(
    BuildContext context,
    MeasurementType type,
    DeviceProvider provider,
  ) {
    final settingsTheme = widget.theme;
    final translations = _translations;
    final screenHeight = MediaQuery.of(context).size.height;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Directionality(
          textDirection: translations.textDirection,
          child: Dialog(
            backgroundColor: settingsTheme.cardColor,
            elevation: 12,
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(settingsTheme.cardBorderRadius * 1.2),
              side: BorderSide(color: settingsTheme.borderColor),
            ),
            insetPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Container(
              constraints: BoxConstraints(
                maxWidth: 420,
                maxHeight: screenHeight * 0.8,
              ),
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Centered Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const SizedBox(width: 32),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: settingsTheme.primarySoftColor,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _getMeasurementIcon(type),
                            color: settingsTheme.primaryColor,
                            size: 24,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          color: settingsTheme.secondaryTextColor,
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      translations.testTypeMeasurement(type),
                      textAlign: TextAlign.center,
                      style: settingsTheme.resolvedItemTitleTextStyle.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: settingsTheme.primarySoftColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${translations.preferredProvider}: ${translations.provider(provider)}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: settingsTheme.primaryColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Divider(
                        height: 1,
                        color:
                            settingsTheme.borderColor.withValues(alpha: 0.6)),
                    const SizedBox(height: 12),
                    // Tightly-wrapped SmHealthDeviceWidget
                    SmHealthDeviceWidget(
                      measurementType: type,
                      initConfig: widget.initConfig,
                      uiConfig: SmHealthUiConfig(
                        showAppBar: false,
                        textColor: settingsTheme.textColor,
                      ),
                      onResult: (result) {
                        Navigator.pop(context);
                        final items =
                            _getFormattedResultItems(result, translations);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${translations.measurementType(type)}: ${items.map((e) => "${e.key}: ${e.value}").join(", ")}',
                            ),
                            backgroundColor: settingsTheme.primaryColor,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      },
                      onCancel: () => Navigator.pop(context),
                      stateBuilder: (context, event, onCancel) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: settingsTheme.primarySoftColor,
                                  shape: BoxShape.circle,
                                ),
                                child: CircularProgressIndicator(
                                  color: settingsTheme.primaryColor,
                                  strokeWidth: 3.5,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                translations.translateMessage(
                                  event.message.isNotEmpty
                                      ? event.message
                                      : translations.starting,
                                ),
                                textAlign: TextAlign.center,
                                style: settingsTheme.resolvedItemTitleTextStyle
                                    .copyWith(fontSize: 15),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${translations.provider(provider)} • ${translations.measurementType(type)}',
                                textAlign: TextAlign.center,
                                style: settingsTheme.resolvedBodyTextStyle,
                              ),
                              const SizedBox(height: 24),
                              OutlinedButton.icon(
                                onPressed: onCancel,
                                icon: const Icon(Icons.cancel_outlined,
                                    size: 18),
                                label: Text(translations.cancel),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor:
                                      settingsTheme.secondaryTextColor,
                                  side: BorderSide(
                                      color: settingsTheme.borderColor),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24, vertical: 12),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      successBuilder: (context, result, onSave, onReset) {
                        final dataEntries =
                            _getFormattedResultItems(result, translations);

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: settingsTheme.successColor
                                      .withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.check_circle_rounded,
                                  color: settingsTheme.successColor,
                                  size: 42,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                translations.measurementSuccess,
                                textAlign: TextAlign.center,
                                style: settingsTheme.resolvedItemTitleTextStyle
                                    .copyWith(
                                  color: settingsTheme.successColor,
                                  fontSize: 17,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: settingsTheme.chipColor,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                      color: settingsTheme.borderColor),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: dataEntries.map((e) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 5),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            e.key,
                                            style: settingsTheme
                                                .resolvedBodyTextStyle
                                                .copyWith(fontSize: 13),
                                          ),
                                          Text(
                                            e.value,
                                            style: settingsTheme
                                                .resolvedItemTitleTextStyle
                                                .copyWith(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: onReset,
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 12),
                                        foregroundColor:
                                            settingsTheme.textColor,
                                        side: BorderSide(
                                            color: settingsTheme.borderColor),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                      ),
                                      child: Text(translations.retry),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: onSave,
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 12),
                                        backgroundColor:
                                            settingsTheme.primaryColor,
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                      ),
                                      child: Text(translations.close),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                      errorBuilder: (context, errorMessage, onRetry, onCancel) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: settingsTheme.dangerSoftColor,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.error_outline_rounded,
                                  color: settingsTheme.dangerColor,
                                  size: 40,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                translations.translateMessage(errorMessage),
                                textAlign: TextAlign.center,
                                style: settingsTheme.resolvedBodyTextStyle
                                    .copyWith(
                                  color: settingsTheme.dangerColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: onCancel,
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 12),
                                        foregroundColor:
                                            settingsTheme.secondaryTextColor,
                                        side: BorderSide(
                                            color: settingsTheme.borderColor),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                      ),
                                      child: Text(translations.close),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: onRetry,
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 12),
                                        backgroundColor:
                                            settingsTheme.primaryColor,
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                      ),
                                      child: Text(translations.retry),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  List<MapEntry<String, String>> _getFormattedResultItems(
      HealthVitalResult result, SmHealthSettingsTranslations translations) {
    final list = <MapEntry<String, String>>[];

    switch (result.measurementType) {
      case MeasurementType.weight:
        if (result.weight != null) {
          list.add(MapEntry(
              translations.isArabic ? 'الوزن' : 'Weight', '${result.weight} kg'));
        }
        if (result.bmi != null) {
          list.add(MapEntry('BMI', '${result.bmi}'));
        }
        break;

      case MeasurementType.bloodPressure:
        if (result.systolic != null && result.diastolic != null) {
          list.add(MapEntry(translations.isArabic ? 'ضغط الدم' : 'Blood Pressure',
              '${result.systolic}/${result.diastolic} mmHg'));
        }
        if (result.pulse != null) {
          list.add(MapEntry(translations.isArabic ? 'النبض' : 'Pulse',
              '${result.pulse} bpm'));
        }
        if (result.irregularHeartbeat != null) {
          list.add(MapEntry(
              translations.isArabic ? 'نبض غير منتظم' : 'Irregular Heartbeat',
              result.irregularHeartbeat!
                  ? (translations.isArabic ? 'نعم' : 'Yes')
                  : (translations.isArabic ? 'لا' : 'No')));
        }
        break;

      case MeasurementType.temperature:
        if (result.temperature != null) {
          final symbol =
              result.temperatureUnit == TemperatureUnit.fahrenheit ? '°F' : '°C';
          list.add(MapEntry(
              translations.isArabic ? 'درجة الحرارة' : 'Temperature',
              '${result.temperature}$symbol'));
        }
        break;

      case MeasurementType.spo2:
        if (result.spo2 != null) {
          list.add(MapEntry('SpO2', '${result.spo2}%'));
        }
        if (result.heartRate != null) {
          list.add(MapEntry(
              translations.isArabic ? 'معدل ضربات القلب' : 'Heart Rate',
              '${result.heartRate} bpm'));
        }
        break;

      case MeasurementType.glucometer:
        if (result.glucoseLevel != null) {
          list.add(MapEntry(
              translations.isArabic ? 'سكر الدم' : 'Glucose Level',
              '${result.glucoseLevel} mg/dL'));
        }
        break;

      case MeasurementType.bodyComposition:
        if (result.weight != null) {
          list.add(MapEntry(
              translations.isArabic ? 'الوزن' : 'Weight', '${result.weight} kg'));
        }
        if (result.bmi != null) {
          list.add(MapEntry('BMI', '${result.bmi}'));
        }
        if (result.fatPercentage != null || result.bodyFatPercentage != null) {
          final fat = result.fatPercentage ?? result.bodyFatPercentage;
          list.add(MapEntry(
              translations.isArabic ? 'نسبة الدهون' : 'Body Fat', '$fat%'));
        }
        if (result.skeletalMusclePercentage != null ||
            result.muscleMass != null) {
          final muscle = result.skeletalMusclePercentage ?? result.muscleMass;
          final unit = result.skeletalMusclePercentage != null ? '%' : ' kg';
          list.add(MapEntry(
              translations.isArabic ? 'العضلات الهيكلية' : 'Skeletal Muscle',
              '$muscle$unit'));
        }
        if (result.visceralFatLevel != null) {
          list.add(MapEntry(
              translations.isArabic ? 'الدهون الأحشائية' : 'Visceral Fat',
              '${result.visceralFatLevel}'));
        }
        if (result.basalMetabolicRate != null || result.bmr != null) {
          final bmrVal = result.basalMetabolicRate ?? result.bmr;
          list.add(MapEntry(
              translations.isArabic ? 'الـ BMR' : 'BMR', '$bmrVal kcal'));
        }
        if (result.bodyAge != null) {
          list.add(MapEntry(
              translations.isArabic ? 'عمر الجسم' : 'Body Age',
              '${result.bodyAge}'));
        }
        break;

      default:
        for (var entry in result.toJson().entries) {
          if (entry.value != null &&
              entry.key != 'provider' &&
              entry.key != 'measurementType' &&
              entry.key != 'hasData' &&
              entry.key != 'errorMessage' &&
              entry.key != 'measurementDate' &&
              entry.key != 'temperatureUnit') {
            list.add(MapEntry(
                _translateResultKey(entry.key, translations.isArabic),
                '${entry.value}'));
          }
        }
        break;
    }

    // Add Measurement Date formatted cleanly at the end if present
    if (result.measurementDate != null) {
      final date = result.measurementDate!;
      final formattedDate =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
          '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      list.add(MapEntry(
          translations.isArabic ? 'تاريخ القياس' : 'Measurement Date',
          formattedDate));
    }

    return list;
  }

  String _translateResultKey(String key, bool isArabic) {
    if (!isArabic) return key;
    switch (key) {
      case 'fatMass':
        return 'كتلة الدهون';
      case 'waterPercentage':
        return 'نسبة الماء';
      case 'protein':
        return 'البروتين';
      case 'minerals':
        return 'المعادن';
      case 'calorie':
      case 'calories':
        return 'السعرات الحرارية';
      case 'steps':
        return 'الخطوات';
      case 'aerobicSteps':
        return 'الخطوات الهوائية';
      case 'distance':
        return 'المسافة';
      case 'wheezeDetected':
        return 'الصفير التنفسي';
      case 'systolic':
        return 'الضغط الانقباضي';
      case 'diastolic':
        return 'الضغط الانبساطي';
      case 'pulse':
        return 'النبض';
      case 'weight':
        return 'الوزن';
      case 'bmi':
        return 'مؤشر كتلة الجسم';
      case 'temperature':
        return 'درجة الحرارة';
      case 'spo2':
        return 'تشبع الأكسجين';
      case 'heartRate':
        return 'معدل ضربات القلب';
      case 'glucoseLevel':
        return 'سكر الدم';
      default:
        return key;
    }
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
