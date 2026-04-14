import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_database.dart';

/// Singleton [AppDatabase] — Drift owns the long-lived [QueryExecutor].
final appDatabaseProvider = Provider<AppDatabase>((Ref ref) => AppDatabase());
