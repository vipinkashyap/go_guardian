import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../guards/route_guard.dart';
import '../meta/guard_meta.dart';
import 'guarded_route.dart';

/// A [ShellRoute] with declarative guard support.
///
/// Guards defined here are automatically inherited by all child
/// [GuardedRoute] and nested [GuardedShellRoute] instances.
/// Plain [GoRoute] children are left untouched — they opted out
/// of the guard system.
///
/// Inheritance works by reconstructing child [GuardedRoute]s at
/// construction time with the shell guards prepended to each
/// child's own guards. This means guard evaluation happens at
/// the route level via [GoRoute.redirect], exactly where GoRouter
/// expects it.
///
/// Example:
/// ```dart
/// GuardedShellRoute(
///   guards: [AuthGuard(...)],
///   builder: (context, state, child) => AppShell(child: child),
///   routes: [
///     GuardedRoute(path: '/home', builder: (_, __) => HomeScreen()),
///     // ↑ inherits AuthGuard automatically
///   ],
/// )
/// ```
class GuardedShellRoute extends ShellRoute {
  /// Creates a [GuardedShellRoute] with optional [guards], [guardMeta],
  /// and [loadingBuilder].
  ///
  /// Guards defined here will be inherited by all descendant
  /// [GuardedRoute] and nested [GuardedShellRoute] instances.
  GuardedShellRoute({
    required ShellRouteBuilder super.builder,
    super.navigatorKey,
    List<RouteBase> routes = const [],
    super.parentNavigatorKey,
    super.restorationScopeId,
    this.guards = const [],
    this.guardMeta = GuardMeta.empty,
    this.loadingBuilder,
    this.existingRedirect,
  })  : originalRoutes = routes,
        super(
          routes: _propagateGuards(routes, guards, guardMeta),
        );

  /// Optional existing redirect to preserve alongside guard logic.
  final GoRouterRedirect? existingRedirect;

  /// The list of guards inherited by all child routes.
  final List<RouteGuard> guards;

  /// Metadata inherited by all child routes.
  /// Child route metadata takes precedence when keys conflict.
  final GuardMeta guardMeta;

  /// Optional builder shown while async guards are resolving.
  ///
  /// If not provided, child routes will wait for guard resolution
  /// before rendering.
  final Widget Function(BuildContext, GoRouterState)? loadingBuilder;

  /// The routes as originally declared, before guard propagation.
  ///
  /// Stored so that nested shell reconstruction (during parent shell
  /// propagation) can start from the un-propagated routes, avoiding
  /// double-prepending of inherited guards.
  final List<RouteBase> originalRoutes;

  /// Walks [routes] and reconstructs any [GuardedRoute] or nested
  /// [GuardedShellRoute] with [shellGuards] prepended and [shellMeta]
  /// merged. Plain [GoRoute]/[ShellRoute] children are left untouched.
  static List<RouteBase> _propagateGuards(
    List<RouteBase> routes,
    List<RouteGuard> shellGuards,
    GuardMeta shellMeta,
  ) {
    if (shellGuards.isEmpty && shellMeta == GuardMeta.empty) return routes;

    return routes.map((route) {
      if (route is GuardedRoute) {
        // Reconstruct with shell guards prepended to the child's own guards.
        return GuardedRoute(
          path: route.path,
          name: route.name,
          builder: route.builder,
          pageBuilder: route.pageBuilder,
          parentNavigatorKey: route.parentNavigatorKey,
          routes: route.routes,
          onExit: route.onExit,
          guards: [...shellGuards, ...route.guards],
          guardMeta: shellMeta.merge(route.guardMeta),
          existingRedirect: route.existingRedirect,
        );
      }

      if (route is GuardedShellRoute) {
        // Merge shell guards into the nested shell, then let its own
        // constructor re-propagate from the original (un-propagated) routes.
        return GuardedShellRoute(
          builder: route.builder!,
          navigatorKey: route.navigatorKey,
          parentNavigatorKey: route.parentNavigatorKey,
          restorationScopeId: route.restorationScopeId,
          routes: route.originalRoutes, // un-propagated originals
          guards: [...shellGuards, ...route.guards],
          guardMeta: shellMeta.merge(route.guardMeta),
          loadingBuilder: route.loadingBuilder,
          existingRedirect: route.existingRedirect,
        );
      }

      // Plain GoRoute / ShellRoute — leave untouched.
      return route;
    }).toList();
  }
}
