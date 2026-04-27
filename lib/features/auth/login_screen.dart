// WHY ConsumerStatefulWidget: holds two TextEditingControllers, two FocusNodes,
// and the password-visibility toggle's bool _obscure — all lifecycle objects
// requiring dispose(). Mirrors welcome_screen.dart and
// camera_permission_screen.dart patterns.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prijavko/core/result/result.dart';
import 'package:prijavko/core/security/window_secure_flag.dart';
import 'package:prijavko/design/icons.dart';
import 'package:prijavko/design/tokens.dart';
import 'package:prijavko/features/auth/login_failure.dart';
import 'package:prijavko/features/auth/login_notifier.dart';
import 'package:prijavko/features/auth/login_state.dart';
import 'package:prijavko/l10n/app_localizations.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with WidgetsBindingObserver {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameFocus = FocusNode();
  final _passwordFocus = FocusNode();
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WindowSecureFlag.enable();
    // Rebuild when text changes (to gate submit button).
    _usernameController.addListener(_onFieldChanged);
    _passwordController.addListener(_onFieldChanged);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    WindowSecureFlag.disable();
    _usernameController.dispose();
    _passwordController.dispose();
    _usernameFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // WHY: clear FLAG_SECURE when backgrounded so subsequent non-credential
    // screens are not blocked from screenshot. Re-enable on resume while this
    // screen is still mounted.
    if (state == AppLifecycleState.paused) {
      WindowSecureFlag.disable();
    } else if (state == AppLifecycleState.resumed) {
      WindowSecureFlag.enable();
    }
  }

  void _onFieldChanged() => setState(() {});

  Future<void> _maybeSubmit() async {
    final result = await ref
        .read(loginNotifierProvider.notifier)
        .submit(
          username: _usernameController.text,
          password: _passwordController.text,
        );

    if (!mounted) return;

    if (result is Ok) {
      context.goNamed('home');
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
                    : Text(l10n.loginSubmitButton),
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
