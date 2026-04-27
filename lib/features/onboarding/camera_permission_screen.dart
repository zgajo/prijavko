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
  Future<void> _onAllow() async {
    final permService = ref.read(permissionServiceProvider);
    final prefStore = ref.read(capturePreferenceStoreProvider);

    final granted = await permService.requestCamera();

    // WHY mounted check: OS dialog is an async gap — user may navigate away
    // or rotate during it. Calling context.go() on an unmounted widget
    // would throw or silently corrupt the navigation stack.
    if (!mounted) return;

    await prefStore.save(
      granted ? CapturePreference.live : CapturePreference.manualOnly,
    );

    if (!mounted) return;
    context.go('/onboarding/login');
  }

  Future<void> _onSkip() async {
    final prefStore = ref.read(capturePreferenceStoreProvider);
    await prefStore.save(CapturePreference.manualOnly);
    if (!mounted) return;
    context.go('/onboarding/login');
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
                      Semantics(
                        label: l10n.cameraPermissionHeadline,
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
                    onPressed: _onAllow,
                    child: Text(l10n.cameraPermissionAllowButton),
                  ),
                  const SizedBox(height: TokensSpace.s12),
                  OutlinedButton(
                    onPressed: _onSkip,
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
