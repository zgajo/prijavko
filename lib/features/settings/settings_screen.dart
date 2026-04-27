// WHY ConsumerWidget (not ConsumerStatefulWidget): no lifecycle controllers,
// no streams to subscribe — the single async action lives in the tile's onTap
// callback. ConsumerWidget is the project default for all screens. Promote to
// ConsumerStatefulWidget when a future story (2.9 auth-state row, 5.8 Replace
// OIB) introduces lifecycle concerns such as a Drift stream subscription.
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

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            onTap: () async {
              final updated = await context.pushNamed<bool>(
                'replace-credentials',
              );
              if (!context.mounted) return;
              if (updated == true) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.settingsCredentialsUpdatedSnackbar),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
