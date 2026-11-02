import 'app_failure.dart';

/// What a repository returns (§10.5): a value or a typed failure, never a thrown exception.
sealed class Result<T, F> {
  const Result();

  bool get isOk => this is Ok<T, F>;

  T? get valueOrNull => switch (this) {
    Ok(:final value) => value,
    Err() => null,
  };

  F? get failureOrNull => switch (this) {
    Ok() => null,
    Err(:final failure) => failure,
  };

  R fold<R>(R Function(T value) onOk, R Function(F failure) onErr) => switch (this) {
    Ok(:final value) => onOk(value),
    Err(:final failure) => onErr(failure),
  };

  Result<R, F> map<R>(R Function(T value) transform) => switch (this) {
    Ok(:final value) => Ok(transform(value)),
    Err(:final failure) => Err(failure),
  };
}

final class Ok<T, F> extends Result<T, F> {
  const Ok(this.value);

  final T value;
}

final class Err<T, F> extends Result<T, F> {
  const Err(this.failure);

  final F failure;
}

/// The repositories' result type.
typedef AppResult<T> = Result<T, AppFailure>;
