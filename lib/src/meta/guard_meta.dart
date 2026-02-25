/// Metadata container for route guards.
///
/// Provides a type-safe way to pass configuration data to guards
/// at the route level. Guards can read metadata keys to customize
/// their behavior per-route.
///
/// Example:
/// ```dart
/// GuardedRoute(
///   path: '/admin',
///   guards: [RoleGuard(...)],
///   guardMeta: GuardMeta({'roles': ['admin', 'superadmin']}),
/// )
/// ```
class GuardMeta {
  /// Creates a [GuardMeta] with the given data map.
  const GuardMeta([this._data = const {}]);

  final Map<String, dynamic> _data;

  /// Retrieves a value by [key], cast to type [T].
  /// Returns `null` if the key is absent or the type doesn't match.
  T? get<T>(String key) {
    final value = _data[key];
    if (value is T) return value;
    return null;
  }

  /// Retrieves a value by [key], returning [defaultValue] if absent.
  T getOrDefault<T>(String key, T defaultValue) {
    final value = _data[key];
    if (value is T) return value;
    return defaultValue;
  }

  /// Returns `true` if the metadata contains the given [key].
  bool has(String key) => _data.containsKey(key);

  /// Merges this metadata with [other]. Values from [other] take precedence.
  GuardMeta merge(GuardMeta other) =>
      GuardMeta({..._data, ...other._data});

  /// Returns all entries as an unmodifiable map.
  Map<String, dynamic> toMap() => Map.unmodifiable(_data);

  /// An empty metadata instance.
  static const empty = GuardMeta();

  @override
  String toString() => 'GuardMeta($_data)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GuardMeta &&
          _data.length == other._data.length &&
          _data.entries.every(
            (e) => other._data[e.key] == e.value,
          );

  @override
  int get hashCode => Object.hashAll(
        _data.entries.map((e) => Object.hash(e.key, e.value)),
      );
}
