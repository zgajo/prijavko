import 'package:flutter/material.dart';

import 'package:prijavko/core/l10n/context_l10n.dart';
import 'package:prijavko/shared/widgets/prijavko_scaffold.dart';

/// Epic 3 — full-screen capture flow placeholder.
class CaptureStubScreen extends StatelessWidget {
  const CaptureStubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PrijavkoScaffold(
      appBar: AppBar(title: Text(context.l10n.routeCapture)),
      body: Center(child: Text(context.l10n.routeCapture)),
    );
  }
}

/// Epic 3 — review step placeholder.
class ReviewStubScreen extends StatelessWidget {
  const ReviewStubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PrijavkoScaffold(
      appBar: AppBar(title: Text(context.l10n.routeReview)),
      body: Center(child: Text(context.l10n.routeReview)),
    );
  }
}

/// Epic 3 — confirm step placeholder.
class ConfirmStubScreen extends StatelessWidget {
  const ConfirmStubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PrijavkoScaffold(
      appBar: AppBar(title: Text(context.l10n.routeConfirm)),
      body: Center(child: Text(context.l10n.routeConfirm)),
    );
  }
}
