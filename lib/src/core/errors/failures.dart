// ============================================================
// core/errors/failures.dart
// ------------------------------------------------------------
// Failure + Exception base types. Datasources throw `SuperException`s; the
// repository layer catches them and returns `Failure`s up to the domain.
// ============================================================

import 'package:flutter/foundation.dart';

/// Base type for a recoverable failure surfaced to the domain / presentation.
@immutable
sealed class Failure {
  const Failure(this.message, {this.cause});

  /// Human-readable, operator-facing message.
  final String message;

  /// The originating error, if any (for logging).
  final Object? cause;

  @override
  String toString() => '$runtimeType($message)';
}

/// A failure originating from a local data source (file read, parse, cache).
final class CacheFailure extends Failure {
  const CacheFailure(super.message, {super.cause});
}

/// A failure originating from a remote data source (network, async fetch).
final class RemoteFailure extends Failure {
  const RemoteFailure(super.message, {super.cause});
}

/// A validation failure (bad input, constraint violation).
final class ValidationFailure extends Failure {
  const ValidationFailure(super.message, {super.cause});
}

/// An unexpected / unclassified failure.
final class UnexpectedFailure extends Failure {
  const UnexpectedFailure(super.message, {super.cause});
}

// ── Exceptions (thrown by datasources, caught by repositories) ───────────────

/// Base type for exceptions thrown inside the data layer.
@immutable
sealed class SuperException implements Exception {
  const SuperException(this.message, {this.cause});
  final String message;
  final Object? cause;

  @override
  String toString() => '$runtimeType($message)';
}

final class CacheException extends SuperException {
  const CacheException(super.message, {super.cause});
}

final class RemoteException extends SuperException {
  const RemoteException(super.message, {super.cause});
}
