/// NestJS-style declarative route guards for GoRouter.
///
/// Declare guards at the route level, inherit through shells,
/// compose with existing redirect logic. Works with any state
/// management: Provider, Bloc, Riverpod, GetX, or plain singletons.
///
/// ```dart
/// import 'package:go_guardian/go_guardian.dart';
///
/// // With BuildContext (Provider, Bloc)
/// GuardedRoute(
///   path: '/admin',
///   guards: [AuthGuard(isAuthenticated: (ctx) => ctx.read<Auth>().isLoggedIn)],
///   builder: (_, __) => AdminScreen(),
/// )
///
/// // Without BuildContext (GetX, singletons, Riverpod ref)
/// GuardedRoute(
///   path: '/admin',
///   guards: [AuthGuard.stateless(isAuthenticated: () => myService.isLoggedIn)],
///   builder: (_, __) => AdminScreen(),
/// )
/// ```
library go_guardian;

// Re-export go_router so users only need one import.
export 'package:go_router/go_router.dart';

// Guards
export 'src/guards/route_guard.dart';
export 'src/guards/auth_guard.dart';
export 'src/guards/role_guard.dart';
export 'src/guards/onboarding_guard.dart';
export 'src/guards/maintenance_guard.dart';

// Routes
export 'src/routes/guarded_route.dart';
export 'src/routes/guarded_shell_route.dart';
export 'src/routes/discarded_route.dart';

// Chain
export 'src/chain/guard_chain.dart';

// Meta
export 'src/meta/guard_meta.dart';

// Core
export 'src/core/guard_result.dart';

// Refresh
export 'src/refresh/guard_refresh_notifier.dart';

// Debug
export 'src/debug/guard_event.dart';
export 'src/debug/guard_observer.dart';

// Testing
export 'src/testing/guard_test_harness.dart';
