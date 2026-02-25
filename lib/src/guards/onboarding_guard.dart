import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../meta/guard_meta.dart';
import 'route_guard.dart';

/// Guard that checks whether the user has completed onboarding.
///
/// Redirects users who haven't completed onboarding to the onboarding flow.
///
/// **With BuildContext** (Provider, Bloc, flutter_riverpod):
/// ```dart
/// OnboardingGuard(isOnboarded: (ctx) => ctx.read<AuthService>().isOnboarded)
/// ```
///
/// **Without BuildContext** (GetX, singletons, Riverpod ref, signals):
/// ```dart
/// OnboardingGuard.stateless(isOnboarded: () => AuthService.instance.isOnboarded)
/// ```
class OnboardingGuard extends RouteGuard {
  /// Creates an [OnboardingGuard] with a context-aware callback.
  OnboardingGuard({
    required bool Function(BuildContext) isOnboarded,
    this.redirectTo = '/onboarding',
  })  : _contextCheck = isOnboarded,
        _statelessCheck = null;

  /// Creates an [OnboardingGuard] with a context-free callback.
  ///
  /// ```dart
  /// OnboardingGuard.stateless(isOnboarded: () => prefs.getBool('onboarded') ?? false)
  /// ```
  OnboardingGuard.stateless({
    required bool Function() isOnboarded,
    this.redirectTo = '/onboarding',
  })  : _contextCheck = null,
        _statelessCheck = isOnboarded;

  final bool Function(BuildContext)? _contextCheck;
  final bool Function()? _statelessCheck;

  /// The path to redirect to when onboarding is incomplete.
  final String redirectTo;

  @override
  int get priority => 30;

  @override
  FutureOr<String?> check(
    BuildContext context,
    GoRouterState state,
    GuardMeta meta,
  ) {
    final contextCheck = _contextCheck;
    final statelessCheck = _statelessCheck;
    final onboarded = contextCheck != null
        ? contextCheck(context)
        : statelessCheck!();

    if (onboarded) return null;
    return redirectTo;
  }
}
