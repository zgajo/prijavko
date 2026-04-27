import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:prijavko/app/app.dart';
import 'package:prijavko/app/providers.dart';
import 'package:prijavko/core/security/security_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  applyMainAppFontConfig();

  final securityService = SecurityService();
  // WHY: SecurityService loads the AES-GCM key once at startup — not lazily
  // on first use — so any flutter_secure_storage failure (Keystore unavailable,
  // corrupt entry) crashes visibly at launch rather than silently during a
  // guest submission at 2 AM. Jidoka: stop the line early.
  await securityService.init();

  final appDocDir = await getApplicationDocumentsDirectory();
  final cookieJarDir = '${appDocDir.path}/.evisitor_cookie_jar';

  runApp(
    ProviderScope(
      overrides: [
        securityServiceProvider.overrideWithValue(securityService),
        cookieJarDirectoryProvider.overrideWithValue(cookieJarDir),
      ],
      child: const PrijavkoApp(),
    ),
  );
}

// WHY: Manrope ships as bundled assets under assets/google_fonts/Manrope/
// (Story 1.2 AC8). Disabling runtime fetching turns a missing-asset bug
// into a loud startup exception in dev/CI rather than a silent CDN
// fallback that violates the offline-tolerant PRD NFR. Poka-yoke.
//
// Factored out of `main()` so `test/design/offline_fonts_test.dart` can
// exercise it directly — the only sanctioned way to drive the same
// initialization the production app performs.
void applyMainAppFontConfig() {
  GoogleFonts.config.allowRuntimeFetching = false;
}
