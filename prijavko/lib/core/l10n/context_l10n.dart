import 'package:flutter/widgets.dart';

import 'app_localizations.dart';

extension ContextL10n on BuildContext {
  AppLocalizations get l10n {
    final value = AppLocalizations.of(this);
    assert(
      value != null,
      'No AppLocalizations found in context (missing localizationsDelegates?)',
    );
    return value!;
  }
}
