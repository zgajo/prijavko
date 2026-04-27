// WHY ConsumerStatefulWidget: holds two TextEditingControllers, two FocusNodes,
// and the password-visibility toggle's bool _obscure — all lifecycle objects
// requiring dispose(). Mirrors welcome_screen.dart and
// camera_permission_screen.dart patterns.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prijavko/core/errors/app_error.dart';
import 'package:prijavko/core/result/result.dart';
import 'package:prijavko/core/security/window_secure_flag.dart';
import 'package:prijavko/design/icons.dart';
import 'package:prijavko/design/tokens.dart';
import 'package:prijavko/features/auth/login_failure.dart';
import 'package:prijavko/features/auth/login_notifier.dart';
import 'package:prijavko/features/auth/login_state.dart';
import 'package:prijavko/features/settings/credential_store.dart';
import 'package:prijavko/l10n/app_localizations.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key, this.replaceMode = false});

  final bool replaceMode;

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameFocus = FocusNode();
  final _passwordFocus = FocusNode();
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    // WHY no paused→disable lifecycle hook: FLAG_SECURE is per-window and does
    // not propagate to subsequent screens. Clearing it on `paused` while the
    // LoginScreen is still mounted lets a later recents thumbnail capture the
    // password field. Keep the flag active for the whole screen lifecycle.
    WindowSecureFlag.enable();
    // Rebuild when text changes (to gate submit button).
    _usernameController.addListener(_onFieldChanged);
    _passwordController.addListener(_onFieldChanged);
    if (widget.replaceMode) {
      _hydrateUsernameFromKeystore();
    }
  }

  Future<void> _hydrateUsernameFromKeystore() async {
    final result = await ref.read(credentialStoreProvider).loadCredentials();
    if (!mounted) return;
    if (result is! Ok<Credentials, StorageError>) {
      // Err path is silently tolerated — the user re-types the username.
      // The next saveCredentials() will overwrite either way.
      return;
    }
    // WHY guard: cold Android Keystore reads can take 100ms+. If the user has
    // already started typing or focused either field, overwriting the input
    // and ripping focus to password is a Poka-yoke violation — keystrokes
    // disappear, focus jumps, host blames the app. Skip the hydration.
    final userIsInteracting =
        _usernameController.text.isNotEmpty ||
        _usernameFocus.hasFocus ||
        _passwordController.text.isNotEmpty ||
        _passwordFocus.hasFocus;
    if (userIsInteracting) return;

    _usernameController.text = result.value.username;
    // WHY focus password (not username): username is pre-filled and
    // immutable in this flow's mental model — the host is *changing
    // password*, not username. Auto-focusing password matches the
    // typical "your username, new password" UX pattern (banking apps,
    // 2FA flows). The user can still edit username; we just do not
    // assume they want to.
    _passwordFocus.requestFocus();
  }

  @override
  void dispose() {
    WindowSecureFlag.disable();
    _usernameController.dispose();
    _passwordController.dispose();
    _usernameFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _onFieldChanged() {
    // AC5.1: `LoginIdle.error` is "cleared when fields change". Notifier
    // ignores the call when the current state has no error.
    ref.read(loginNotifierProvider.notifier).clearError();
    setState(() {});
  }

  Future<void> _maybeSubmit() async {
    final result = await ref
        .read(loginNotifierProvider.notifier)
        .submit(
          username: _usernameController.text,
          password: _passwordController.text,
        );

    if (!mounted) return;

    if (result is Ok) {
      if (widget.replaceMode) {
        // WHY pop(true) when canPop: back-stack already has /settings
        // underneath. pop is go_router's documented idiom for "return result
        // to parent"; goNamed would push a duplicate /settings on every
        // successful re-entry — a slow stack leak.
        // WHY canPop fallback to /home: a deep link directly to
        // /settings/replace-credentials lands with a shallow stack — pop
        // would either no-op or eject the host to the launcher. goNamed
        // /home is the safe terminal for replace-mode success.
        if (context.canPop()) {
          context.pop(true);
        } else {
          context.goNamed('home');
        }
      } else {
        context.goNamed('home');
      }
    }
    // Err path: state already updated by notifier — UI rebuild handles it.
  }

  bool get _canSubmit {
    final state = ref.read(loginNotifierProvider);
    if (state is LoginSubmitting || state is LoginLockedOut) return false;
    if (_usernameController.text.isEmpty) return false;
    if (_passwordController.text.isEmpty) return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final state = ref.watch(loginNotifierProvider);
    final isDisabled = state is LoginSubmitting || state is LoginLockedOut;

    return Scaffold(
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: TokensSpace.s64),
                      if (widget.replaceMode) ...[
                        // WHY plain Container (not MaterialBanner): MaterialBanner
                        // is reserved for transient system-level recovery messages
                        // (Epic 2 Story 2.7 CredentialBanner). Re-entry is a
                        // host-initiated flow, not a system event — a neutral
                        // surfaceContainerHigh panel is the correct affordance.
                        // WHY Symbols.info_rounded (not warning): this is
                        // informational — facility/queue preservation is a
                        // positive reassurance (UX-DR24 shape redundancy).
                        Container(
                          padding: const EdgeInsets.all(TokensSpace.s12),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(
                              TokensSpace.s12,
                            ),
                            border: Border.all(
                              color: colorScheme.outlineVariant,
                            ),
                          ),
                          child: Row(
                            children: [
                              // WHY ExcludeSemantics: the banner is decorative.
                              // Without exclusion, TalkBack reads "info" before
                              // the banner text, doubling the cognitive load.
                              const ExcludeSemantics(
                                child: Icon(Symbols.info_rounded, size: 20),
                              ),
                              const SizedBox(width: TokensSpace.s12),
                              Expanded(
                                child: Text(
                                  l10n.replaceCredentialsBanner,
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: TokensSpace.s24),
                      ],
                      Text(
                        l10n.loginHeadline,
                        style: theme.textTheme.displayMedium,
                      ),
                      const SizedBox(height: TokensSpace.s24),
                      Text(l10n.loginBody, style: theme.textTheme.bodyLarge),
                      const SizedBox(height: TokensSpace.s32),
                      TextField(
                        controller: _usernameController,
                        focusNode: _usernameFocus,
                        autofillHints: const [AutofillHints.username],
                        keyboardType: TextInputType.text,
                        textInputAction: TextInputAction.next,
                        enabled: !isDisabled,
                        decoration: InputDecoration(
                          labelText: l10n.loginUsernameLabel,
                        ),
                      ),
                      const SizedBox(height: TokensSpace.s16),
                      TextField(
                        controller: _passwordController,
                        focusNode: _passwordFocus,
                        obscureText: _obscure,
                        autofillHints: const [AutofillHints.password],
                        textInputAction: TextInputAction.done,
                        enabled: !isDisabled,
                        onSubmitted: (_) {
                          if (_canSubmit) _maybeSubmit();
                        },
                        decoration: InputDecoration(
                          labelText: l10n.loginPasswordLabel,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscure
                                  ? Symbols.visibility_rounded
                                  : Symbols.visibility_off_rounded,
                            ),
                            tooltip: _obscure
                                ? l10n.loginPasswordToggleShow
                                : l10n.loginPasswordToggleHide,
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                          ),
                        ),
                      ),
                      const SizedBox(height: TokensSpace.s16),
                      Text(
                        l10n.loginReassurance,
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(height: TokensSpace.s16),
                      _buildErrorOrLockoutBlock(state, l10n, colorScheme),
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
                // Skeleton — keeps button clear of the Android gesture bar.
                bottom: TokensSpace.s24,
              ),
              child: FilledButton(
                onPressed: _canSubmit ? _maybeSubmit : null,
                child: state is LoginSubmitting
                    ? SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: colorScheme.onPrimary,
                        ),
                      )
                    // WHY different label in replace mode: "Prijavi se" implies
                    // first-time login; "Spremi nove podatke" matches the host's
                    // mental model of replacing, not signing in.
                    : Text(
                        widget.replaceMode
                            ? l10n.replaceCredentialsSubmitButton
                            : l10n.loginSubmitButton,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorOrLockoutBlock(
    LoginState state,
    AppLocalizations l10n,
    ColorScheme colorScheme,
  ) {
    if (state is LoginLockedOut) {
      final seconds = state.retryAfter
          .difference(DateTime.now())
          .inSeconds
          .clamp(0, 360);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.loginLockoutMessage,
            style: TextStyle(color: colorScheme.error),
          ),
          const SizedBox(height: TokensSpace.s4),
          Text(
            l10n.loginLockoutCountdownSeconds(seconds),
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: colorScheme.error),
          ),
        ],
      );
    }

    if (state is LoginIdle && state.error != null) {
      return Text(
        _errorMessage(state.error!, l10n),
        style: TextStyle(color: colorScheme.error),
      );
    }

    return const SizedBox.shrink();
  }

  String _errorMessage(LoginFailure failure, AppLocalizations l10n) {
    return switch (failure) {
      CredentialsInvalid(:final userMessage) =>
        (userMessage != null && userMessage.isNotEmpty)
            ? '$userMessage\n${l10n.loginCredentialsHint}'
            : l10n.loginCredentialsHint,
      NetworkUnreachable() => l10n.loginNetworkError,
      ServerError() => l10n.loginServerError,
      ContractBreak() => l10n.loginContractBreakError,
      // AccountLockedOut is handled by the lockout block above, but exhaustive
      // switch requires coverage.
      AccountLockedOut() => l10n.loginLockoutMessage,
    };
  }
}
