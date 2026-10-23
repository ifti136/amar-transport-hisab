import 'formatters.dart';

/// Money value stored as integer paisa (1 BDT = 100 paisa).
/// Never use [double] for money calculations.
class Money implements Comparable<Money> {
  final int _paisa;

  const Money._(this._paisa);

  /// Creates a [Money] from paisa (integer).
  factory Money.paisa(int paisa) => Money._(paisa);

  /// Creates a [Money] from taka (may have decimals).
  /// [taka] can be int, double, or string like "123.45".
  factory Money.fromTaka(num taka) => Money._((taka * 100).round());

  /// Creates a [Money] from a string input (Bengali or Latin digits, with commas).
  /// Returns null if parsing fails.
  static Money? tryParse(String input) {
    final result = parseMoneyInput(input);
    return result.isSuccess ? result.value : null;
  }

  /// The value in paisa (1/100 of a Taka).
  int get paisa => _paisa;

  /// The value in taka as a double (for display only, not for calculation).
  double get taka => _paisa / 100.0;

  /// Whether the value is zero.
  bool get isZero => _paisa == 0;

  /// Whether the value is positive.
  bool get isPositive => _paisa > 0;

  /// Whether the value is negative.
  bool get isNegative => _paisa < 0;

  /// Absolute value.
  Money get abs => Money._(_paisa.abs());

  /// Negated value.
  Money get negated => Money._(-_paisa);

  /// Addition.
  Money operator +(Money other) => Money._(_paisa + other._paisa);

  /// Subtraction.
  Money operator -(Money other) => Money._(_paisa - other._paisa);

  /// Multiplication by a scalar (int).
  Money operator *(int scalar) => Money._(_paisa * scalar);

  /// Division by a scalar (int), rounded.
  Money operator ~/(int scalar) => Money._(_paisa ~/ scalar);

  /// Division by a scalar (double), rounded.
  Money operator /(double scalar) => Money._((_paisa / scalar).round());

  @override
  int compareTo(Money other) => _paisa.compareTo(other._paisa);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Money && _paisa == other._paisa;

  @override
  int get hashCode => _paisa.hashCode;

  @override
  String toString() => 'Money(paisa: $_paisa, taka: $taka)';

  /// Returns a new [Money] with the same value (for chaining).
  Money get copyWith => Money._(_paisa);
}

/// Result type for parsing operations.
sealed class Result<T, E> {
  const Result();

  bool get isSuccess => this is Success<T, E>;
  bool get isFailure => this is Failure<T, E>;

  T get value {
    if (this is Success<T, E>) return (this as Success<T, E>).value;
    throw StateError('Result is a failure');
  }

  E get error {
    if (this is Failure<T, E>) return (this as Failure<T, E>).error;
    throw StateError('Result is a success');
  }
}

class Success<T, E> extends Result<T, E> {
  final T value;
  const Success(this.value);
}

class Failure<T, E> extends Result<T, E> {
  final E error;
  const Failure(this.error);
}