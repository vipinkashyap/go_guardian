import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../core/guard_resolver.dart';
import '../guards/route_guard.dart';
import '../meta/guard_meta.dart';

/// Test harness for evaluating guards in isolation without a widget tree.
///
/// Provides a minimal [BuildContext] and [GoRouterState] so guards can
/// be unit-tested without pumping a full Flutter app.
///
/// ```dart
/// test('AuthGuard allows authenticated users', () async {
///   final guard = AuthGuard.stateless(isAuthenticated: () => true);
///   final harness = GuardTestHarness();
///   final result = await harness.check(guard);
///   expect(result, isNull); // null = allowed
/// });
///
/// test('RoleGuard checks metadata', () async {
///   final guard = RoleGuard.stateless(hasRole: (roles) => roles.contains('admin'));
///   final harness = GuardTestHarness(
///     meta: GuardMeta({'roles': ['admin', 'editor']}),
///   );
///   final result = await harness.check(guard);
///   expect(result, isNull);
/// });
/// ```
class GuardTestHarness {
  /// Creates a [GuardTestHarness] with optional configuration.
  ///
  /// [path] — the simulated route path (default: `/test`).
  /// [pathParams] — simulated path parameters.
  /// [queryParams] — simulated query parameters.
  /// [meta] — [GuardMeta] to pass to guards during evaluation.
  GuardTestHarness({
    this.path = '/test',
    this.pathParams = const {},
    this.queryParams = const {},
    this.meta = GuardMeta.empty,
  });

  /// The simulated route path.
  final String path;

  /// Simulated path parameters (e.g., `{'id': '123'}`).
  final Map<String, String> pathParams;

  /// Simulated query parameters.
  final Map<String, String> queryParams;

  /// Metadata passed to guards during evaluation.
  final GuardMeta meta;

  /// Evaluate a single guard.
  ///
  /// Returns `null` if allowed, or a redirect path string if denied.
  Future<String?> check(RouteGuard guard) async {
    final state = _createState();
    // For .stateless() guards, context is unused.
    // For context-based guards, tests should use widget testing instead.
    final context = _DummyBuildContext();
    return guard.check(context, state, meta);
  }

  /// Evaluate multiple guards in priority order.
  ///
  /// Returns the first non-null redirect, or `null` if all pass.
  Future<String?> checkAll(List<RouteGuard> guards) async {
    final state = _createState();
    final context = _DummyBuildContext();
    return GuardResolver.resolve(
      context: context,
      state: state,
      guards: guards,
      meta: meta,
    );
  }

  /// Returns a new harness with different metadata.
  GuardTestHarness withMeta(GuardMeta newMeta) {
    return GuardTestHarness(
      path: path,
      pathParams: pathParams,
      queryParams: queryParams,
      meta: newMeta,
    );
  }

  /// Returns a new harness with a different path.
  GuardTestHarness withPath(
    String newPath, {
    Map<String, String>? newPathParams,
  }) {
    return GuardTestHarness(
      path: newPath,
      pathParams: newPathParams ?? pathParams,
      queryParams: queryParams,
      meta: meta,
    );
  }

  /// Returns a new harness with different query parameters.
  GuardTestHarness withQueryParams(Map<String, String> newQueryParams) {
    return GuardTestHarness(
      path: path,
      pathParams: pathParams,
      queryParams: newQueryParams,
      meta: meta,
    );
  }

  GoRouterState _createState() {
    final uri = Uri.parse(path).replace(
      queryParameters: queryParams.isEmpty ? null : queryParams,
    );
    final routingConfig = RoutingConfig(
      routes: const <RouteBase>[],
      redirect: (_, __) => null,
    );
    final config = RouteConfiguration(
      ValueNotifier<RoutingConfig>(routingConfig),
      navigatorKey: GlobalKey<NavigatorState>(),
    );
    return GoRouterState(
      config,
      uri: uri,
      matchedLocation: path,
      fullPath: path,
      pageKey: ValueKey<String>(path),
      pathParameters: pathParams,
    );
  }
}

/// Minimal BuildContext for testing `.stateless()` guards.
///
/// Context-based guards (those using `context.read<T>()`) should be tested
/// with `WidgetTester` instead. This dummy context exists so the guard
/// signature is satisfied for stateless guards.
class _DummyBuildContext implements BuildContext {
  @override
  bool get debugDoingBuild => false;

  @override
  InheritedWidget dependOnInheritedElement(
    InheritedElement ancestor, {
    Object? aspect,
  }) =>
      throw _unsupported('dependOnInheritedElement');

  @override
  T? dependOnInheritedWidgetOfExactType<T extends InheritedWidget>({
    Object? aspect,
  }) =>
      throw _unsupported('dependOnInheritedWidgetOfExactType');

  @override
  DiagnosticsNode describeElement(
    String name, {
    DiagnosticsTreeStyle style = DiagnosticsTreeStyle.errorProperty,
  }) =>
      DiagnosticsProperty<String>(name, 'DummyBuildContext');

  @override
  List<DiagnosticsNode> describeMissingAncestor({
    required Type expectedAncestorType,
  }) =>
      const [];

  @override
  DiagnosticsNode describeOwnershipChain(String name) =>
      DiagnosticsProperty<String>(name, 'DummyBuildContext');

  @override
  DiagnosticsNode describeWidget(
    String name, {
    DiagnosticsTreeStyle style = DiagnosticsTreeStyle.errorProperty,
  }) =>
      DiagnosticsProperty<String>(name, 'DummyBuildContext');

  @override
  void dispatchNotification(Notification notification) {}

  @override
  T? findAncestorRenderObjectOfType<T extends RenderObject>() => null;

  @override
  T? findAncestorStateOfType<T extends State<StatefulWidget>>() => null;

  @override
  T? findAncestorWidgetOfExactType<T extends Widget>() => null;

  @override
  RenderObject? findRenderObject() => null;

  @override
  T? findRootAncestorStateOfType<T extends State<StatefulWidget>>() => null;

  @override
  InheritedElement?
      getElementForInheritedWidgetOfExactType<T extends InheritedWidget>() =>
          null;

  @override
  T? getInheritedWidgetOfExactType<T extends InheritedWidget>() => null;

  @override
  bool get mounted => true;

  @override
  BuildOwner? get owner => null;

  @override
  Size? get size => null;

  @override
  void visitAncestorElements(
    ConditionalElementVisitor visitor,
  ) {}

  @override
  void visitChildElements(ElementVisitor visitor) {}

  @override
  Widget get widget => const SizedBox.shrink();

  UnsupportedError _unsupported(String method) => UnsupportedError(
        '$method is not available in GuardTestHarness. '
        'Use WidgetTester for guards that access BuildContext.',
      );

  @override
  dynamic noSuchMethod(Invocation invocation) {
    // Catch any future BuildContext methods added in newer Flutter versions
    return null;
  }
}
