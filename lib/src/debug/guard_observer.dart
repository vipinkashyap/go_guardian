import 'package:flutter/foundation.dart';

import 'guard_event.dart';

/// Observer for guard evaluation lifecycle events.
///
/// Implement this to add custom logging, analytics, or debugging.
///
/// Example:
/// ```dart
/// GoGuardian.observer = DebugGuardObserver();
/// ```
abstract class GuardObserver {
  /// Called for every guard event during evaluation.
  void onEvent(GuardEvent event);
}

/// Built-in observer that logs all guard events to the debug console.
///
/// Usage:
/// ```dart
/// GoGuardian.observer = DebugGuardObserver();
/// ```
class DebugGuardObserver extends GuardObserver {
  @override
  void onEvent(GuardEvent event) {
    debugPrint('[GoGuardian] $event');
  }
}

/// Global configuration for go_guardian.
///
/// Set [observer] to receive guard evaluation events for debugging
/// and monitoring.
///
/// ```dart
/// void main() {
///   if (kDebugMode) {
///     GoGuardian.observer = DebugGuardObserver();
///   }
///   runApp(MyApp());
/// }
/// ```
class GoGuardian {
  GoGuardian._();

  /// Global guard observer. Set to receive evaluation events.
  /// Set to `null` to disable event emission (default).
  static GuardObserver? observer;

  /// Emit an event to the global observer, if set.
  static void emit(GuardEvent event) {
    observer?.onEvent(event);
  }
}
