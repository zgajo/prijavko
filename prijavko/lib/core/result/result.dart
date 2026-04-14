import 'package:freezed_annotation/freezed_annotation.dart';

import '../../data/models/failure.dart';

part 'result.freezed.dart';

/// Explicit success vs [Failure] for data-layer APIs (no thrown exceptions).
@freezed
sealed class Result<T> with _$Result<T> {
  const factory Result.success(T value) = ResultSuccess;

  const factory Result.failure(Failure failure) = ResultFailure;
}
