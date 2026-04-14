import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/app_config.dart';
import 'core/config/app_config_provider.dart';

/// Root widget; does not perform platform initialization (see [main]).
class PrijavkoApp extends ConsumerWidget {
  const PrijavkoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppConfig config = ref.watch(appConfigProvider);
    return MaterialApp(
      title: 'Prijavko',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      ),
      home: Scaffold(
        appBar: AppBar(title: const Text('Prijavko')),
        body: Center(
          child: Text(
            'API: ${config.apiBase}\nAds: ${config.adEnabled}',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
