import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../debug/guard_event.dart';
import '../debug/guard_observer.dart';
import 'guard_result.dart';
import '../guards/route_guard.dart';
import '../meta/guard_meta.dart';

/// Internal resolver that evaluates a list of guards in priority order.
///
/// Handles both synchronous and asynchronous guards. Emits [GuardEvent]s
/// to the global [GoGuardian.observer] for debugging and profiling.
class GuardResolver {
  GuardResolver._();

  /// Evaluates [guards] in priority order against the given [context],
  /// [state], and [meta].
  ///
  /// Returns the redirect path from the first guard that denies access,
  /// or `null` if all guards pass.
  static Future<String?> resolve({
    required BuildContext context,
    required GoRouterState state,
    required List<RouteGuard> guards,
    required GuardMeta meta,
  }) async {
    if (guards.isEmpty) return null;

    // Sort by priority (lowest first)
    final sorted = List<RouteGuard>.from(guards)
      ..sort((a, b) => a.priority.compareTo(b.priority));

    final routePath = state.uri.path;
    final chainStart = DateTime.now();
    final chainStopwatch = Stopwatch()..start();

    // Emit start event
    GoGuardian.emit(GuardEvaluationStarted(
      routePath: routePath,
      timestamp: chainStart,
      guardCount: sorted.length,
      guardTypes: sorted.map((g) => g.runtimeType.toString()).toList(),
    ));

    var guardsEvaluated = 0;
    GuardResult finalResult = const GuardResult.allow();

    for (final guard in sorted) {
      guardsEvaluated++;
      final guardStopwatch = Stopwatch()..start();

      final result = await guard.check(context, state, meta);
      guardStopwatch.stop();

      final guardResult = result == null
          ? const GuardResult.allow()
          : GuardResult.redirect(result);

      // Emit per-guard event
      GoGuardian.emit(GuardCheckCompleted(
        routePath: routePath,
        timestamp: DateTime.now(),
        guardType: guard.runtimeType.toString(),
        result: guardResult,
        duration: guardStopwatch.elapsed,
      ));

      if (result != null) {
        finalResult = guardResult;
        break;
      }
    }

    chainStopwatch.stop();

    // Emit chain completion event
    GoGuardian.emit(GuardChainCompleted(
      routePath: routePath,
      timestamp: DateTime.now(),
      finalResult: finalResult,
      totalDuration: chainStopwatch.elapsed,
      guardsEvaluated: guardsEvaluated,
    ));

    return finalResult.toRedirectPath();
  }

  /// Synchronously evaluates guards where possible.
  /// If any guard returns a Future, falls back to async resolution.
  static FutureOr<String?> resolveSync({
    required BuildContext context,
    required GoRouterState state,
    required List<RouteGuard> guards,
    required GuardMeta meta,
  }) {
    final sorted = List<RouteGuard>.from(guards)
      ..sort((a, b) => a.priority.compareTo(b.priority));

    for (final guard in sorted) {
      final result = guard.check(context, state, meta);
      if (result is Future<String?>) {
        // Switch to async resolution for remaining guards
        return _resolveRemainingAsync(
          context: context,
          state: state,
          guards: sorted,
          meta: meta,
          startIndex: sorted.indexOf(guard),
          pendingFuture: result,
        );
      }
      if (result != null) return result;
    }
    return null;
  }

  static Future<String?> _resolveRemainingAsync({
    required BuildContext context,
    required GoRouterState state,
    required List<RouteGuard> guards,
    required GuardMeta meta,
    required int startIndex,
    required Future<String?> pendingFuture,
  }) async {
    final pendingResult = await pendingFuture;
    if (pendingResult != null) return pendingResult;

    for (var i = startIndex + 1; i < guards.length; i++) {
      if (!context.mounted) return null;
      final result = await guards[i].check(context, state, meta);
      if (result != null) return result;
    }
    return null;
  }
}
