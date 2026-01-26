import 'package:flutter/material.dart';
import '../../sm_flutter_health_devices.dart';

/// Configuration for SmHealthDeviceWidget
/// Allows customization of UI strings, colors, behavior, and advanced styling.
class SmDeviceConfig {
  // --- Core Colors & Style ---

  /// Primary color for the widget (icons, progress bar user, buttons).
  /// If null, uses Theme.of(context).primaryColor
  final Color? primaryColor;

  /// Background color for the widget.
  /// If null, uses Theme.of(context).scaffoldBackgroundColor
  final Color? backgroundColor;

  /// General text color.
  /// If null, uses Theme.of(context).textTheme.bodyLarge?.color
  final Color? textColor;

  /// Secondary text color (for messages/subtitles).
  /// If null, uses textColor with opacity.
  final Color? secondaryTextColor;

  /// Global border radius for cards, buttons, and containers.
  final double borderRadius;

  // --- AppBar ---

  /// Whether to show the AppBar (use false if embedding in another page).
  final bool showAppBar;

  /// Title displayed in AppBar or top of widget.
  final String? title;

  /// Style for the title text.
  final TextStyle? titleTextStyle;

  // --- Iconography ---

  /// Custom icon widget to display. If null, a default icon based on [MeasurementType] is used.
  /// This takes precedence over default device icons.
  final Widget? customIcon;

  /// Size of the status icon. Default is 60.
  final double iconSize;

  /// Decoration for the container surrounding the status icon.
  /// If null, a default circular decoration using [primaryColor] with opacity is used.
  final BoxDecoration? iconContainerDecoration;

  // --- Start / Text Styles ---

  /// Text displayed while scanning for devices.
  final String scanningText;

  /// Text displayed while connecting.
  final String connectingText;

  /// Text displayed while measuring.
  final String measuringText;

  /// Style for the main status text (e.g. "Scanning...").
  final TextStyle? statusTextStyle;

  /// Style for secondary messages (e.g. error messages or connection details).
  final TextStyle? messageTextStyle;

  /// Style for the progress percentage/value text.
  final TextStyle? progressTextStyle;

  // --- Buttons ---

  /// Text for the cancel button.
  final String cancelButtonText;

  /// Text for the retry button.
  final String retryButtonText;

  /// Custom style for the Cancel button.
  final ButtonStyle? cancelButtonStyle;

  /// Custom style for the Retry button.
  final ButtonStyle? retryButtonStyle;

  // --- Progress Bar ---

  /// Color of the filled portion of the progress bar.
  /// Defaults to [primaryColor].
  final Color? progressColor;

  /// Color of the background track of the progress bar.
  /// Defaults to [primaryColor] with low opacity.
  final Color? progressBackgroundColor;

  /// Stroke width / height of the progress bar. Default is 12.0.
  final double progressStrokeWidth;

  // --- Behavior ---

  /// Automatically start scanning when the widget builds.
  final bool autoStartScan;

  /// Whether to show a detailed success dialog on completion.
  /// If false, simply triggers onResult callback.
  final bool showResultDialog;

  /// Animation duration for UI transitions.
  final Duration animationDuration;

  // --- Success View Buttons ---

  /// Text for the "Done" / "Save" button in the success view.
  final String successSaveText;

  /// Text for the "Retry" button in the success view.
  final String successRetryText;

  /// Style for the "Done" / "Save" button in the success view.
  final ButtonStyle? successSaveButtonStyle;

  /// Style for the "Retry" button in the success view.
  final ButtonStyle? successRetryButtonStyle;

  const SmDeviceConfig({
    this.primaryColor,
    this.backgroundColor,
    this.textColor,
    this.secondaryTextColor,
    this.borderRadius = 16.0,
    this.showAppBar = true,
    this.title,
    this.titleTextStyle,
    this.customIcon,
    this.iconSize = 60.0,
    this.iconContainerDecoration,
    this.scanningText = 'Scanning for devices...',
    this.connectingText = 'Connecting...',
    this.measuringText = 'Measuring...',
    this.statusTextStyle,
    this.messageTextStyle,
    this.progressTextStyle,
    this.cancelButtonText = 'Cancel',
    this.retryButtonText = 'Retry',
    this.cancelButtonStyle,
    this.retryButtonStyle,
    // Success Button Defaults
    this.successSaveText = 'Save',
    this.successRetryText = 'Retry',
    this.successSaveButtonStyle,
    this.successRetryButtonStyle,
    this.progressColor,
    this.progressBackgroundColor,
    this.progressStrokeWidth = 12.0,
    this.autoStartScan = true,
    this.showResultDialog = false,
    this.animationDuration = const Duration(milliseconds: 300),
  });
}
