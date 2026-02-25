import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_guardian/go_guardian.dart';

import 'guards.dart';
import 'screens.dart';
import 'services.dart';

final _auth = AuthService.instance;
final _config = AppConfig.instance;

/// Merges auth + config changes into a single refreshListenable.
final refreshNotifier = GuardRefreshNotifier.from([_auth, _config]);

// ── Existing redirect (for GuardChain brownfield demo) ──────────────
/// Pretend this is a legacy redirect function that was here before go_guardian.
FutureOr<String?> _legacySettingsRedirect(
    BuildContext context, GoRouterState state) {
  // Old-school redirect: block settings if user has no name.
  if (_auth.userName.isEmpty) return '/login';
  return null;
}

// ── Router ──────────────────────────────────────────────────────────

final router = GoRouter(
  initialLocation: '/login',
  refreshListenable: refreshNotifier,
  routes: [
    // ── DiscardedRoute ──────────────────────────────────────────────
    // Skips /login when already logged in — inverse of a guard.
    DiscardedRoute.stateless(
      path: '/login',
      discardWhen: () => _auth.isLoggedIn,
      redirectTo: '/home',
      builder: (_, __) => const LoginScreen(),
    ),

    // ── Standalone screens (outside the guarded shell) ──────────────
    GoRoute(
        path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
    GoRoute(
        path: '/unauthorized',
        builder: (_, __) => const MessageScreen(
              icon: Icons.block,
              title: 'Access Denied',
              body: 'RoleGuard blocked you — you lack the required role.',
              goTo: '/home',
              goLabel: 'Go home',
            )),
    GoRoute(
        path: '/maintenance',
        builder: (_, __) => const MessageScreen(
              icon: Icons.construction,
              title: 'Under Maintenance',
              body: 'MaintenanceGuard (priority -10) caught this first.\n'
                  'Toggle maintenance OFF from the home screen.',
              // No "Go home" button — it would redirect loop.
              goTo: null,
              goLabel: null,
            )),
    GoRoute(
        path: '/paywall',
        builder: (_, __) => const MessageScreen(
              icon: Icons.lock,
              title: 'Premium Only',
              body:
                  'PremiumGuard (a custom RouteGuard) blocked this route.\nToggle Premium ON from the home screen.',
              goTo: '/home',
              goLabel: 'Go home',
            )),

    // ── GuardedShellRoute — all children inherit these guards ───────
    // Every GuardedRoute child automatically gets Maintenance + Auth +
    // Onboarding guards prepended to its own guards at construction time.
    // Plain GoRoute children (like /settings) opt out of inheritance.
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
        // Basic — inherits shell guards only (Auth, Onboarding, Maintenance).
        GuardedRoute(path: '/home', builder: (_, __) => const HomeScreen()),

        // ── RoleGuard + GuardMeta ───────────────────────────────────
        // Inherits shell guards + adds RoleGuard.
        GuardedRoute(
          path: '/admin',
          guards: [
            RoleGuard.stateless(hasRole: (r) => _auth.hasAnyRole(r)),
          ],
          guardMeta: const GuardMeta({'roles': ['admin']}),
          builder: (_, __) => const AdminScreen(),
        ),

        // ── Custom guard (extends RouteGuard) ───────────────────────
        // Inherits shell guards + adds PremiumGuard.
        GuardedRoute(
          path: '/premium',
          guards: [
            PremiumGuard.stateless(isPremium: () => _auth.isPremium),
          ],
          builder: (_, __) => const PremiumScreen(),
        ),

        // ── GuardChain — brownfield migration ───────────────────────
        // Plain GoRoute: does NOT inherit shell guards.
        // Uses GuardChain to wrap a legacy redirect with an AuthGuard.
        GoRoute(
          path: '/settings',
          redirect: GuardChain
              .existing(_legacySettingsRedirect)
              .then(AuthGuard.stateless(
                  isAuthenticated: () => _auth.isLoggedIn))
              .existingWins(), // legacy redirect runs first
          builder: (_, __) => const SettingsScreen(),
        ),

        // ── Guard composition: | (OR) operator ─────────────────────
        // Inherits shell guards + accessible if admin OR premium.
        GuardedRoute(
          path: '/vip-lounge',
          guards: [
            RoleGuard.stateless(hasRole: (r) => _auth.hasAnyRole(r)) |
                PremiumGuard.stateless(isPremium: () => _auth.isPremium),
          ],
          guardMeta: const GuardMeta({'roles': ['admin']}),
          builder: (_, __) => const VipLoungeScreen(),
        ),
      ],
    ),
  ],
);
