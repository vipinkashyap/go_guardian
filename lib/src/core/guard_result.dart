/// Result of a guard evaluation, used in [GuardEvent]s for debugging.
///
/// You'll see these in [GuardCheckCompleted] and [GuardChainCompleted] events
/// when using [DebugGuardObserver] or a custom [GuardObserver].
///
/// - [AllowResult] — guard passed, navigation permitted
/// - [RedirectResult] — guard denied access, redirecting
/// - [LoadingResult] — async guard still resolving
/// - [BlockResult] — guard blocked with a reason (no redirect)
sealed class GuardResult {
  const GuardResult();

  /// Guard passed — permit navigation.
  const factory GuardResult.allow() = AllowResult;

  /// Redirect to a different path.
  const factory GuardResult.redirect(String path) = RedirectResult;

  /// Guard is loading async state — show loading UI.
  const factory GuardResult.loading({String? message}) = LoadingResult;

  /// Deny navigation with a reason (logged but no redirect).
  const factory GuardResult.block(String reason) = BlockResult;

  /// Convert to a redirect path for GoRouter compatibility.
  ///
  /// - [AllowResult] → `null`
  /// - [RedirectResult] → the redirect path
  /// - [LoadingResult] → [loadingPath] (defaults to `null`)
  /// - [BlockResult] → `null` (blocked, but no redirect target)
  String? toRedirectPath({String? loadingPath}) {
    return switch (this) {
      AllowResult() => null,
      RedirectResult(:final path) => path,
      LoadingResult() => loadingPath,
      BlockResult() => null,
    };
  }

  /// Whether this result allows navigation.
  bool get isAllowed => this is AllowResult;

  /// Whether this result denies navigation (redirect or block).
  bool get isDenied => this is RedirectResult || this is BlockResult;
}

/// Guard passed — permit navigation.
class AllowResult extends GuardResult {
  const AllowResult();

  @override
  String toString() => 'GuardResult.allow()';
}

/// Redirect to a different path.
class RedirectResult extends GuardResult {
  const RedirectResult(this.path);

  /// The path to redirect to.
  final String path;

  @override
  String toString() => 'GuardResult.redirect($path)';
}

/// Guard is loading async state.
class LoadingResult extends GuardResult {
  const LoadingResult({this.message});

  /// Optional message to display while loading.
  final String? message;

  @override
  String toString() => 'GuardResult.loading(${message ?? ""})';
}

/// Deny navigation with a reason.
class BlockResult extends GuardResult {
  const BlockResult(this.reason);

  /// Human-readable reason for the block.
  final String reason;

  @override
  String toString() => 'GuardResult.block($reason)';
}
