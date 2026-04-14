/// How guest identity was captured; [dbValue] is stable across reorderings.
enum CaptureTier {
  mrz(0),
  ocr(1),
  manual(2);

  const CaptureTier(this.dbValue);

  final int dbValue;

  static CaptureTier fromDbValue(int value) {
    for (final CaptureTier t in CaptureTier.values) {
      if (t.dbValue == value) {
        return t;
      }
    }
    throw ArgumentError.value(value, 'value', 'Unknown CaptureTier db value');
  }
}
