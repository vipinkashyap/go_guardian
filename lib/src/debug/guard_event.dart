import '../core/guard_result.dart';

/// Events emitted during guard evaluation.
///
/// Listen to these via [GuardObserver] to debug guard behavior,
/// log evaluation timing, or build developer tooling.
sealed class GuardEvent {
  const GuardEvent({
    required this.routePath,
    required this.timestamp,
  });

  /// The route path being evaluated.
  final String routePath;

  /// When the event occurred.
  final DateTime timestamp;
}

/// Emitted when guard evaluation begins for a route.
class GuardEvaluationStarted extends GuardEvent {
  const GuardEvaluationStarted({
    required super.routePath,
    required super.timestamp,
    required this.guardCount,
    required this.guardTypes,
  });

  /// Total number of guards to evaluate.
  final int guardCount;

  /// Runtime type names of each guard in evaluation order.
  final List<String> guardTypes;

  @override
  String toString() =>
      'GuardEvaluationStarted(route: $routePath, guards: $guardCount [${guardTypes.join(", ")}])';
}

/// Emitted after each individual guard completes its check.
class GuardCheckCompleted extends GuardEvent {
  const GuardCheckCompleted({
    required super.routePath,
    required super.timestamp,
    required this.guardType,
    required this.result,
    required this.duration,
  });

  /// Runtime type name of the guard.
  final String guardType;

  /// The result returned by the guard.
  final GuardResult result;

  /// How long the guard took to evaluate.
  final Duration duration;

  @override
  String toString() =>
      'GuardCheckCompleted(route: $routePath, guard: $guardType, result: $result, ${duration.inMilliseconds}ms)';
}

/// Emitted when the entire guard chain completes for a route.
class GuardChainCompleted extends GuardEvent {
  const GuardChainCompleted({
    required super.routePath,
    required super.timestamp,
    required this.finalResult,
    required this.totalDuration,
    required this.guardsEvaluated,
  });

  /// The final result after all guards ran (or short-circuited).
  final GuardResult finalResult;

  /// Total time for the entire chain.
  final Duration totalDuration;

  /// How many guards were actually evaluated (may be fewer than total
  /// if a guard short-circuited the chain).
  final int guardsEvaluated;

  @override
  String toString() =>
      'GuardChainCompleted(route: $routePath, result: $finalResult, evaluated: $guardsEvaluated, ${totalDuration.inMilliseconds}ms)';
}
