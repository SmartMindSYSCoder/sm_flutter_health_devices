import 'package:flutter/material.dart';
import '../../sm_flutter_health_devices.dart';
import 'sm_omron_devices_page.dart';

/// Customization style for [SmHealthSettingsPage].
class SmHealthSettingsStyle {
  final String? title;
  final TextStyle? titleTextStyle;
  final Color? backgroundColor;
  final Color? cardColor;
  final Color? primaryColor;
  final Color? secondaryColor;
  final double cardElevation;
  final EdgeInsetsGeometry cardPadding;
  final ShapeBorder? cardShape;
  final TextStyle? measurementTitleStyle;
  final TextStyle? providerLabelStyle;
  final Color? selectedChipColor;
  final Color? unselectedChipColor;
  final Color? onSelectedChipColor;
  final double chipBorderRadius;

  const SmHealthSettingsStyle({
    this.title,
    this.titleTextStyle,
    this.backgroundColor,
    this.cardColor,
    this.primaryColor,
    this.secondaryColor,
    this.cardElevation = 0,
    this.cardPadding = const EdgeInsets.all(20),
    this.cardShape,
    this.measurementTitleStyle,
    this.providerLabelStyle,
    this.selectedChipColor,
    this.unselectedChipColor,
    this.onSelectedChipColor,
    this.chipBorderRadius = 12,
  });
}

/// A highly customizable Settings Page for health device provider selection.
/// This is part of the plugin UI and can be used directly in any application.
class SmHealthSettingsPage extends StatefulWidget {
  final SmHealthSettingsStyle style;

  const SmHealthSettingsPage({
    super.key,
    this.style = const SmHealthSettingsStyle(),
  });

  /// Static method to easily open the settings page.
  static Future<void> open(BuildContext context,
      {SmHealthSettingsStyle style = const SmHealthSettingsStyle()}) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SmHealthSettingsPage(style: style),
      ),
    );
  }

  @override
  State<SmHealthSettingsPage> createState() => _SmHealthSettingsPageState();
}

class _SmHealthSettingsPageState extends State<SmHealthSettingsPage> {
  final SmHealthDevices _healthDevices = SmHealthDevices();

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
    _healthDevices.init().then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final style = widget.style;

    if (!_healthDevices.isInitialized) {
      return Scaffold(
        backgroundColor: style.backgroundColor ?? colors.surface,
        appBar: AppBar(
          title: Text(style.title ?? 'Measurement Settings',
              style: style.titleTextStyle),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Reset to Defaults',
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
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          style.title ?? 'Settings',
          style: style.titleTextStyle ??
              const TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: Colors.white),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        iconTheme: style.primaryColor != null
            ? IconThemeData(color: style.primaryColor)
            : const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Reset to Defaults',
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
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              style.primaryColor?.withOpacity(0.8) ?? colors.primary,
              style.secondaryColor?.withOpacity(0.6) ?? colors.tertiary,
              colors.surface.withOpacity(0.95),
            ],
            stops: const [0.0, 0.4, 1.0],
          ),
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
                child: _buildOmronDevicesCard(colors, style),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 12),
                child: Text(
                  'Preferences',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white.withOpacity(0.9),
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
                  child: _buildMeasurementSettingCard(type, colors, style),
                );
              }),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool?> _showResetConfirmation(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset to Defaults?'),
        content: const Text(
            'This will reset all your preferred device providers to their default values.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  Widget _buildOmronDevicesCard(
      ColorScheme colors, SmHealthSettingsStyle style) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Material(
          color: Colors.transparent,
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            leading: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.bluetooth_searching_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
            title: const Text(
              'Omron Devices',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.white,
              ),
            ),
            subtitle: Text(
              'Manage your paired equipment',
              style:
                  TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13),
            ),
            trailing:
                const Icon(Icons.chevron_right_rounded, color: Colors.white70),
            onTap: () => SmOmronDevicesPage.open(context, style),
          ),
        ),
      ),
    );
  }

  Widget _buildMeasurementSettingCard(
      MeasurementType type, ColorScheme colors, SmHealthSettingsStyle style) {
    final currentProvider =
        _healthDevices.settingsManager.getPreferredProvider(type);
    final supportedProviders = type.supportedProviders;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    _getMeasurementIcon(type),
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  type.displayName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'PREFERRED PROVIDER',
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withOpacity(0.5),
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
                          ? Colors.white
                          : Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? Colors.white
                            : Colors.white.withOpacity(0.2),
                        width: 1.5,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: Colors.white.withOpacity(0.1),
                                blurRadius: 12,
                                spreadRadius: 0,
                              )
                            ]
                          : [],
                    ),
                    child: Text(
                      provider.displayName,
                      style: TextStyle(
                        color: isSelected ? Colors.black : Colors.white70,
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
