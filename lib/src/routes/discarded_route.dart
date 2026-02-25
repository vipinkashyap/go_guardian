import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// A route that becomes inaccessible when a condition IS met.
///
/// This is the inverse of [GuardedRoute]: instead of blocking access when
/// a condition fails, it redirects away when a condition passes.
///
/// Classic use cases:
/// - `/login` redirects to `/home` when user is already authenticated
/// - `/onboarding` redirects to `/home` when onboarding is complete
/// - `/get-started` is irrelevant once the user has an account
///
/// **With BuildContext** (Provider, Bloc):
/// ```dart
/// DiscardedRoute(
///   path: '/login',
///   discardWhen: (ctx) => ctx.read<Auth>().isLoggedIn,
///   redirectTo: '/home',
///   builder: (_, __) => LoginScreen(),
/// )
/// ```
///
/// **Without BuildContext** (GetX, singletons, Riverpod ref):
/// ```dart
/// DiscardedRoute.stateless(
///   path: '/login',
///   discardWhen: () => AuthService.instance.isLoggedIn,
///   redirectTo: '/home',
///   builder: (_, __) => LoginScreen(),
/// )
/// ```
class DiscardedRoute extends GoRoute {
  /// Creates a [DiscardedRoute] with a context-aware discard condition.
  ///
  /// When [discardWhen] returns `true`, navigation to this route is
  /// redirected to [redirectTo].
  DiscardedRoute({
    required super.path,
    required bool Function(BuildContext) discardWhen,
    required String redirectTo,
    super.name,
    super.builder,
    super.pageBuilder,
    super.parentNavigatorKey,
    super.routes,
    super.onExit,
  }) : super(
          redirect: (BuildContext context, GoRouterState state) {
            if (discardWhen(context)) return redirectTo;
            return null;
          },
        );

  /// Creates a [DiscardedRoute] with a context-free discard condition.
  ///
  /// Works with any state management: GetX, singletons, Riverpod `ref`,
  /// signals, or plain global state.
  ///
  /// ```dart
  /// DiscardedRoute.stateless(
  ///   path: '/login',
  ///   discardWhen: () => Get.find<AuthCtrl>().isLoggedIn,
  ///   redirectTo: '/home',
  ///   builder: (_, __) => LoginScreen(),
  /// )
  /// ```
  DiscardedRoute.stateless({
    required super.path,
    required bool Function() discardWhen,
    required String redirectTo,
    super.name,
    super.builder,
    super.pageBuilder,
    super.parentNavigatorKey,
    super.routes,
    super.onExit,
  }) : super(
          redirect: (BuildContext context, GoRouterState state) {
            if (discardWhen()) return redirectTo;
            return null;
          },
        );
}
