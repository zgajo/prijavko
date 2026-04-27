// WHY ConsumerStatefulWidget: the credential re-entry tile owns an in-flight
// `_navigating` flag to debounce double-taps. Without the flag, two rapid taps
// on slow Android hardware push two `replace-credentials` routes on top of
// each other — the second `pop(true)` returns to the first LoginScreen instead
// of /settings, and the SnackBar fires on the wrong screen. ConsumerWidget
// closures recreate per build so a stack-local bool would not persist.
// Promote further (e.g., to a Notifier) when Story 2.9 / 5.8 / 8.1 add
// additional async tiles that need the same debounce.
//
// WHY no FLAG_SECURE: the Settings list contains no PII or credential text.
// The replace-credentials sub-route (LoginScreen) sets FLAG_SECURE on its own.
// Adding FLAG_SECURE here would propagate to all future Settings sub-routes and
// create false dependencies.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prijavko/design/icons.dart';
import 'package:prijavko/design/tokens.dart';
import 'package:prijavko/l10n/app_localizations.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _navigating = false;

  Future<void> _onReplaceCredentialsTap() async {
    if (_navigating) return;
    _navigating = true;
    try {
      final updated = await context.pushNamed<bool>('replace-credentials');
      if (!mounted) return;
      if (updated == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).settingsCredentialsUpdatedSnackbar,
            ),
          ),
        );
      }
    } finally {
      if (mounted) _navigating = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: TokensSpace.s8),
        children: [
          ListTile(
            leading: const Icon(Symbols.lock_reset_rounded),
            title: Text(l10n.settingsReplaceCredentialsLabel),
            trailing: const Icon(Symbols.chevron_right_rounded),
            onTap: _onReplaceCredentialsTap,
          ),
        ],
      ),
    );
  }
}
