import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prijavko/core/capture/capture_preference.dart';
import 'package:prijavko/core/capture/capture_preference_store.dart';
import 'package:prijavko/core/permissions/permission_service_impl.dart';
import 'package:prijavko/design/icons.dart';
import 'package:prijavko/design/tokens.dart';
import 'package:prijavko/l10n/app_localizations.dart';

/// Camera permission request screen — second step of the linear onboarding flow.
///
/// Presents the camera rationale before the OS dialog fires (FilledButton path)
/// and provides a hard skip (OutlinedButton) that writes manualOnly and proceeds.
///
/// WHY ConsumerStatefulWidget (not ConsumerWidget): requestCamera() shows the
/// OS dialog — an async gap during which the user can rotate, switch apps, or
/// trigger navigation. State.mounted is the robust guard for this.
/// Mirrors WelcomeScreen's ConsumerStatefulWidget choice for lifecycle
/// consistency across onboarding screens.
class CameraPermissionScreen extends ConsumerStatefulWidget {
  const CameraPermissionScreen({super.key});

  @override
  ConsumerState<CameraPermissionScreen> createState() =>
      _CameraPermissionScreenState();
}

class _CameraPermissionScreenState
    extends ConsumerState<CameraPermissionScreen> {
  // WHY: both handlers are async (OS dialog + disk write). Without this guard,
  // a double-tap fires concurrent executions — two requestCamera() calls and
  // two goNamed() calls on the same navigation stack.
  bool _isInFlight = false;

  Future<void> _onAllow() async {
    if (_isInFlight) return;
    setState(() => _isInFlight = true);

    try {
      final permService = ref.read(permissionServiceProvider);
      final prefStore = ref.read(capturePreferenceStoreProvider);

      final granted = await permService.requestCamera();

      // WHY mounted check: OS dialog is an async gap — user may navigate away
      // or rotate during it. Calling goNamed() on an unmounted widget would
      // throw or silently corrupt the navigation stack.
      if (!mounted) return;

      if (!granted) {
        final permanentlyDenied = await permService.isCameraPermanentlyDenied();
        if (!mounted) return;
        if (permanentlyDenied) {
          // WHY SnackBar + stay: when permanently denied, the OS returns false
          // immediately with no dialog — looks like a broken button to the user.
          // SnackBar explains and offers a direct path to Settings. The user
          // proceeds via "Preskoči — ručni unos" which saves manualOnly.
          final l10n = AppLocalizations.of(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.cameraPermissionPermanentlyDeniedMessage),
              action: SnackBarAction(
                label: l10n.cameraPermissionOpenSettingsButton,
                onPressed: () => permService.openSettings(),
              ),
            ),
          );
          return;
        }
      }

      try {
        await prefStore.save(
          granted ? CapturePreference.live : CapturePreference.manualOnly,
        );
      } catch (_) {
        // Preference persistence failure is non-fatal — manualOnly is the safe
        // default on next load. Log when AppLogger lands (Story 9.1).
      }

      if (!mounted) return;
      context.goNamed('login');
    } finally {
      if (mounted) setState(() => _isInFlight = false);
    }
  }

  Future<void> _onSkip() async {
    if (_isInFlight) return;
    setState(() => _isInFlight = true);

    try {
      final prefStore = ref.read(capturePreferenceStoreProvider);
      try {
        await prefStore.save(CapturePreference.manualOnly);
      } catch (_) {
        // Non-fatal — manualOnly is the safe default on next load. Log Story 9.1.
      }
      if (!mounted) return;
      context.goNamed('login');
    } finally {
      if (mounted) setState(() => _isInFlight = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      // WHY no AppBar: full-screen onboarding — WelcomeScreen is behind via
      // context.go (not push), so back-stack is empty. Same as WelcomeScreen.
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: TokensSpace.s16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: TokensSpace.s64),
                      // WHY ExcludeSemantics: the icon is decorative — the
                      // headline Text immediately below announces the same
                      // label. Including a Semantics label here causes screen
                      // readers to announce the heading twice in succession.
                      ExcludeSemantics(
                        child: Icon(
                          Symbols.photo_camera_rounded,
                          size: 64,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: TokensSpace.s24),
                      Text(
                        l10n.cameraPermissionHeadline,
                        style: theme.textTheme.displayMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: TokensSpace.s16),
                      Text(
                        l10n.cameraPermissionBody,
                        style: theme.textTheme.bodyLarge,
                        textAlign: TextAlign.start,
                      ),
                      const SizedBox(height: TokensSpace.s32),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                left: TokensSpace.s16,
                right: TokensSpace.s16,
                top: TokensSpace.s16,
                // WHY s24 bottom: gesture inset per UX spec §Standard Screen
                // Skeleton — keeps buttons clear of the Android gesture bar.
                bottom: TokensSpace.s24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton(
                    onPressed: _isInFlight ? null : _onAllow,
                    child: Text(l10n.cameraPermissionAllowButton),
                  ),
                  const SizedBox(height: TokensSpace.s12),
                  OutlinedButton(
                    onPressed: _isInFlight ? null : _onSkip,
                    child: Text(l10n.cameraPermissionSkipButton),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
