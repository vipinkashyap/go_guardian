import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:go_guardian/go_guardian.dart';

// ---------------------------------------------------------------------------
// Test helpers
// ---------------------------------------------------------------------------

class _AllowGuard extends RouteGuard {
  _AllowGuard({int? priority}) : _priority = priority ?? 0;
  final int _priority;

  @override
  int get priority => _priority;

  @override
  FutureOr<String?> check(
    BuildContext context,
    GoRouterState state,
    GuardMeta meta,
  ) =>
      null;
}

class _DenyGuard extends RouteGuard {
  _DenyGuard(this.redirectTo, {int? priority}) : _priority = priority ?? 0;
  final String redirectTo;
  final int _priority;

  @override
  int get priority => _priority;

  @override
  FutureOr<String?> check(
    BuildContext context,
    GoRouterState state,
    GuardMeta meta,
  ) =>
      redirectTo;
}

class _AsyncAllowGuard extends RouteGuard {
  _AsyncAllowGuard({Duration? delay})
      : delay = delay ?? const Duration(milliseconds: 10);
  final Duration delay;

  @override
  FutureOr<String?> check(
    BuildContext context,
    GoRouterState state,
    GuardMeta meta,
  ) async {
    await Future<void>.delayed(delay);
    return null;
  }
}

class _AsyncDenyGuard extends RouteGuard {
  _AsyncDenyGuard(this.redirectTo, {Duration? delay})
      : delay = delay ?? const Duration(milliseconds: 10);
  final String redirectTo;
  final Duration delay;

  @override
  FutureOr<String?> check(
    BuildContext context,
    GoRouterState state,
    GuardMeta meta,
  ) async {
    await Future<void>.delayed(delay);
    return redirectTo;
  }
}

/// Helper to build a minimal GoRouter context for testing.
Future<void> _pumpRouter(
  WidgetTester tester,
  GoRouter router,
) async {
  await tester.pumpWidget(
    MaterialApp.router(routerConfig: router),
  );
  await tester.pumpAndSettle();
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('GuardMeta', () {
    test('get returns typed value', () {
      const meta = GuardMeta({'name': 'test', 'count': 42});
      expect(meta.get<String>('name'), 'test');
      expect(meta.get<int>('count'), 42);
    });

    test('get returns null for missing key', () {
      const meta = GuardMeta({'name': 'test'});
      expect(meta.get<String>('missing'), isNull);
    });

    test('get returns null for wrong type', () {
      const meta = GuardMeta({'name': 'test'});
      expect(meta.get<int>('name'), isNull);
    });

    test('getOrDefault returns value when present', () {
      const meta = GuardMeta({'count': 42});
      expect(meta.getOrDefault<int>('count', 0), 42);
    });

    test('getOrDefault returns default when absent', () {
      const meta = GuardMeta({});
      expect(meta.getOrDefault<int>('count', 99), 99);
    });

    test('has returns true for existing key', () {
      const meta = GuardMeta({'key': 'value'});
      expect(meta.has('key'), isTrue);
    });

    test('has returns false for missing key', () {
      const meta = GuardMeta({});
      expect(meta.has('key'), isFalse);
    });

    test('merge combines metadata with other taking precedence', () {
      const a = GuardMeta({'x': 1, 'y': 2});
      const b = GuardMeta({'y': 3, 'z': 4});
      final merged = a.merge(b);
      expect(merged.get<int>('x'), 1);
      expect(merged.get<int>('y'), 3);
      expect(merged.get<int>('z'), 4);
    });

    test('empty is truly empty', () {
      expect(GuardMeta.empty.has('anything'), isFalse);
    });

    test('equality works', () {
      const a = GuardMeta({'x': 1});
      const b = GuardMeta({'x': 1});
      expect(a, equals(b));
    });

    test('inequality works', () {
      const a = GuardMeta({'x': 1});
      const b = GuardMeta({'x': 2});
      expect(a, isNot(equals(b)));
    });
  });

  group('Guard composition', () {
    testWidgets('AndGuard passes when both pass', (tester) async {
      final guard = _AllowGuard() & _AllowGuard();
      final router = GoRouter(
        initialLocation: '/test',
        routes: [
          GoRoute(
            path: '/test',
            redirect: (context, state) async {
              return guard.check(context, state, GuardMeta.empty);
            },
            builder: (_, __) => const Text('test'),
          ),
        ],
      );
      await _pumpRouter(tester, router);
      expect(find.text('test'), findsOneWidget);
    });

    testWidgets('AndGuard fails when left fails', (tester) async {
      final guard = _DenyGuard('/denied') & _AllowGuard();
      final router = GoRouter(
        initialLocation: '/test',
        routes: [
          GoRoute(
            path: '/test',
            redirect: (context, state) async {
              return guard.check(context, state, GuardMeta.empty);
            },
            builder: (_, __) => const Text('test'),
          ),
          GoRoute(
            path: '/denied',
            builder: (_, __) => const Text('denied'),
          ),
        ],
      );
      await _pumpRouter(tester, router);
      expect(find.text('denied'), findsOneWidget);
    });

    testWidgets('AndGuard fails when right fails', (tester) async {
      final guard = _AllowGuard() & _DenyGuard('/denied');
      final router = GoRouter(
        initialLocation: '/test',
        routes: [
          GoRoute(
            path: '/test',
            redirect: (context, state) async {
              return guard.check(context, state, GuardMeta.empty);
            },
            builder: (_, __) => const Text('test'),
          ),
          GoRoute(
            path: '/denied',
            builder: (_, __) => const Text('denied'),
          ),
        ],
      );
      await _pumpRouter(tester, router);
      expect(find.text('denied'), findsOneWidget);
    });

    testWidgets('OrGuard passes when left passes', (tester) async {
      final guard = _AllowGuard() | _DenyGuard('/denied');
      final router = GoRouter(
        initialLocation: '/test',
        routes: [
          GoRoute(
            path: '/test',
            redirect: (context, state) async {
              return guard.check(context, state, GuardMeta.empty);
            },
            builder: (_, __) => const Text('test'),
          ),
          GoRoute(
            path: '/denied',
            builder: (_, __) => const Text('denied'),
          ),
        ],
      );
      await _pumpRouter(tester, router);
      expect(find.text('test'), findsOneWidget);
    });

    testWidgets('OrGuard passes when right passes', (tester) async {
      final guard = _DenyGuard('/denied') | _AllowGuard();
      final router = GoRouter(
        initialLocation: '/test',
        routes: [
          GoRoute(
            path: '/test',
            redirect: (context, state) async {
              return guard.check(context, state, GuardMeta.empty);
            },
            builder: (_, __) => const Text('test'),
          ),
          GoRoute(
            path: '/denied',
            builder: (_, __) => const Text('denied'),
          ),
        ],
      );
      await _pumpRouter(tester, router);
      expect(find.text('test'), findsOneWidget);
    });

    testWidgets('OrGuard fails when both fail', (tester) async {
      final guard = _DenyGuard('/denied') | _DenyGuard('/other');
      final router = GoRouter(
        initialLocation: '/test',
        routes: [
          GoRoute(
            path: '/test',
            redirect: (context, state) async {
              return guard.check(context, state, GuardMeta.empty);
            },
            builder: (_, __) => const Text('test'),
          ),
          GoRoute(
            path: '/denied',
            builder: (_, __) => const Text('denied'),
          ),
          GoRoute(
            path: '/other',
            builder: (_, __) => const Text('other'),
          ),
        ],
      );
      await _pumpRouter(tester, router);
      expect(find.text('denied'), findsOneWidget);
    });

    testWidgets('NotGuard inverts allow to deny', (tester) async {
      final guard = ~_AllowGuard();
      final router = GoRouter(
        initialLocation: '/test',
        routes: [
          GoRoute(
            path: '/test',
            redirect: (context, state) async {
              return guard.check(context, state, GuardMeta.empty);
            },
            builder: (_, __) => const Text('test'),
          ),
          GoRoute(
            path: '/',
            builder: (_, __) => const Text('root'),
          ),
        ],
      );
      await _pumpRouter(tester, router);
      expect(find.text('root'), findsOneWidget);
    });

    testWidgets('NotGuard inverts deny to allow', (tester) async {
      final guard = ~_DenyGuard('/denied');
      final router = GoRouter(
        initialLocation: '/test',
        routes: [
          GoRoute(
            path: '/test',
            redirect: (context, state) async {
              return guard.check(context, state, GuardMeta.empty);
            },
            builder: (_, __) => const Text('test'),
          ),
          GoRoute(
            path: '/denied',
            builder: (_, __) => const Text('denied'),
          ),
        ],
      );
      await _pumpRouter(tester, router);
      expect(find.text('test'), findsOneWidget);
    });
  });

  group('GuardChain', () {
    testWidgets('existingWins runs existing first', (tester) async {
      final redirect = GuardChain.existing(
        (_, __) => '/existing-redirect',
      ).then(_DenyGuard('/guard-redirect')).existingWins();

      final router = GoRouter(
        initialLocation: '/test',
        redirect: redirect,
        routes: [
          GoRoute(
            path: '/test',
            builder: (_, __) => const Text('test'),
          ),
          GoRoute(
            path: '/existing-redirect',
            builder: (_, __) => const Text('existing'),
          ),
          GoRoute(
            path: '/guard-redirect',
            builder: (_, __) => const Text('guard'),
          ),
        ],
      );
      await _pumpRouter(tester, router);
      expect(find.text('existing'), findsOneWidget);
    });

    testWidgets('guardsWin runs guards first', (tester) async {
      final redirect = GuardChain.existing(
        (_, __) => '/existing-redirect',
      ).then(_DenyGuard('/guard-redirect')).guardsWin();

      final router = GoRouter(
        initialLocation: '/test',
        redirect: redirect,
        routes: [
          GoRoute(
            path: '/test',
            builder: (_, __) => const Text('test'),
          ),
          GoRoute(
            path: '/existing-redirect',
            builder: (_, __) => const Text('existing'),
          ),
          GoRoute(
            path: '/guard-redirect',
            builder: (_, __) => const Text('guard'),
          ),
        ],
      );
      await _pumpRouter(tester, router);
      expect(find.text('guard'), findsOneWidget);
    });

    testWidgets('build runs steps in order', (tester) async {
      final redirect = GuardChain.guards([
        _AllowGuard(),
        _DenyGuard('/second'),
      ]).build();

      final router = GoRouter(
        initialLocation: '/test',
        redirect: redirect,
        routes: [
          GoRoute(
            path: '/test',
            builder: (_, __) => const Text('test'),
          ),
          GoRoute(
            path: '/second',
            builder: (_, __) => const Text('second'),
          ),
        ],
      );
      await _pumpRouter(tester, router);
      expect(find.text('second'), findsOneWidget);
    });

    testWidgets('build with all passing guards allows through',
        (tester) async {
      final redirect = GuardChain.guards([
        _AllowGuard(),
        _AllowGuard(),
      ]).build();

      final router = GoRouter(
        initialLocation: '/test',
        redirect: redirect,
        routes: [
          GoRoute(
            path: '/test',
            builder: (_, __) => const Text('test'),
          ),
        ],
      );
      await _pumpRouter(tester, router);
      expect(find.text('test'), findsOneWidget);
    });

    testWidgets('thenRaw integrates raw redirects', (tester) async {
      final redirect = GuardChain.guards([_AllowGuard()])
          .thenRaw((_, __) => '/raw-result')
          .build();

      final router = GoRouter(
        initialLocation: '/test',
        redirect: redirect,
        routes: [
          GoRoute(
            path: '/test',
            builder: (_, __) => const Text('test'),
          ),
          GoRoute(
            path: '/raw-result',
            builder: (_, __) => const Text('raw'),
          ),
        ],
      );
      await _pumpRouter(tester, router);
      expect(find.text('raw'), findsOneWidget);
    });
  });

  group('Async guards', () {
    testWidgets('async allow guard permits access', (tester) async {
      final redirect = GuardChain.guards([_AsyncAllowGuard()]).build();

      final router = GoRouter(
        initialLocation: '/test',
        redirect: redirect,
        routes: [
          GoRoute(
            path: '/test',
            builder: (_, __) => const Text('test'),
          ),
        ],
      );
      await _pumpRouter(tester, router);
      expect(find.text('test'), findsOneWidget);
    });

    testWidgets('async deny guard redirects', (tester) async {
      final redirect = GuardChain.guards([
        _AsyncDenyGuard('/denied'),
      ]).build();

      final router = GoRouter(
        initialLocation: '/test',
        redirect: redirect,
        routes: [
          GoRoute(
            path: '/test',
            builder: (_, __) => const Text('test'),
          ),
          GoRoute(
            path: '/denied',
            builder: (_, __) => const Text('denied'),
          ),
        ],
      );
      await _pumpRouter(tester, router);
      expect(find.text('denied'), findsOneWidget);
    });
  });

  group('AuthGuard', () {
    testWidgets('preserveDeepLink appends continue param', (tester) async {
      String? capturedRedirect;

      final guard = AuthGuard(
        isAuthenticated: (_) => false,
        redirectTo: '/login',
        preserveDeepLink: true,
      );

      final router = GoRouter(
        initialLocation: '/dashboard/settings',
        routes: [
          GoRoute(
            path: '/dashboard/settings',
            redirect: (context, state) async {
              capturedRedirect =
                  await guard.check(context, state, GuardMeta.empty);
              return capturedRedirect;
            },
            builder: (_, __) => const Text('settings'),
          ),
          GoRoute(
            path: '/login',
            builder: (_, __) => const Text('login'),
          ),
        ],
      );
      await _pumpRouter(tester, router);

      expect(capturedRedirect, contains('/login'));
      expect(capturedRedirect, contains('continue'));
      expect(capturedRedirect, contains('/dashboard/settings'));
    });

    testWidgets('authenticated user passes through', (tester) async {
      final guard = AuthGuard(
        isAuthenticated: (_) => true,
        redirectTo: '/login',
      );

      final router = GoRouter(
        initialLocation: '/test',
        routes: [
          GoRoute(
            path: '/test',
            redirect: (context, state) async {
              return guard.check(context, state, GuardMeta.empty);
            },
            builder: (_, __) => const Text('test'),
          ),
          GoRoute(
            path: '/login',
            builder: (_, __) => const Text('login'),
          ),
        ],
      );
      await _pumpRouter(tester, router);
      expect(find.text('test'), findsOneWidget);
    });
  });
}
