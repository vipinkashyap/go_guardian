import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../guards/route_guard.dart';
import '../meta/guard_meta.dart';

/// A [ShellRoute] with declarative guard support.
///
/// Guards defined here are automatically inherited by all child
/// [GuardedRoute] and nested [GuardedShellRoute] instances.
///
/// Supports a [loadingBuilder] for displaying a loading state while
/// async guards resolve.
///
/// Example:
/// ```dart
/// GuardedShellRoute(
///   guards: [AuthGuard(...)],
///   builder: (context, state, child) => AppShell(child: child),
///   routes: [
///     GuardedRoute(path: '/home', builder: (_, __) => HomeScreen()),
///   ],
/// )
/// ```
class GuardedShellRoute extends ShellRoute {
  /// Creates a [GuardedShellRoute] with optional [guards], [guardMeta],
  /// and [loadingBuilder].
  ///
  /// Guards defined here will be inherited by all descendant routes.
  GuardedShellRoute({
    required super.builder,
    super.navigatorKey,
    super.routes = const [],
    super.parentNavigatorKey,
    super.restorationScopeId,
    this.guards = const [],
    this.guardMeta = GuardMeta.empty,
    this.loadingBuilder,
    this.existingRedirect,
  });

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
}
