import 'package:freezed_annotation/freezed_annotation.dart';

part 'scan_session.freezed.dart';

/// A capture session scoped to one facility.
@freezed
sealed class ScanSession with _$ScanSession {
  const factory ScanSession({
    required int id,
    required int facilityId,
    required DateTime startedAt,
    DateTime? endedAt,
    required int guestCount,
  }) = _ScanSession;
}
