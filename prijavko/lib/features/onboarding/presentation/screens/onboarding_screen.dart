import 'package:flutter/material.dart';

import 'package:prijavko/core/l10n/context_l10n.dart';
import 'package:prijavko/shared/widgets/prijavko_scaffold.dart';

/// Placeholder until Epic 2 facility onboarding (CRUD + full UX).
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PrijavkoScaffold(
      body: Center(
        child: Text(
          context.l10n.onboardingHeadline,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
    );
  }
}
