import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../meta/guard_meta.dart';
import 'route_guard.dart';

/// Guard that checks authentication status.
///
/// Redirects unauthenticated users to the login route, optionally
/// preserving the original deep link as a query parameter.
///
/// **With BuildContext** (Provider, Bloc, flutter_riverpod):
/// ```dart
/// AuthGuard(
///   isAuthenticated: (ctx) => ctx.read<AuthService>().isLoggedIn,
/// )
/// ```
///
/// **Without BuildContext** (GetX, singletons, Riverpod ref, signals):
/// ```dart
/// AuthGuard.stateless(
///   isAuthenticated: () => AuthService.instance.isLoggedIn,
/// )
/// ```
class AuthGuard extends RouteGuard {
  /// Creates an [AuthGuard] with a context-aware callback.
  ///
  /// [isAuthenticated] — callback receiving [BuildContext], returning `true`
  ///   if the user is logged in.
  /// [redirectTo] — path to redirect to when not authenticated.
  /// [preserveDeepLink] — if `true`, appends `?continue=<original_path>` to
  ///   the redirect URL so the login page can navigate back after auth.
  AuthGuard({
    required bool Function(BuildContext) isAuthenticated,
    this.redirectTo = '/login',
    this.preserveDeepLink = true,
  })  : _contextCheck = isAuthenticated,
        _statelessCheck = null;

  /// Creates an [AuthGuard] with a context-free callback.
  ///
  /// Works with any state management: GetX, singletons, Riverpod `ref`,
  /// signals, or plain global state.
  ///
  /// ```dart
  /// AuthGuard.stateless(isAuthenticated: () => ref.read(authProvider).isLoggedIn)
  /// AuthGuard.stateless(isAuthenticated: () => Get.find<AuthCtrl>().isLoggedIn)
  /// AuthGuard.stateless(isAuthenticated: () => AuthService.instance.isLoggedIn)
  /// ```
  AuthGuard.stateless({
    required bool Function() isAuthenticated,
    this.redirectTo = '/login',
    this.preserveDeepLink = true,
  })  : _contextCheck = null,
        _statelessCheck = isAuthenticated;

  final bool Function(BuildContext)? _contextCheck;
  final bool Function()? _statelessCheck;

  /// The path to redirect to when authentication fails.
  final String redirectTo;

  /// Whether to append the original path as a `continue` query parameter.
  final bool preserveDeepLink;

  @override
  int get priority => 10;

  @override
  FutureOr<String?> check(
    BuildContext context,
    GoRouterState state,
    GuardMeta meta,
  ) {
    final contextCheck = _contextCheck;
    final statelessCheck = _statelessCheck;
    final authenticated = contextCheck != null
        ? contextCheck(context)
        : statelessCheck!();

    if (authenticated) return null;

    if (preserveDeepLink) {
      final currentPath = state.uri.toString();
      if (currentPath != redirectTo && currentPath != '/') {
        return Uri.parse(redirectTo).replace(
          queryParameters: {'continue': currentPath},
        ).toString();
      }
    }

    return redirectTo;
  }
}
