/// Uygulama genelinde Clean Architecture hata ve sonuc modelleri.
sealed class Failure {
  final String message;
  final Object? cause;

  const Failure(this.message, [this.cause]);

  @override
  String toString() => '$runtimeType: $message${cause != null ? ' (Neden: $cause)' : ''}';
}

class StorageFailure extends Failure {
  const StorageFailure([super.message = 'Yerel depolama islemi basarisiz oldu.', super.cause]);
}

class ValidationFailure extends Failure {
  const ValidationFailure([super.message = 'Gecersiz veri girisi yapildi.', super.cause]);
}

class FormatFailure extends Failure {
  const FormatFailure([super.message = 'Veri formati donusturulemedi.', super.cause]);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'Istenen kayit bulunamadi.', super.cause]);
}

/// Sonuc ve hata kapsullemesi (Result / Failure Pattern)
sealed class Result<S, E extends Failure> {
  const Result();

  const factory Result.success(S data) = Success<S, E>;
  const factory Result.failure(E failure) = Error<S, E>;

  bool get isSuccess => this is Success<S, E>;
  bool get isFailure => this is Error<S, E>;

  S? get dataOrNull => switch (this) {
        Success(data: final d) => d,
        Error() => null,
      };

  E? get failureOrNull => switch (this) {
        Success() => null,
        Error(failure: final f) => f,
      };

  R fold<R>({
    required R Function(S data) onSuccess,
    required R Function(E failure) onFailure,
  }) {
    return switch (this) {
      Success(data: final d) => onSuccess(d),
      Error(failure: final f) => onFailure(f),
    };
  }
}

class Success<S, E extends Failure> extends Result<S, E> {
  final S data;
  const Success(this.data);
}

class Error<S, E extends Failure> extends Result<S, E> {
  final E failure;
  const Error(this.failure);
}
