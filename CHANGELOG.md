## 0.2.3

### Improvements

- Updated go_router dependency


## 0.2.2

### Improvements

- Updated github links to documentation

## 0.2.1

### Bug Fixes

- **`GuardedShellRoute` now actually propagates guards to child routes.** Previously, shell guards were stored as data but never evaluated on child `GuardedRoute`s. Guards are now reconstructed at construction time — shell guards are prepended to each child's own guards, and `GuardMeta` is merged. Nested shells accumulate correctly.
- **`GuardedRoute.existingRedirect` is now a stored field**, so shell route reconstruction can recover it during guard propagation.

### Improvements

- Example app now has a working onboarding flow: login → OnboardingGuard redirects to `/onboarding` → complete → home.
- Expanded test coverage for shell guard inheritance (7 new tests: inherit, allow, combine, nested, meta merge, plain GoRoute opt-out).
- Removed dead `GuardRegistry` class (guard inheritance is now handled at construction time).

## 0.2.0

### Universal State Management Support

- **`.stateless()` factories** on all 4 built-in guards (`AuthGuard`, `RoleGuard`, `OnboardingGuard`, `MaintenanceGuard`). Use `bool Function()` instead of `bool Function(BuildContext)` — works with GetX, Riverpod `ref`, singletons, Signals, or any approach that doesn't need `BuildContext`.

### New Features

- **Re-exports `go_router`** — one import (`package:go_guardian/go_guardian.dart`) gives you everything. No need to add `go_router` to your pubspec separately.
- **`DiscardedRoute`** — inverse of `GuardedRoute`. Redirects AWAY when a condition IS met. Classic use case: `/login` redirects to `/home` when user is already authenticated. Both context-aware and `.stateless()` constructors.
- **`GuardRefreshNotifier`** — composes multiple `Listenable`s and `Stream`s into one `Listenable` for `GoRouter.refreshListenable`. Factory constructors: `.from()`, `.fromStreams()`.
- **`GuardObserver` / `DebugGuardObserver`** — guard evaluation lifecycle events. Set `GoGuardian.observer = DebugGuardObserver()` to log every guard check with timing.
- **`GuardTestHarness`** — unit test guards without a widget tree. `check()`, `checkAll()`, plus builders `withMeta()`, `withPath()`, `withQueryParams()`.

### Example

- Comprehensive example app demonstrating all guard features: inheritance, onboarding flow, DiscardedRoute, maintenance mode, role-based access, custom guards, guard composition, and brownfield migration.

### Internal

- `GuardResolver` emits `GuardEvent`s with per-guard timing via `Stopwatch`.

## 0.1.0

- Initial release
- `RouteGuard` abstract base class with `&`, `|`, `~` composition operators
- `GuardedRoute` — GoRoute with declarative guard support
- `GuardedShellRoute` — ShellRoute with guard inheritance
- `GuardChain` — brownfield migration support for existing redirect logic
- `GuardMeta` — typed metadata container for per-route guard configuration
- Built-in guards: `AuthGuard`, `RoleGuard`, `OnboardingGuard`, `MaintenanceGuard`
- Guard priority ordering
- Deep link preservation on `AuthGuard`
- Example app
