import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../core/guard_resolver.dart';
import '../guards/route_guard.dart';
import '../meta/guard_meta.dart';

/// A [GoRoute] with declarative guard support.
///
/// Guards are evaluated in priority order before the route is rendered.
/// The first guard that returns a non-null redirect path wins.
///
/// Guards defined on parent [GuardedShellRoute]s are automatically
/// inherited and prepended to this route's own guards.
///
/// Example:
/// ```dart
/// GuardedRoute(
///   path: '/admin',
///   guards: [RoleGuard(hasRole: (ctx, roles) => /* ... */)],
///   guardMeta: GuardMeta({'roles': ['admin']}),
///   builder: (_, __) => AdminScreen(),
/// )
/// ```
class GuardedRoute extends GoRoute {
  /// Creates a [GuardedRoute] with optional [guards] and [guardMeta].
  ///
  /// If [existingRedirect] is provided, it will be called after all guards
  /// pass, allowing you to preserve existing redirect logic.
  GuardedRoute({
    required super.path,
    super.name,
    super.builder,
    super.pageBuilder,
    super.parentNavigatorKey,
    super.routes,
    super.onExit,
    this.guards = const [],
    this.guardMeta = GuardMeta.empty,
    GoRouterRedirect? existingRedirect,
  }) : super(
          redirect: (BuildContext context, GoRouterState state) {
            return _evaluateGuards(
              context: context,
              state: state,
              guards: guards,
              guardMeta: guardMeta,
              existingRedirect: existingRedirect,
            );
          },
        );

  /// The list of guards to evaluate for this route.
  final List<RouteGuard> guards;

  /// Metadata passed to guards during evaluation.
  final GuardMeta guardMeta;

  static FutureOr<String?> _evaluateGuards({
    required BuildContext context,
    required GoRouterState state,
    required List<RouteGuard> guards,
    required GuardMeta guardMeta,
    required GoRouterRedirect? existingRedirect,
  }) async {
    if (guards.isEmpty && existingRedirect == null) return null;

    // Evaluate guards
    if (guards.isNotEmpty) {
      final result = await GuardResolver.resolve(
        context: context,
        state: state,
        guards: guards,
        meta: guardMeta,
      );
      if (result != null) return result;
    }

    // Fall through to existing redirect if guards pass
    if (existingRedirect != null && context.mounted) {
      return existingRedirect(context, state);
    }

    return null;
  }
}
