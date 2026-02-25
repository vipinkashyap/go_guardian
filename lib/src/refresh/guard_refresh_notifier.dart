import 'dart:async';

import 'package:flutter/foundation.dart';

/// A [Listenable] that composes multiple state sources into a single
/// refresh signal for `GoRouter.refreshListenable`.
///
/// When any attached [Listenable] or [Stream] fires, this notifier
/// triggers a GoRouter refresh, causing all guards to re-evaluate.
///
/// **With ChangeNotifier (Provider):**
/// ```dart
/// GoRouter(
///   refreshListenable: GuardRefreshNotifier.from([authNotifier]),
/// )
/// ```
///
/// **With Bloc streams:**
/// ```dart
/// GoRouter(
///   refreshListenable: GuardRefreshNotifier.fromStreams([authBloc.stream]),
/// )
/// ```
///
/// **Mixed sources:**
/// ```dart
/// GoRouter(
///   refreshListenable: GuardRefreshNotifier(
///     listenables: [authNotifier, themeNotifier],
///     streams: [featureFlagStream],
///   ),
/// )
/// ```
class GuardRefreshNotifier extends ChangeNotifier {
  /// Creates a [GuardRefreshNotifier] with optional [listenables] and [streams].
  GuardRefreshNotifier({
    List<Listenable>? listenables,
    List<Stream<dynamic>>? streams,
  })  : _listenables = listenables ?? [],
        _subscriptions = [] {
    for (final listenable in _listenables) {
      listenable.addListener(_onRefresh);
    }
    if (streams != null) {
      for (final stream in streams) {
        _subscriptions.add(stream.listen((_) => _onRefresh()));
      }
    }
  }

  /// Creates a [GuardRefreshNotifier] from a list of [Listenable]s.
  ///
  /// Convenience factory for the common case of composing ChangeNotifiers.
  ///
  /// ```dart
  /// GuardRefreshNotifier.from([authNotifier, userNotifier])
  /// ```
  factory GuardRefreshNotifier.from(List<Listenable> listenables) {
    return GuardRefreshNotifier(listenables: listenables);
  }

  /// Creates a [GuardRefreshNotifier] from a list of [Stream]s.
  ///
  /// Useful for Bloc integration where state changes come as streams.
  ///
  /// ```dart
  /// GuardRefreshNotifier.fromStreams([authBloc.stream, settingsBloc.stream])
  /// ```
  factory GuardRefreshNotifier.fromStreams(List<Stream<dynamic>> streams) {
    return GuardRefreshNotifier(streams: streams);
  }

  final List<Listenable> _listenables;
  final List<StreamSubscription<dynamic>> _subscriptions;

  void _onRefresh() {
    notifyListeners();
  }

  /// Add a [Listenable] to listen to. When it fires, guards re-evaluate.
  void addListenable(Listenable listenable) {
    _listenables.add(listenable);
    listenable.addListener(_onRefresh);
  }

  /// Remove a [Listenable] from the composition.
  void removeListenable(Listenable listenable) {
    listenable.removeListener(_onRefresh);
    _listenables.remove(listenable);
  }

  /// Add a [Stream] to listen to. When it emits, guards re-evaluate.
  void addStream(Stream<dynamic> stream) {
    _subscriptions.add(stream.listen((_) => _onRefresh()));
  }

  @override
  void dispose() {
    for (final listenable in _listenables) {
      listenable.removeListener(_onRefresh);
    }
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _listenables.clear();
    _subscriptions.clear();
    super.dispose();
  }
}
