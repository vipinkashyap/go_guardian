import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:go_guardian/go_guardian.dart';

/// ── Custom guard ────────────────────────────────────────────────────
/// Demonstrates extending RouteGuard directly.
///
/// This is what you'd write for any check that isn't covered by the
/// four built-in guards. Override `check()` — return null to allow,
/// or a redirect path to deny.
class PremiumGuard extends RouteGuard {
  PremiumGuard({
    required bool Function(BuildContext) isPremium,
    this.redirectTo = '/paywall',
  })  : _contextCheck = isPremium,
        _statelessCheck = null;

  PremiumGuard.stateless({
    required bool Function() isPremium,
    this.redirectTo = '/paywall',
  })  : _contextCheck = null,
        _statelessCheck = isPremium;

  final bool Function(BuildContext)? _contextCheck;
  final bool Function()? _statelessCheck;
  final String redirectTo;

  @override
  int get priority => 25; // after Auth (10), Role (20), before Onboarding (30)

  @override
  FutureOr<String?> check(
    BuildContext context,
    GoRouterState state,
    GuardMeta meta,
  ) {
    final isPremium = _contextCheck != null
        ? _contextCheck(context)
        : _statelessCheck!();
    if (isPremium) return null;
    return redirectTo;
  }
}
