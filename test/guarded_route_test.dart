import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_guardian/go_guardian.dart';

// ---------------------------------------------------------------------------
// Test guards
// ---------------------------------------------------------------------------

class _SimpleAuthGuard extends RouteGuard {
  _SimpleAuthGuard({required this.loggedIn});
  final bool loggedIn;

  @override
  int get priority => 10;

  @override
  FutureOr<String?> check(
    BuildContext context,
    GoRouterState state,
    GuardMeta meta,
  ) =>
      loggedIn ? null : '/login';
}

class _SimpleRoleGuard extends RouteGuard {
  _SimpleRoleGuard({required this.userRoles});
  final Set<String> userRoles;

  @override
  int get priority => 20;

  @override
  FutureOr<String?> check(
    BuildContext context,
    GoRouterState state,
    GuardMeta meta,
  ) {
    final required = meta.get<List<dynamic>>('roles');
    if (required == null) return null;
    final hasRole = required.any((r) => userRoles.contains(r));
    return hasRole ? null : '/unauthorized';
  }
}

Future<void> _pumpRouter(WidgetTester tester, GoRouter router) async {
  await tester.pumpWidget(MaterialApp.router(routerConfig: router));
  await tester.pumpAndSettle();
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('GuardedRoute', () {
    testWidgets('allows access when all guards pass', (tester) async {
      final router = GoRouter(
        initialLocation: '/protected',
        routes: [
          GuardedRoute(
            path: '/protected',
            guards: [_SimpleAuthGuard(loggedIn: true)],
            builder: (_, __) => const Text('protected'),
          ),
          GoRoute(
            path: '/login',
            builder: (_, __) => const Text('login'),
          ),
        ],
      );
      await _pumpRouter(tester, router);
      expect(find.text('protected'), findsOneWidget);
    });

    testWidgets('redirects when guard denies', (tester) async {
      final router = GoRouter(
        initialLocation: '/protected',
        routes: [
          GuardedRoute(
            path: '/protected',
            guards: [_SimpleAuthGuard(loggedIn: false)],
            builder: (_, __) => const Text('protected'),
          ),
          GoRoute(
            path: '/login',
            builder: (_, __) => const Text('login'),
          ),
        ],
      );
      await _pumpRouter(tester, router);
      expect(find.text('login'), findsOneWidget);
    });

    testWidgets('reads metadata for role check', (tester) async {
      final router = GoRouter(
        initialLocation: '/admin',
        routes: [
          GuardedRoute(
            path: '/admin',
            guards: [
              _SimpleAuthGuard(loggedIn: true),
              _SimpleRoleGuard(userRoles: {'user'}),
            ],
            guardMeta: const GuardMeta({'roles': ['admin']}),
            builder: (_, __) => const Text('admin'),
          ),
          GoRoute(
            path: '/unauthorized',
            builder: (_, __) => const Text('unauthorized'),
          ),
          GoRoute(
            path: '/login',
            builder: (_, __) => const Text('login'),
          ),
        ],
      );
      await _pumpRouter(tester, router);
      expect(find.text('unauthorized'), findsOneWidget);
    });

    testWidgets('passes role check with correct role', (tester) async {
      final router = GoRouter(
        initialLocation: '/admin',
        routes: [
          GuardedRoute(
            path: '/admin',
            guards: [
              _SimpleAuthGuard(loggedIn: true),
              _SimpleRoleGuard(userRoles: {'admin', 'user'}),
            ],
            guardMeta: const GuardMeta({'roles': ['admin']}),
            builder: (_, __) => const Text('admin'),
          ),
          GoRoute(
            path: '/unauthorized',
            builder: (_, __) => const Text('unauthorized'),
          ),
          GoRoute(
            path: '/login',
            builder: (_, __) => const Text('login'),
          ),
        ],
      );
      await _pumpRouter(tester, router);
      expect(find.text('admin'), findsOneWidget);
    });

    testWidgets('first failing guard wins (priority order)', (tester) async {
      final router = GoRouter(
        initialLocation: '/test',
        routes: [
          GuardedRoute(
            path: '/test',
            guards: [
              _SimpleAuthGuard(loggedIn: false), // priority 10, fails
              _SimpleRoleGuard(userRoles: {}), // priority 20, would also fail
            ],
            guardMeta: const GuardMeta({'roles': ['admin']}),
            builder: (_, __) => const Text('test'),
          ),
          GoRoute(
            path: '/login',
            builder: (_, __) => const Text('login'),
          ),
          GoRoute(
            path: '/unauthorized',
            builder: (_, __) => const Text('unauthorized'),
          ),
        ],
      );
      await _pumpRouter(tester, router);
      // Auth guard (priority 10) should run first and redirect to /login
      expect(find.text('login'), findsOneWidget);
    });

    testWidgets('no guards means no redirect', (tester) async {
      final router = GoRouter(
        initialLocation: '/open',
        routes: [
          GuardedRoute(
            path: '/open',
            guards: const [],
            builder: (_, __) => const Text('open'),
          ),
        ],
      );
      await _pumpRouter(tester, router);
      expect(find.text('open'), findsOneWidget);
    });

    testWidgets('existingRedirect is called after guards pass',
        (tester) async {
      final router = GoRouter(
        initialLocation: '/test',
        routes: [
          GuardedRoute(
            path: '/test',
            guards: [_SimpleAuthGuard(loggedIn: true)],
            existingRedirect: (_, __) => '/existing',
            builder: (_, __) => const Text('test'),
          ),
          GoRoute(
            path: '/existing',
            builder: (_, __) => const Text('existing'),
          ),
        ],
      );
      await _pumpRouter(tester, router);
      expect(find.text('existing'), findsOneWidget);
    });
  });

  group('GuardedShellRoute inheritance', () {
    testWidgets('child routes inherit shell guards', (tester) async {
      // The child route has NO guards of its own — the shell's AuthGuard
      // should be inherited and block /child.
      final router = GoRouter(
        initialLocation: '/child',
        routes: [
          GuardedShellRoute(
            guards: [_SimpleAuthGuard(loggedIn: false)],
            builder: (_, __, child) => child,
            routes: [
              GuardedRoute(
                path: '/child',
                // No guards here — inherited from shell
                builder: (_, __) => const Text('child'),
              ),
            ],
          ),
          GoRoute(
            path: '/login',
            builder: (_, __) => const Text('login'),
          ),
        ],
      );
      await _pumpRouter(tester, router);
      expect(find.text('login'), findsOneWidget);
    });

    testWidgets('child routes allow when inherited guards pass',
        (tester) async {
      final router = GoRouter(
        initialLocation: '/child',
        routes: [
          GuardedShellRoute(
            guards: [_SimpleAuthGuard(loggedIn: true)],
            builder: (_, __, child) => child,
            routes: [
              GuardedRoute(
                path: '/child',
                builder: (_, __) => const Text('child'),
              ),
            ],
          ),
          GoRoute(
            path: '/login',
            builder: (_, __) => const Text('login'),
          ),
        ],
      );
      await _pumpRouter(tester, router);
      expect(find.text('child'), findsOneWidget);
    });

    testWidgets('child own guards combine with inherited guards',
        (tester) async {
      // Shell provides AuthGuard (passes), child adds RoleGuard (fails).
      final router = GoRouter(
        initialLocation: '/admin',
        routes: [
          GuardedShellRoute(
            guards: [_SimpleAuthGuard(loggedIn: true)],
            builder: (_, __, child) => child,
            routes: [
              GuardedRoute(
                path: '/admin',
                guards: [_SimpleRoleGuard(userRoles: {'user'})],
                guardMeta: const GuardMeta({'roles': ['admin']}),
                builder: (_, __) => const Text('admin'),
              ),
            ],
          ),
          GoRoute(
            path: '/login',
            builder: (_, __) => const Text('login'),
          ),
          GoRoute(
            path: '/unauthorized',
            builder: (_, __) => const Text('unauthorized'),
          ),
        ],
      );
      await _pumpRouter(tester, router);
      // Auth passes, but role check fails → unauthorized
      expect(find.text('unauthorized'), findsOneWidget);
    });

    testWidgets('nested shells accumulate guards', (tester) async {
      // Outer shell: AuthGuard (passes)
      // Inner shell: RoleGuard (fails — user has 'user', needs 'admin')
      // Child: no guards of its own
      final router = GoRouter(
        initialLocation: '/inner',
        routes: [
          GuardedShellRoute(
            guards: [_SimpleAuthGuard(loggedIn: true)],
            builder: (_, __, child) => child,
            routes: [
              GuardedShellRoute(
                guards: [
                  _SimpleRoleGuard(userRoles: {'user'}),
                ],
                guardMeta: const GuardMeta({'roles': ['admin']}),
                builder: (_, __, child) => child,
                routes: [
                  GuardedRoute(
                    path: '/inner',
                    // No guards — inherits Auth + Role from shells
                    builder: (_, __) => const Text('inner'),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/login',
            builder: (_, __) => const Text('login'),
          ),
          GoRoute(
            path: '/unauthorized',
            builder: (_, __) => const Text('unauthorized'),
          ),
        ],
      );
      await _pumpRouter(tester, router);
      // User has 'user' role but 'admin' is required → unauthorized
      expect(find.text('unauthorized'), findsOneWidget);
    });

    testWidgets('shell meta is inherited and merged', (tester) async {
      // Shell provides guardMeta with roles: ['admin'].
      // Child has RoleGuard but no meta of its own — should use shell meta.
      final router = GoRouter(
        initialLocation: '/admin',
        routes: [
          GuardedShellRoute(
            guards: [_SimpleAuthGuard(loggedIn: true)],
            guardMeta: const GuardMeta({'roles': ['admin']}),
            builder: (_, __, child) => child,
            routes: [
              GuardedRoute(
                path: '/admin',
                guards: [_SimpleRoleGuard(userRoles: {'admin'})],
                // No guardMeta here — inherited from shell
                builder: (_, __) => const Text('admin'),
              ),
            ],
          ),
          GoRoute(
            path: '/login',
            builder: (_, __) => const Text('login'),
          ),
          GoRoute(
            path: '/unauthorized',
            builder: (_, __) => const Text('unauthorized'),
          ),
        ],
      );
      await _pumpRouter(tester, router);
      // Shell meta provides roles, RoleGuard checks it, user has 'admin' → allow
      expect(find.text('admin'), findsOneWidget);
    });

    testWidgets('plain GoRoute children are not affected', (tester) async {
      // A plain GoRoute inside GuardedShellRoute should NOT inherit guards.
      final router = GoRouter(
        initialLocation: '/open',
        routes: [
          GuardedShellRoute(
            guards: [_SimpleAuthGuard(loggedIn: false)],
            builder: (_, __, child) => child,
            routes: [
              // Plain GoRoute — should NOT be affected by shell guards
              GoRoute(
                path: '/open',
                builder: (_, __) => const Text('open'),
              ),
            ],
          ),
          GoRoute(
            path: '/login',
            builder: (_, __) => const Text('login'),
          ),
        ],
      );
      await _pumpRouter(tester, router);
      // Plain GoRoute ignores shell guards → renders normally
      expect(find.text('open'), findsOneWidget);
    });
  });
}
