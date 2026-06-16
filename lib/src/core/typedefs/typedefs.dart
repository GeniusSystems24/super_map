// ============================================================
// core/typedefs/typedefs.dart
// ------------------------------------------------------------
// Project-wide type aliases. Keeps signatures terse and intent obvious.
// ============================================================

import '../errors/failures.dart';

/// A JSON object as decoded by `dart:convert`.
typedef Json = Map<String, dynamic>;

/// A JSON list.
typedef JsonList = List<dynamic>;

/// The result of an operation that can fail: either a [Failure] (left) or a
/// value of type [T] (right). A lightweight, dependency-free Either.
typedef Result<T> = ({Failure? failure, T? value});

/// A synchronous validator returning an error message, or null when valid.
typedef Validator<T> = String? Function(T value);

/// A row-aware validator: the value plus the whole row it belongs to.
typedef RowValidator<T> = String? Function(String value, T row);

/// Reports a field's validity to a host (true == valid).
typedef ValidityChanged = void Function(bool valid);
