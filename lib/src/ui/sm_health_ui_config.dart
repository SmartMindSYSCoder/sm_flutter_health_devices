import 'package:flutter/material.dart';

/// Configuration for SmHealthDeviceWidget Styling and core UI strings.
/// This configuration focuses on the overall "shell" of the widget (AppBar, Background).
/// Specific state rendering is handled by builders in the SmHealthDeviceWidget.
class SmHealthUiConfig {
  // --- Core Colors & Style ---

  /// Background color for the widget shell.
  /// If null, uses Theme.of(context).scaffoldBackgroundColor
  final Color? backgroundColor;

  /// Text color used for the default AppBar and core shell elements.
  /// If null, defaults to black or theme-appropriate color.
  final Color? textColor;

  // --- AppBar ---

  /// Whether to show the AppBar (use false if embedding in another page).
  final bool showAppBar;

  /// Title displayed in the default AppBar.
  /// If null, uses the [MeasurementType] display name.
  final String? title;

  /// Style for the title text in the default AppBar.
  final TextStyle? titleTextStyle;

  // --- Status Strings (Shell) ---

  /// Text displayed while scanning for devices.
  final String scanningText;

  /// Text displayed while connecting to a device.
  final String connectingText;

  // --- Transitions ---

  /// Animation duration for UI transitions (e.g. between builders).
  final Duration animationDuration;

  const SmHealthUiConfig({
    this.backgroundColor,
    this.textColor,
    this.showAppBar = true,
    this.title,
    this.titleTextStyle,
    this.scanningText = 'Scanning for devices...',
    this.connectingText = 'Connecting...',
    this.animationDuration = const Duration(milliseconds: 300),
  });
}
