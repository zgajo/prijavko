import 'package:freezed_annotation/freezed_annotation.dart';

part 'failure.freezed.dart';

/// Typed error surface for repositories; UI maps from [AsyncValue.error].
@freezed
sealed class Failure with _$Failure {
  const factory Failure.networkFailure() = NetworkFailure;

  const factory Failure.authFailure() = AuthFailure;

  const factory Failure.apiFailure(String userMessage) = ApiFailure;

  const factory Failure.validationFailure(Map<String, String> fields) =
      ValidationFailure;

  const factory Failure.storageFailure() = StorageFailure;
}
