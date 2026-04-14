import 'package:freezed_annotation/freezed_annotation.dart';

import 'capture_tier.dart';
import 'guest_source.dart';
import 'guest_state.dart';

part 'guest.freezed.dart';

/// Domain guest row: eVisitor wire dates are [String] (YYYYMMDD / hh:mm); audit uses UTC [DateTime].
@freezed
sealed class Guest with _$Guest {
  const factory Guest({
    required int id,
    required String guid,
    required int facilityId,
    int? sessionId,
    required GuestState state,
    required CaptureTier captureTier,
    required GuestSource source,
    required String stayFromDate,
    required String stayFromTime,
    required String foreseenStayUntilDate,
    required String foreseenStayUntilTime,
    required String documentType,
    required String documentNumber,
    required String touristName,
    required String touristSurname,
    String? touristMiddleName,
    required String gender,
    required String countryOfBirth,
    required String cityOfBirth,
    required String dateOfBirth,
    required String citizenship,
    required String countryOfResidence,
    required String cityOfResidence,
    String? residenceAddress,
    String? touristEmail,
    String? touristTelephone,
    String? accommodationUnitType,
    required String ttPaymentCategory,
    required String arrivalOrganisation,
    required String offeredServiceType,
    String? borderCrossing,
    String? passageDate,
    String? eVisitorResponse,
    String? errorMessage,
    bool? isTerminalFailure,
    required DateTime createdAt,
    DateTime? confirmedAt,
    DateTime? submittedAt,
  }) = _Guest;
}
