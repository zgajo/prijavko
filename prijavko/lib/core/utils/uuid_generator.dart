import 'package:uuid/uuid.dart';

/// UUID v4 strings for eVisitor `ID` (lowercase with hyphens per wire examples).
abstract final class UuidGenerator {
  static const Uuid _uuid = Uuid();

  static String nextV4() => _uuid.v4();
}
