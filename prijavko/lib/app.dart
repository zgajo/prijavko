import 'package:flutter/material.dart';

import 'core/theme/theme.dart';

/// Root widget; does not perform platform initialization (see [main]).
class PrijavkoApp extends StatelessWidget {
  const PrijavkoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Prijavko',
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: ThemeMode.system,
      home: Scaffold(
        appBar: AppBar(title: const Text('Prijavko')),
        body: const Center(child: Text('Prijavko')),
      ),
    );
  }
}
