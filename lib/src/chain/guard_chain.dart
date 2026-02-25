import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../guards/route_guard.dart';
import '../meta/guard_meta.dart';

/// Composes guards and existing redirect logic for brownfield migration.
///
/// Use [GuardChain] when you have existing `redirect` functions and want
/// to gradually adopt guards without rewriting everything at once.
///
/// Example — brownfield:
/// ```dart
/// redirect: GuardChain
///   .existing(myExistingRedirect)
///   .then(AuthGuard())
///   .then(RoleGuard(Role.admin))
///   .existingWins(),
/// ```
///
/// Example — greenfield:
/// ```dart
/// redirect: GuardChain
///   .guards([AuthGuard(), RoleGuard(Role.admin)])
///   .build(),
/// ```
class GuardChain {
  GuardChain._();

  /// Creates a chain starting with an existing redirect function.
  ///
  /// Use [GuardChainBuilder.existingWins] or [GuardChainBuilder.guardsWin]
  /// to choose priority strategy.
  static GuardChainBuilder existing(GoRouterRedirect existingRedirect) {
    return GuardChainBuilder._(existingRedirect: existingRedirect);
  }

  /// Creates a chain with guards only, no existing redirect.
  static GuardChainBuilder guards(List<RouteGuard> guards) {
    return GuardChainBuilder._(initialGuards: guards);
  }
}

/// Builder for composing guard chains with priority strategies.
class GuardChainBuilder {
  GuardChainBuilder._({
    GoRouterRedirect? existingRedirect,
    List<RouteGuard>? initialGuards,
  })  : _existingRedirect = existingRedirect,
        _steps = [] {
    if (initialGuards != null) {
      for (final guard in initialGuards) {
        _steps.add(_GuardStep(guard));
      }
    }
  }

  final GoRouterRedirect? _existingRedirect;
  final List<_ChainStep> _steps;
  GuardMeta _meta = GuardMeta.empty;

  /// Appends a guard to the chain.
  GuardChainBuilder then(RouteGuard guard) {
    _steps.add(_GuardStep(guard));
    return this;
  }

  /// Appends a raw redirect function to the chain.
  GuardChainBuilder thenRaw(GoRouterRedirect redirect) {
    _steps.add(_RawStep(redirect));
    return this;
  }

  /// Sets metadata for guard evaluation.
  GuardChainBuilder withMeta(GuardMeta meta) {
    _meta = meta;
    return this;
  }

  /// Builds the redirect: existing redirect runs first.
  /// If it returns a redirect, guards are skipped.
  GoRouterRedirect existingWins() {
    final existing = _existingRedirect;
    final steps = List<_ChainStep>.from(_steps);
    final meta = _meta;

    return (BuildContext context, GoRouterState state) async {
      // Existing redirect takes priority
      if (existing != null) {
        final result = await existing(context, state);
        if (result != null) return result;
      }

      // Then evaluate chain steps
      if (!context.mounted) return null;
      return _evaluateSteps(context, state, steps, meta);
    };
  }

  /// Builds the redirect: guards run first.
  /// If any guard redirects, existing redirect is skipped.
  GoRouterRedirect guardsWin() {
    final existing = _existingRedirect;
    final steps = List<_ChainStep>.from(_steps);
    final meta = _meta;

    return (BuildContext context, GoRouterState state) async {
      // Guards take priority
      final guardResult = await _evaluateSteps(context, state, steps, meta);
      if (guardResult != null) return guardResult;

      // Then existing redirect
      if (!context.mounted) return null;
      if (existing != null) {
        return existing(context, state);
      }

      return null;
    };
  }

  /// Builds the redirect using explicit ordering — steps run in
  /// the order they were added.
  GoRouterRedirect build() {
    final existing = _existingRedirect;
    final steps = List<_ChainStep>.from(_steps);
    final meta = _meta;

    return (BuildContext context, GoRouterState state) async {
      // If there's an existing redirect and no steps, just use it
      if (existing != null && steps.isEmpty) {
        return existing(context, state);
      }

      // Run steps in order
      final result = await _evaluateSteps(context, state, steps, meta);
      if (result != null) return result;

      // Fall through to existing if present
      if (!context.mounted) return null;
      if (existing != null) {
        return existing(context, state);
      }

      return null;
    };
  }

  static Future<String?> _evaluateSteps(
    BuildContext context,
    GoRouterState state,
    List<_ChainStep> steps,
    GuardMeta meta,
  ) async {
    for (final step in steps) {
      final result = await step.evaluate(context, state, meta);
      if (result != null) return result;
    }
    return null;
  }
}

/// Base class for chain steps.
abstract class _ChainStep {
  FutureOr<String?> evaluate(
    BuildContext context,
    GoRouterState state,
    GuardMeta meta,
  );
}

/// A chain step wrapping a [RouteGuard].
class _GuardStep extends _ChainStep {
  _GuardStep(this.guard);
  final RouteGuard guard;

  @override
  FutureOr<String?> evaluate(
    BuildContext context,
    GoRouterState state,
    GuardMeta meta,
  ) {
    return guard.check(context, state, meta);
  }
}

/// A chain step wrapping a raw [GoRouterRedirect].
class _RawStep extends _ChainStep {
  _RawStep(this.redirect);
  final GoRouterRedirect redirect;

  @override
  FutureOr<String?> evaluate(
    BuildContext context,
    GoRouterState state,
    GuardMeta meta,
  ) {
    return redirect(context, state);
  }
}
