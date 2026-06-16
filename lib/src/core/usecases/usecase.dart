// ============================================================
// core/usecases/usecase.dart
// ------------------------------------------------------------
// The base UseCase contract. A usecase is one business action — a single
// callable that the presentation layer invokes and the data layer fulfils,
// keeping the dependency arrow `presentation -> domain <- data`.
// ============================================================

import 'package:flutter/foundation.dart';

import '../typedefs/typedefs.dart';

/// A single business action producing a [Result] of [Type] from [Params].
///
/// ```dart
/// class SearchSuggestions implements UseCase<List<Suggestion>, String> {
///   const SearchSuggestions(this._repo);
///   final SuggestionRepository _repo;
///   @override
///   Future<Result<List<Suggestion>>> call(String query) => _repo.search(query);
/// }
/// ```
abstract interface class UseCase<Type, Params> {
  Future<Result<Type>> call(Params params);
}

/// A synchronous variant for pure, non-async actions.
abstract interface class SyncUseCase<Type, Params> {
  Result<Type> call(Params params);
}

/// Marker for usecases that take no arguments: `call(NoParams())`.
@immutable
class NoParams {
  const NoParams();
}
