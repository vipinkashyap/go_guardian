import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../meta/guard_meta.dart';
import 'route_guard.dart';

/// Guard that checks whether the app is under maintenance.
///
/// When maintenance mode is active, all protected routes redirect
/// to a maintenance page.
///
/// **With BuildContext** (Provider, Bloc, flutter_riverpod):
/// ```dart
/// MaintenanceGuard(isUnderMaintenance: (ctx) => ctx.read<Config>().maintenance)
/// ```
///
/// **Without BuildContext** (GetX, singletons, Riverpod ref, signals):
/// ```dart
/// MaintenanceGuard.stateless(isUnderMaintenance: () => RemoteConfig.getBool('maintenance'))
/// ```
class MaintenanceGuard extends RouteGuard {
  /// Creates a [MaintenanceGuard] with a context-aware callback.
  MaintenanceGuard({
    required bool Function(BuildContext) isUnderMaintenance,
    this.redirectTo = '/maintenance',
  })  : _contextCheck = isUnderMaintenance,
        _statelessCheck = null;

  /// Creates a [MaintenanceGuard] with a context-free callback.
  ///
  /// ```dart
  /// MaintenanceGuard.stateless(isUnderMaintenance: () => false)
  /// ```
  MaintenanceGuard.stateless({
    required bool Function() isUnderMaintenance,
    this.redirectTo = '/maintenance',
  })  : _contextCheck = null,
        _statelessCheck = isUnderMaintenance;

  final bool Function(BuildContext)? _contextCheck;
  final bool Function()? _statelessCheck;

  /// The path to redirect to during maintenance.
  final String redirectTo;

  @override
  int get priority => -10; // Runs before most guards

  @override
  FutureOr<String?> check(
    BuildContext context,
    GoRouterState state,
    GuardMeta meta,
  ) {
    final contextCheck = _contextCheck;
    final statelessCheck = _statelessCheck;
    final underMaintenance = contextCheck != null
        ? contextCheck(context)
        : statelessCheck!();

    if (underMaintenance) return redirectTo;
    return null;
  }
}
