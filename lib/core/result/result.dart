// WHY: All repository and data-layer functions return Result<T, E> instead of
// throwing. Pattern-matching on Result at call sites makes the error path
// structurally impossible to forget (Poka-yoke). Dart 3 sealed exhaustive
// switch replaces the need for a Freezed union here.
sealed class Result<T, E> {
  const Result();
}

final class Ok<T, E> extends Result<T, E> {
  const Ok(this.value);
  final T value;
}

final class Err<T, E> extends Result<T, E> {
  const Err(this.error);
  final E error;
}
