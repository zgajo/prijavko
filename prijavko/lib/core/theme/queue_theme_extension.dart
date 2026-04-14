import 'package:flutter/material.dart';

/// Semantic colors and icons for queue row / chip styling.
///
/// Domain mapping (for UI; tokens only in this story): ready → queued;
/// sending; failed + non-terminal → failed-retryable; failed + terminal →
/// failed-terminal; paused-auth (`tertiary`); sent (`primaryContainer`).
@immutable
class AppQueueTheme extends ThemeExtension<AppQueueTheme> {
  const AppQueueTheme({
    required this.queuedColor,
    required this.queuedIcon,
    required this.sendingColor,
    required this.sendingIcon,
    required this.failedRetryableColor,
    required this.failedRetryableIcon,
    required this.failedTerminalColor,
    required this.failedTerminalIcon,
    required this.pausedAuthColor,
    required this.pausedAuthIcon,
    required this.sentColor,
    required this.sentIcon,
  });

  /// Derives queue semantics from the active [ColorScheme] (seeded palette, no ad-hoc hex).
  factory AppQueueTheme.fromColorScheme(ColorScheme scheme) {
    return AppQueueTheme(
      queuedColor: scheme.secondary,
      queuedIcon: Icons.schedule,
      sendingColor: scheme.primary,
      sendingIcon: Icons.cloud_upload_outlined,
      failedRetryableColor: scheme.errorContainer,
      failedRetryableIcon: Icons.refresh,
      failedTerminalColor: scheme.error,
      failedTerminalIcon: Icons.block,
      pausedAuthColor: scheme.tertiary,
      pausedAuthIcon: Icons.lock_clock,
      sentColor: scheme.primaryContainer,
      sentIcon: Icons.check_circle,
    );
  }

  final Color queuedColor;
  final IconData queuedIcon;

  final Color sendingColor;
  final IconData sendingIcon;

  final Color failedRetryableColor;
  final IconData failedRetryableIcon;

  final Color failedTerminalColor;
  final IconData failedTerminalIcon;

  final Color pausedAuthColor;
  final IconData pausedAuthIcon;

  final Color sentColor;
  final IconData sentIcon;

  @override
  AppQueueTheme copyWith({
    Color? queuedColor,
    IconData? queuedIcon,
    Color? sendingColor,
    IconData? sendingIcon,
    Color? failedRetryableColor,
    IconData? failedRetryableIcon,
    Color? failedTerminalColor,
    IconData? failedTerminalIcon,
    Color? pausedAuthColor,
    IconData? pausedAuthIcon,
    Color? sentColor,
    IconData? sentIcon,
  }) {
    return AppQueueTheme(
      queuedColor: queuedColor ?? this.queuedColor,
      queuedIcon: queuedIcon ?? this.queuedIcon,
      sendingColor: sendingColor ?? this.sendingColor,
      sendingIcon: sendingIcon ?? this.sendingIcon,
      failedRetryableColor: failedRetryableColor ?? this.failedRetryableColor,
      failedRetryableIcon: failedRetryableIcon ?? this.failedRetryableIcon,
      failedTerminalColor: failedTerminalColor ?? this.failedTerminalColor,
      failedTerminalIcon: failedTerminalIcon ?? this.failedTerminalIcon,
      pausedAuthColor: pausedAuthColor ?? this.pausedAuthColor,
      pausedAuthIcon: pausedAuthIcon ?? this.pausedAuthIcon,
      sentColor: sentColor ?? this.sentColor,
      sentIcon: sentIcon ?? this.sentIcon,
    );
  }

  @override
  AppQueueTheme lerp(ThemeExtension<AppQueueTheme>? other, double t) {
    if (other is! AppQueueTheme) {
      return this;
    }
    final double tt = t.clamp(0.0, 1.0);
    Color lerpColor(Color a, Color b) => Color.lerp(a, b, tt)!;

    IconData lerpIcon(IconData a, IconData b) => tt < 0.5 ? a : b;

    return AppQueueTheme(
      queuedColor: lerpColor(queuedColor, other.queuedColor),
      queuedIcon: lerpIcon(queuedIcon, other.queuedIcon),
      sendingColor: lerpColor(sendingColor, other.sendingColor),
      sendingIcon: lerpIcon(sendingIcon, other.sendingIcon),
      failedRetryableColor: lerpColor(
        failedRetryableColor,
        other.failedRetryableColor,
      ),
      failedRetryableIcon: lerpIcon(
        failedRetryableIcon,
        other.failedRetryableIcon,
      ),
      failedTerminalColor: lerpColor(
        failedTerminalColor,
        other.failedTerminalColor,
      ),
      failedTerminalIcon: lerpIcon(
        failedTerminalIcon,
        other.failedTerminalIcon,
      ),
      pausedAuthColor: lerpColor(pausedAuthColor, other.pausedAuthColor),
      pausedAuthIcon: lerpIcon(pausedAuthIcon, other.pausedAuthIcon),
      sentColor: lerpColor(sentColor, other.sentColor),
      sentIcon: lerpIcon(sentIcon, other.sentIcon),
    );
  }
}
