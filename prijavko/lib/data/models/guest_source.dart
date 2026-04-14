/// Origin of guest row; maps Drift `source` column.
enum GuestSource {
  local(0),
  remote(1);

  const GuestSource(this.dbValue);

  final int dbValue;

  static GuestSource fromDbValue(int value) {
    for (final GuestSource s in GuestSource.values) {
      if (s.dbValue == value) {
        return s;
      }
    }
    throw ArgumentError.value(value, 'value', 'Unknown GuestSource db value');
  }
}
