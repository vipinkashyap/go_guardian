import 'package:go_router/go_router.dart';

import '../guards/route_guard.dart';
import '../meta/guard_meta.dart';
import '../routes/guarded_route.dart';
import '../routes/guarded_shell_route.dart';

/// Internal registry that tracks guard inheritance through the route tree.
///
/// When [GuardedShellRoute]s define guards, those guards are automatically
/// inherited by all child [GuardedRoute] and nested [GuardedShellRoute]
/// instances. This class walks the route tree to collect inherited guards
/// and merged metadata.
class GuardRegistry {
  GuardRegistry._();

  /// Collects all guards applicable to the given [route] by walking
  /// up through its parent shells in [allRoutes].
  ///
  /// Returns guards sorted by priority (lowest first).
  static List<RouteGuard> collectGuards(
    RouteBase route,
    List<RouteBase> allRoutes,
  ) {
    final inherited = <RouteGuard>[];
    _collectFromTree(allRoutes, route, inherited);

    // Add the route's own guards
    final ownGuards = _getRouteGuards(route);

    final all = [...inherited, ...ownGuards];
    all.sort((a, b) => a.priority.compareTo(b.priority));
    return all;
  }

  /// Collects merged [GuardMeta] for the given [route] by walking
  /// up through its parent shells in [allRoutes].
  static GuardMeta collectMeta(
    RouteBase route,
    List<RouteBase> allRoutes,
  ) {
    var meta = GuardMeta.empty;
    _collectMetaFromTree(allRoutes, route, meta, (merged) => meta = merged);

    final ownMeta = _getRouteMeta(route);
    return meta.merge(ownMeta);
  }

  static void _collectFromTree(
    List<RouteBase> routes,
    RouteBase target,
    List<RouteGuard> inherited,
  ) {
    for (final route in routes) {
      if (identical(route, target)) return;

      if (route is GuardedShellRoute && _containsRoute(route.routes, target)) {
        inherited.addAll(route.guards);
        _collectFromTree(route.routes, target, inherited);
        return;
      } else if (route is ShellRoute && _containsRoute(route.routes, target)) {
        _collectFromTree(route.routes, target, inherited);
        return;
      } else if (route is GoRoute && _containsRoute(route.routes, target)) {
        _collectFromTree(route.routes, target, inherited);
        return;
      }
    }
  }

  static void _collectMetaFromTree(
    List<RouteBase> routes,
    RouteBase target,
    GuardMeta current,
    void Function(GuardMeta) onUpdate,
  ) {
    for (final route in routes) {
      if (identical(route, target)) return;

      if (route is GuardedShellRoute && _containsRoute(route.routes, target)) {
        onUpdate(current.merge(route.guardMeta));
        _collectMetaFromTree(
          route.routes,
          target,
          current.merge(route.guardMeta),
          onUpdate,
        );
        return;
      } else if (route is ShellRoute && _containsRoute(route.routes, target)) {
        _collectMetaFromTree(route.routes, target, current, onUpdate);
        return;
      } else if (route is GoRoute && _containsRoute(route.routes, target)) {
        _collectMetaFromTree(route.routes, target, current, onUpdate);
        return;
      }
    }
  }

  static bool _containsRoute(List<RouteBase> routes, RouteBase target) {
    for (final route in routes) {
      if (identical(route, target)) return true;
      if (route is ShellRoute && _containsRoute(route.routes, target)) {
        return true;
      }
      if (route is GoRoute && _containsRoute(route.routes, target)) {
        return true;
      }
    }
    return false;
  }

  static List<RouteGuard> _getRouteGuards(RouteBase route) {
    if (route is GuardedRoute) return route.guards;
    if (route is GuardedShellRoute) return route.guards;
    return const [];
  }

  static GuardMeta _getRouteMeta(RouteBase route) {
    if (route is GuardedRoute) return route.guardMeta;
    if (route is GuardedShellRoute) return route.guardMeta;
    return GuardMeta.empty;
  }
}
