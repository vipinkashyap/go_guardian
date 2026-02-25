import 'package:flutter/material.dart';
import 'package:go_guardian/go_guardian.dart';

import 'screens.dart';
import 'services.dart';

final _auth = AuthService.instance;
final _config = AppConfig.instance;

/// Merges auth + config changes into a single refreshListenable.
final refreshNotifier = GuardRefreshNotifier.from([_auth, _config]);

final router = GoRouter(
  initialLocation: '/login',
  refreshListenable: refreshNotifier,
  routes: [
    // Public: skips /login when already logged in.
    DiscardedRoute.stateless(
      path: '/login',
      discardWhen: () => _auth.isLoggedIn,
      redirectTo: '/home',
      builder: (_, __) => const LoginScreen(),
    ),

    // Standalone screens (no guards needed).
    GoRoute(
        path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
    GoRoute(
        path: '/unauthorized',
        builder: (_, __) => const MessageScreen(
              icon: Icons.block,
              title: 'Access Denied',
              body: 'RoleGuard blocked you — you lack the required role.',
            )),
    GoRoute(
        path: '/maintenance',
        builder: (_, __) => const MessageScreen(
              icon: Icons.construction,
              title: 'Under Maintenance',
              body: 'MaintenanceGuard (priority -10) caught this first.',
            )),

    // Protected shell — all children inherit these three guards.
    GuardedShellRoute(
      guards: [
        MaintenanceGuard.stateless(
            isUnderMaintenance: () => _config.maintenance),
        AuthGuard.stateless(
            isAuthenticated: () => _auth.isLoggedIn, preserveDeepLink: true),
        OnboardingGuard.stateless(isOnboarded: () => _auth.isOnboarded),
      ],
      builder: (ctx, state, child) => AppShell(child: child),
      routes: [
        GuardedRoute(path: '/home', builder: (_, __) => const HomeScreen()),
        GuardedRoute(
          path: '/admin',
          guards: [
            RoleGuard.stateless(hasRole: (r) => _auth.hasAnyRole(r)),
          ],
          guardMeta: const GuardMeta({'roles': ['admin']}),
          builder: (_, __) => const AdminScreen(),
        ),
        GuardedRoute(
            path: '/settings', builder: (_, __) => const SettingsScreen()),
      ],
    ),
  ],
);
