/// Persisted guest lifecycle; [dbValue] is stable across reorderings.
enum GuestState {
  captured(0),
  confirmed(1),
  ready(2),
  sending(3),
  sent(4),
  failed(5),
  pausedAuth(6);

  const GuestState(this.dbValue);

  final int dbValue;

  static GuestState fromDbValue(int value) {
    for (final GuestState s in GuestState.values) {
      if (s.dbValue == value) {
        return s;
      }
    }
    throw ArgumentError.value(value, 'value', 'Unknown GuestState db value');
  }
}
