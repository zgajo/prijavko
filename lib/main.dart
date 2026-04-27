import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  // WHY: Manrope ships as bundled assets under assets/google_fonts/Manrope/
  // (Story 1.2 AC8). Disabling runtime fetching turns a missing-asset bug
  // into a loud startup exception in dev/CI rather than a silent CDN
  // fallback that violates the offline-tolerant PRD NFR. Poka-yoke.
  GoogleFonts.config.allowRuntimeFetching = false;

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(body: Center(child: Text('Hello World!'))),
    );
  }
}
