import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_guardian/go_guardian.dart';

/// Helper to pump a router in widget tests.
Future<void> _pumpRouter(WidgetTester tester, GoRouter router) async {
  await tester.pumpWidget(MaterialApp.router(routerConfig: router));
  await tester.pumpAndSettle();
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // ==========================================================================
  // GuardResult
  // ==========================================================================
  group('GuardResult', () {
    test('AllowResult properties', () {
      const result = GuardResult.allow();
      expect(result.isAllowed, isTrue);
      expect(result.isDenied, isFalse);
      expect(result.toRedirectPath(), isNull);
      expect(result.toString(), contains('allow'));
    });

    test('RedirectResult properties', () {
      const result = GuardResult.redirect('/login');
      expect(result.isAllowed, isFalse);
      expect(result.isDenied, isTrue);
      expect(result.toRedirectPath(), '/login');
      expect(result.toString(), contains('/login'));
    });

    test('LoadingResult properties', () {
      const result = GuardResult.loading(message: 'wait');
      expect(result.isAllowed, isFalse);
      expect(result.isDenied, isFalse);
      expect(result.toRedirectPath(), isNull);
      expect(result.toRedirectPath(loadingPath: '/loading'), '/loading');
      expect(result.toString(), contains('wait'));
    });

    test('BlockResult properties', () {
      const result = GuardResult.block('no access');
      expect(result.isAllowed, isFalse);
      expect(result.isDenied, isTrue);
      expect(result.toRedirectPath(), isNull);
      expect(result.toString(), contains('no access'));
    });

    test('sealed class exhaustive switch', () {
      const GuardResult result = GuardResult.allow();
      final label = switch (result) {
        AllowResult() => 'allow',
        RedirectResult() => 'redirect',
        LoadingResult() => 'loading',
        BlockResult() => 'block',
      };
      expect(label, 'allow');
    });
  });

  // ==========================================================================
  // Stateless guards (.stateless() factories)
  // ==========================================================================
  group('Stateless guards', () {
    test('AuthGuard.stateless allows authenticated users', () async {
      final guard = AuthGuard.stateless(isAuthenticated: () => true);
      final harness = GuardTestHarness();
      final result = await harness.check(guard);
      expect(result, isNull);
    });

    test('AuthGuard.stateless redirects unauthenticated users', () async {
      final guard = AuthGuard.stateless(isAuthenticated: () => false);
      final harness = GuardTestHarness();
      final result = await harness.check(guard);
      expect(result, contains('/login'));
    });

    test('AuthGuard.stateless preserves deep link', () async {
      final guard = AuthGuard.stateless(
        isAuthenticated: () => false,
        preserveDeepLink: true,
      );
      final harness = GuardTestHarness(path: '/dashboard/settings');
      final result = await harness.check(guard);
      expect(result, contains('continue'));
      expect(result, contains('/dashboard/settings'));
    });

    test('RoleGuard.stateless allows matching role', () async {
      final guard = RoleGuard.stateless(
        hasRole: (roles) => roles.contains('admin'),
      );
      final harness = GuardTestHarness(
        meta: const GuardMeta({'roles': ['admin', 'editor']}),
      );
      final result = await harness.check(guard);
      expect(result, isNull);
    });

    test('RoleGuard.stateless denies wrong role', () async {
      final guard = RoleGuard.stateless(
        hasRole: (roles) => roles.contains('superadmin'),
      );
      final harness = GuardTestHarness(
        meta: const GuardMeta({'roles': ['admin', 'editor']}),
      );
      final result = await harness.check(guard);
      expect(result, contains('/unauthorized'));
    });

    test('OnboardingGuard.stateless allows onboarded', () async {
      final guard = OnboardingGuard.stateless(isOnboarded: () => true);
      final harness = GuardTestHarness();
      final result = await harness.check(guard);
      expect(result, isNull);
    });

    test('OnboardingGuard.stateless redirects non-onboarded', () async {
      final guard = OnboardingGuard.stateless(isOnboarded: () => false);
      final harness = GuardTestHarness();
      final result = await harness.check(guard);
      expect(result, '/onboarding');
    });

    test('MaintenanceGuard.stateless allows when not under maintenance', () async {
      final guard = MaintenanceGuard.stateless(isUnderMaintenance: () => false);
      final harness = GuardTestHarness();
      final result = await harness.check(guard);
      expect(result, isNull);
    });

    test('MaintenanceGuard.stateless redirects under maintenance', () async {
      final guard = MaintenanceGuard.stateless(isUnderMaintenance: () => true);
      final harness = GuardTestHarness();
      final result = await harness.check(guard);
      expect(result, '/maintenance');
    });
  });

  // ==========================================================================
  // GuardTestHarness
  // ==========================================================================
  group('GuardTestHarness', () {
    test('withMeta returns harness with new metadata', () async {
      final guard = RoleGuard.stateless(
        hasRole: (roles) => roles.contains('admin'),
      );
      final harness = GuardTestHarness();

      // Without meta — no roles key, should allow (no roles to check)
      final r1 = await harness.check(guard);
      expect(r1, isNull);

      // With meta — has admin role
      final r2 = await harness
          .withMeta(const GuardMeta({'roles': ['admin']}))
          .check(guard);
      expect(r2, isNull);

      // With meta — wrong role
      final r3 = await harness
          .withMeta(const GuardMeta({'roles': ['superadmin']}))
          .check(guard);
      expect(r3, isNotNull);
    });

    test('withPath changes the simulated path', () async {
      final guard = AuthGuard.stateless(
        isAuthenticated: () => false,
        preserveDeepLink: true,
      );
      final harness = GuardTestHarness()
          .withPath('/admin/users');
      final result = await harness.check(guard);
      expect(result, contains('/admin/users'));
    });

    test('withQueryParams sets query params', () async {
      final harness = GuardTestHarness()
          .withQueryParams({'tab': 'settings'});
      expect(harness.queryParams, {'tab': 'settings'});
    });

    test('checkAll evaluates guards in priority order', () async {
      final guards = [
        AuthGuard.stateless(isAuthenticated: () => true),
        RoleGuard.stateless(hasRole: (roles) => roles.contains('admin')),
      ];
      final harness = GuardTestHarness(
        meta: const GuardMeta({'roles': ['admin']}),
      );
      final result = await harness.checkAll(guards);
      expect(result, isNull); // Both pass
    });

    test('checkAll returns first failure', () async {
      final guards = [
        AuthGuard.stateless(isAuthenticated: () => false), // priority 10
        RoleGuard.stateless(hasRole: (roles) => false),     // priority 20
      ];
      final harness = GuardTestHarness(
        meta: const GuardMeta({'roles': ['admin']}),
      );
      final result = await harness.checkAll(guards);
      expect(result, contains('/login')); // Auth fails first (priority 10)
    });
  });

  // ==========================================================================
  // DiscardedRoute
  // ==========================================================================
  group('DiscardedRoute', () {
    testWidgets('redirects when discard condition is true', (tester) async {
      final router = GoRouter(
        initialLocation: '/login',
        routes: [
          DiscardedRoute(
            path: '/login',
            discardWhen: (_) => true, // already logged in
            redirectTo: '/home',
            builder: (_, __) => const Text('login'),
          ),
          GoRoute(
            path: '/home',
            builder: (_, __) => const Text('home'),
          ),
        ],
      );
      await _pumpRouter(tester, router);
      expect(find.text('home'), findsOneWidget);
    });

    testWidgets('allows access when discard condition is false', (tester) async {
      final router = GoRouter(
        initialLocation: '/login',
        routes: [
          DiscardedRoute(
            path: '/login',
            discardWhen: (_) => false, // not logged in
            redirectTo: '/home',
            builder: (_, __) => const Text('login'),
          ),
          GoRoute(
            path: '/home',
            builder: (_, __) => const Text('home'),
          ),
        ],
      );
      await _pumpRouter(tester, router);
      expect(find.text('login'), findsOneWidget);
    });

    testWidgets('stateless variant redirects when true', (tester) async {
      final router = GoRouter(
        initialLocation: '/login',
        routes: [
          DiscardedRoute.stateless(
            path: '/login',
            discardWhen: () => true,
            redirectTo: '/home',
            builder: (_, __) => const Text('login'),
          ),
          GoRoute(
            path: '/home',
            builder: (_, __) => const Text('home'),
          ),
        ],
      );
      await _pumpRouter(tester, router);
      expect(find.text('home'), findsOneWidget);
    });

    testWidgets('stateless variant allows when false', (tester) async {
      final router = GoRouter(
        initialLocation: '/login',
        routes: [
          DiscardedRoute.stateless(
            path: '/login',
            discardWhen: () => false,
            redirectTo: '/home',
            builder: (_, __) => const Text('login'),
          ),
          GoRoute(
            path: '/home',
            builder: (_, __) => const Text('home'),
          ),
        ],
      );
      await _pumpRouter(tester, router);
      expect(find.text('login'), findsOneWidget);
    });
  });

  // ==========================================================================
  // GuardRefreshNotifier
  // ==========================================================================
  group('GuardRefreshNotifier', () {
    test('notifies when listenable fires', () {
      final source = ChangeNotifier();
      final notifier = GuardRefreshNotifier.from([source]);

      var notified = false;
      notifier.addListener(() => notified = true);

      // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
      source.notifyListeners();
      expect(notified, isTrue);

      notifier.dispose();
    });

    test('notifies when stream emits', () async {
      final controller = StreamController<int>();
      final notifier = GuardRefreshNotifier.fromStreams([controller.stream]);

      var notified = false;
      notifier.addListener(() => notified = true);

      controller.add(1);
      await Future<void>.delayed(Duration.zero); // let stream deliver
      expect(notified, isTrue);

      await controller.close();
      notifier.dispose();
    });

    test('mixed listenables and streams', () async {
      final listenable = ChangeNotifier();
      final controller = StreamController<int>();
      final notifier = GuardRefreshNotifier(
        listenables: [listenable],
        streams: [controller.stream],
      );

      var count = 0;
      notifier.addListener(() => count++);

      // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
      listenable.notifyListeners();
      expect(count, 1);

      controller.add(42);
      await Future<void>.delayed(Duration.zero);
      expect(count, 2);

      await controller.close();
      notifier.dispose();
    });

    test('addListenable attaches dynamically', () {
      final notifier = GuardRefreshNotifier();
      final source = ChangeNotifier();

      var notified = false;
      notifier.addListener(() => notified = true);

      notifier.addListenable(source);
      // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
      source.notifyListeners();
      expect(notified, isTrue);

      notifier.dispose();
    });

    test('removeListenable detaches', () {
      final source = ChangeNotifier();
      final notifier = GuardRefreshNotifier.from([source]);

      notifier.removeListenable(source);

      var notified = false;
      notifier.addListener(() => notified = true);

      // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
      source.notifyListeners();
      expect(notified, isFalse);

      notifier.dispose();
    });

    test('dispose cleans up all subscriptions', () {
      final source = ChangeNotifier();
      final controller = StreamController<int>.broadcast();
      final notifier = GuardRefreshNotifier(
        listenables: [source],
        streams: [controller.stream],
      );

      notifier.dispose();

      // After dispose, no errors should occur when source fires
      // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
      source.notifyListeners();
      controller.add(1);
      controller.close();
    });
  });

  // ==========================================================================
  // Guard debug events & observer
  // ==========================================================================
  group('Guard observer', () {
    tearDown(() {
      GoGuardian.observer = null;
    });

    test('observer receives events during evaluation', () async {
      final events = <GuardEvent>[];
      GoGuardian.observer = _CollectingObserver(events);

      final guard = AuthGuard.stateless(isAuthenticated: () => true);
      final harness = GuardTestHarness();
      await harness.checkAll([guard]);

      expect(events, isNotEmpty);
      expect(events.first, isA<GuardEvaluationStarted>());
      expect(events.any((e) => e is GuardCheckCompleted), isTrue);
      expect(events.last, isA<GuardChainCompleted>());
    });

    test('GuardEvaluationStarted has correct metadata', () async {
      final events = <GuardEvent>[];
      GoGuardian.observer = _CollectingObserver(events);

      final guards = [
        AuthGuard.stateless(isAuthenticated: () => true),
        MaintenanceGuard.stateless(isUnderMaintenance: () => false),
      ];
      final harness = GuardTestHarness();
      await harness.checkAll(guards);

      final started = events.whereType<GuardEvaluationStarted>().first;
      expect(started.guardCount, 2);
      expect(started.guardTypes, hasLength(2));
    });

    test('GuardCheckCompleted has timing info', () async {
      final events = <GuardEvent>[];
      GoGuardian.observer = _CollectingObserver(events);

      final guard = AuthGuard.stateless(isAuthenticated: () => true);
      final harness = GuardTestHarness();
      await harness.checkAll([guard]);

      final completed = events.whereType<GuardCheckCompleted>().first;
      expect(completed.duration, isNotNull);
      expect(completed.result, isA<AllowResult>());
    });

    test('GuardChainCompleted records final result', () async {
      final events = <GuardEvent>[];
      GoGuardian.observer = _CollectingObserver(events);

      final guard = AuthGuard.stateless(isAuthenticated: () => false);
      final harness = GuardTestHarness();
      await harness.checkAll([guard]);

      final chain = events.whereType<GuardChainCompleted>().first;
      expect(chain.finalResult, isA<RedirectResult>());
      expect(chain.guardsEvaluated, 1);
    });

    test('no observer means no crash', () async {
      GoGuardian.observer = null;
      final guard = AuthGuard.stateless(isAuthenticated: () => true);
      final harness = GuardTestHarness();
      // Should not throw
      await harness.checkAll([guard]);
    });
  });

  // ==========================================================================
  // Integration: stateless guards in GuardedRoute
  // ==========================================================================
  group('Stateless guards in GuardedRoute', () {
    testWidgets('stateless AuthGuard allows in widget tree', (tester) async {
      final router = GoRouter(
        initialLocation: '/dashboard',
        routes: [
          GuardedRoute(
            path: '/dashboard',
            guards: [AuthGuard.stateless(isAuthenticated: () => true)],
            builder: (_, __) => const Text('dashboard'),
          ),
          GoRoute(
            path: '/login',
            builder: (_, __) => const Text('login'),
          ),
        ],
      );
      await _pumpRouter(tester, router);
      expect(find.text('dashboard'), findsOneWidget);
    });

    testWidgets('stateless AuthGuard denies in widget tree', (tester) async {
      final router = GoRouter(
        initialLocation: '/dashboard',
        routes: [
          GuardedRoute(
            path: '/dashboard',
            guards: [AuthGuard.stateless(isAuthenticated: () => false)],
            builder: (_, __) => const Text('dashboard'),
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

    testWidgets('mixed context and stateless guards work together', (tester) async {
      final router = GoRouter(
        initialLocation: '/admin',
        routes: [
          GuardedRoute(
            path: '/admin',
            guards: [
              AuthGuard.stateless(isAuthenticated: () => true),
              RoleGuard.stateless(hasRole: (roles) => roles.contains('admin')),
            ],
            guardMeta: const GuardMeta({'roles': ['admin']}),
            builder: (_, __) => const Text('admin'),
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
      expect(find.text('admin'), findsOneWidget);
    });
  });
}

// ---------------------------------------------------------------------------
// Test observer
// ---------------------------------------------------------------------------

class _CollectingObserver extends GuardObserver {
  _CollectingObserver(this.events);
  final List<GuardEvent> events;

  @override
  void onEvent(GuardEvent event) {
    events.add(event);
  }
}
