import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../meta/guard_meta.dart';

/// Base class for all route guards.
///
/// Extend this class to create custom guards that control access to routes.
/// Override [check] — return `null` to allow, or a redirect path to deny.
///
/// ```dart
/// class AuthGuard extends RouteGuard {
///   @override
///   int get priority => 10;
///
///   @override
///   FutureOr<String?> check(BuildContext context, GoRouterState state, GuardMeta meta) {
///     if (isLoggedIn) return null;  // allow
///     return '/login';              // redirect
///   }
/// }
/// ```
abstract class RouteGuard {
  /// Priority for guard evaluation order. Lower values run first.
  /// Default is 0.
  int get priority => 0;

  /// Check whether the route should be accessible.
  ///
  /// Returns `null` to allow access, or a redirect path string to deny.
  FutureOr<String?> check(
    BuildContext context,
    GoRouterState state,
    GuardMeta meta,
  );

  /// Combines this guard with [other] using AND logic.
  /// Both guards must pass (return null) for the route to be accessible.
  RouteGuard operator &(RouteGuard other) => _AndGuard(this, other);

  /// Combines this guard with [other] using OR logic.
  /// At least one guard must pass for the route to be accessible.
  RouteGuard operator |(RouteGuard other) => _OrGuard(this, other);

  /// Negates this guard. Passes when the original guard would redirect,
  /// and redirects to [redirectTo] when the original guard would pass.
  RouteGuard operator ~() => _NotGuard(this);
}

/// AND composition: both guards must pass.
class _AndGuard extends RouteGuard {
  _AndGuard(this._left, this._right);

  final RouteGuard _left;
  final RouteGuard _right;

  @override
  int get priority => _left.priority < _right.priority
      ? _left.priority
      : _right.priority;

  @override
  FutureOr<String?> check(
    BuildContext context,
    GoRouterState state,
    GuardMeta meta,
  ) async {
    final leftResult = await _left.check(context, state, meta);
    if (leftResult != null) return leftResult;
    if (!context.mounted) return null;
    return _right.check(context, state, meta);
  }
}

/// OR composition: at least one guard must pass.
class _OrGuard extends RouteGuard {
  _OrGuard(this._left, this._right);

  final RouteGuard _left;
  final RouteGuard _right;

  @override
  int get priority => _left.priority < _right.priority
      ? _left.priority
      : _right.priority;

  @override
  FutureOr<String?> check(
    BuildContext context,
    GoRouterState state,
    GuardMeta meta,
  ) async {
    final leftResult = await _left.check(context, state, meta);
    if (leftResult == null) return null;
    if (!context.mounted) return null;
    final rightResult = await _right.check(context, state, meta);
    if (rightResult == null) return null;
    // Both failed — return the first guard's redirect
    return leftResult;
  }
}

/// NOT composition: inverts the guard result.
class _NotGuard extends RouteGuard {
  _NotGuard(this._inner);

  final RouteGuard _inner;

  /// Default redirect path when the inner guard passes (meaning NOT fails).
  static const String defaultRedirectTo = '/';

  @override
  int get priority => _inner.priority;

  @override
  FutureOr<String?> check(
    BuildContext context,
    GoRouterState state,
    GuardMeta meta,
  ) async {
    final result = await _inner.check(context, state, meta);
    if (result != null) {
      // Inner guard would redirect → NOT means allow
      return null;
    }
    // Inner guard would allow → NOT means redirect
    // Use meta 'notRedirectTo' or fall back to default
    return meta.get<String>('notRedirectTo') ?? defaultRedirectTo;
  }
}
