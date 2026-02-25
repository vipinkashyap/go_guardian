import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../meta/guard_meta.dart';
import 'route_guard.dart';

/// Guard that checks user roles against required roles from [GuardMeta].
///
/// Reads the `roles` key from [GuardMeta] automatically, making it easy
/// to define required roles at the route level.
///
/// **With BuildContext** (Provider, Bloc, flutter_riverpod):
/// ```dart
/// RoleGuard(hasRole: (ctx, roles) => ctx.read<AuthService>().hasAnyRole(roles))
/// ```
///
/// **Without BuildContext** (GetX, singletons, Riverpod ref, signals):
/// ```dart
/// RoleGuard.stateless(hasRole: (roles) => AuthService.instance.hasAnyRole(roles))
/// ```
class RoleGuard extends RouteGuard {
  /// Creates a [RoleGuard] with a context-aware callback.
  ///
  /// [hasRole] — callback that receives the context and required roles list,
  ///   returning `true` if the user has at least one of the required roles.
  /// [redirectTo] — path to redirect to when the role check fails.
  /// [rolesKey] — the key used to read roles from [GuardMeta]. Defaults to `'roles'`.
  RoleGuard({
    required bool Function(BuildContext, List<String>) hasRole,
    this.redirectTo = '/unauthorized',
    this.rolesKey = 'roles',
  })  : _contextCheck = hasRole,
        _statelessCheck = null;

  /// Creates a [RoleGuard] with a context-free callback.
  ///
  /// ```dart
  /// RoleGuard.stateless(hasRole: (roles) => myService.hasAnyRole(roles))
  /// ```
  RoleGuard.stateless({
    required bool Function(List<String>) hasRole,
    this.redirectTo = '/unauthorized',
    this.rolesKey = 'roles',
  })  : _contextCheck = null,
        _statelessCheck = hasRole;

  final bool Function(BuildContext, List<String>)? _contextCheck;
  final bool Function(List<String>)? _statelessCheck;

  /// The path to redirect to when the role check fails.
  final String redirectTo;

  /// The metadata key used to read required roles. Defaults to `'roles'`.
  final String rolesKey;

  @override
  int get priority => 20;

  @override
  FutureOr<String?> check(
    BuildContext context,
    GoRouterState state,
    GuardMeta meta,
  ) {
    final roles = meta.get<List<dynamic>>(rolesKey);
    if (roles == null || roles.isEmpty) {
      // No roles required — allow access
      return null;
    }

    final stringRoles = roles.cast<String>();
    final contextCheck = _contextCheck;
    final statelessCheck = _statelessCheck;
    final hasRole = contextCheck != null
        ? contextCheck(context, stringRoles)
        : statelessCheck!(stringRoles);

    if (hasRole) return null;
    return redirectTo;
  }
}
