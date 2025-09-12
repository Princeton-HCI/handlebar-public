/// A functional programming pattern for handling success and failure states,
/// providing type-safe error handling without throwing exceptions.
sealed class Result<T, E> {
  const Result();

  bool get isSuccess => this is Success<T, E>;
  bool get isFailure => this is Failure<T, E>;

  T? get valueOrNull => isSuccess ? (this as Success<T, E>).value : null;
  E? get errorOrNull => isFailure ? (this as Failure<T, E>).error : null;

  R fold<R>({
    required R Function(T value) onSuccess,
    required R Function(E error) onFailure,
  }) {
    return switch (this) {
      Success(:final value) => onSuccess(value),
      Failure(:final error) => onFailure(error),
    };
  }

  Result<R, E> map<R>(R Function(T value) transform) {
    return switch (this) {
      Success(:final value) => Success(transform(value)),
      Failure(:final error) => Failure(error),
    };
  }

  Result<T, R> mapError<R>(R Function(E error) transform) {
    return switch (this) {
      Success(:final value) => Success(value),
      Failure(:final error) => Failure(transform(error)),
    };
  }

  Future<Result<R, E>> flatMap<R>(
      Future<Result<R, E>> Function(T value) transform) async {
    return switch (this) {
      Success(:final value) => await transform(value),
      Failure(:final error) => Failure(error),
    };
  }
}

/// Represents a successful result containing a value of type T.
class Success<T, E> extends Result<T, E> {
  final T value;
  const Success(this.value);
}

/// Represents a failed result containing an error of type E.
class Failure<T, E> extends Result<T, E> {
  final E error;
  const Failure(this.error);
}

/// Represents an API error with message, status code, and original error details.
class ApiError {
  final String message;
  final int? statusCode;
  final dynamic originalError;

  const ApiError({
    required this.message,
    this.statusCode,
    this.originalError,
  });

  @override
  String toString() => 'ApiError(message: $message, statusCode: $statusCode)';
}
