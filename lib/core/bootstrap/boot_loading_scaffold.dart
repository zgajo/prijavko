// WHY extracted: both ConsentGate and BootGate show an identical transient
// loading surface during their async windows (~50ms each on cold start). A
// shared widget prevents pixel divergence between the two loading states — the
// user should see a seamless loading experience, not two slightly different
// spinners. The surface carries no PII, no locale-dependent strings, and no
// AppBar (sub-50ms transient; an AppBar would flash and vanish — Muri).
//
// i18n-ignore: no user-facing strings (semanticsLabel matches ConsentGate's
// existing 'Loading' label — same TalkBack surface, no ARB churn).
import 'package:flutter/material.dart';

class BootLoadingScaffold extends StatelessWidget {
  const BootLoadingScaffold({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: const Center(
        child: CircularProgressIndicator(semanticsLabel: 'Loading'),
      ),
    );
  }
}
