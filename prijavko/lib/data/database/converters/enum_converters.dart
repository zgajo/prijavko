import 'package:drift/drift.dart';

import '../../models/capture_tier.dart';
import '../../models/guest_source.dart';
import '../../models/guest_state.dart';

/// Stable int mapping for [GuestState] (see [GuestState.dbValue]).
class GuestStateConverter extends TypeConverter<GuestState, int> {
  const GuestStateConverter();

  @override
  GuestState fromSql(int fromDb) => GuestState.fromDbValue(fromDb);

  @override
  int toSql(GuestState value) => value.dbValue;
}

/// Stable int mapping for [CaptureTier].
class CaptureTierConverter extends TypeConverter<CaptureTier, int> {
  const CaptureTierConverter();

  @override
  CaptureTier fromSql(int fromDb) => CaptureTier.fromDbValue(fromDb);

  @override
  int toSql(CaptureTier value) => value.dbValue;
}

/// Stable int mapping for [GuestSource].
class GuestSourceConverter extends TypeConverter<GuestSource, int> {
  const GuestSourceConverter();

  @override
  GuestSource fromSql(int fromDb) => GuestSource.fromDbValue(fromDb);

  @override
  int toSql(GuestSource value) => value.dbValue;
}
