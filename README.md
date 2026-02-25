# go_guardian

NestJS-style route guards for [GoRouter](https://pub.dev/packages/go_router). Declare guards on routes, inherit them through shells, compose them with existing redirects.

Works with **every** state management approach — Provider, Bloc, Riverpod, GetX, Signals, or plain singletons.

```dart
GuardedRoute(
  path: '/dashboard',
  guards: [AuthGuard.stateless(isAuthenticated: () => auth.isLoggedIn)],
  builder: (_, __) => DashboardScreen(),
)
```

> **[Full documentation &rarr;](https://vipinvkmenon.github.io/go_guardian/)**

---

## Install

```yaml
dependencies:
  go_guardian: ^0.2.0
```

One import gives you everything — `go_guardian` re-exports `go_router`:

```dart
import 'package:go_guardian/go_guardian.dart'; // includes GoRouter, GoRoute, etc.
```

## 30-second overview

**1. Pick a guard** — four are built-in:

| Guard | What it checks | Default redirect |
|---|---|---|
| `AuthGuard` | Is the user logged in? | `/login` |
| `RoleGuard` | Does the user have a required role? | `/unauthorized` |
| `OnboardingGuard` | Has the user finished onboarding? | `/onboarding` |
| `MaintenanceGuard` | Is the app under maintenance? | `/maintenance` |

**2. Attach it to a route:**

```dart
GuardedRoute(
  path: '/admin',
  guards: [RoleGuard.stateless(hasRole: (roles) => user.hasAny(roles))],
  guardMeta: GuardMeta({'roles': ['admin']}),
  builder: (_, __) => AdminScreen(),
)
```

**3. Or inherit through a shell:**

```dart
GuardedShellRoute(
  guards: [AuthGuard.stateless(isAuthenticated: () => auth.isLoggedIn)],
  builder: (ctx, state, child) => AppShell(child: child),
  routes: [
    GuardedRoute(path: '/home', ...),   // inherits AuthGuard
    GuardedRoute(path: '/profile', ...), // inherits AuthGuard
  ],
)
```

**4. Redirect *away* from routes with `DiscardedRoute`:**

```dart
DiscardedRoute.stateless(
  path: '/login',
  discardWhen: () => auth.isLoggedIn,
  redirectTo: '/home',
  builder: (_, __) => LoginScreen(),
)
```

**5. Reactive re-evaluation:**

```dart
GoRouter(
  refreshListenable: GuardRefreshNotifier.from([authNotifier, configNotifier]),
  routes: [ ... ],
)
```

That's it. Guards run in priority order, the first redirect wins.

---

## State management

Every built-in guard has two constructors — one that receives `BuildContext`, one that doesn't:

```dart
// Provider / Bloc
AuthGuard(isAuthenticated: (ctx) => ctx.read<AuthService>().isLoggedIn)

// Riverpod
AuthGuard.stateless(isAuthenticated: () => ref.read(authProvider).isLoggedIn)

// GetX
AuthGuard.stateless(isAuthenticated: () => Get.find<AuthCtrl>().isLoggedIn)

// Signals
AuthGuard.stateless(isAuthenticated: () => isLoggedIn.value)

// Singleton
AuthGuard.stateless(isAuthenticated: () => AuthService.instance.isLoggedIn)
```

## Custom guards

Extend `RouteGuard` and implement `check()`:

```dart
class SubscriptionGuard extends RouteGuard {
  @override
  int get priority => 15; // lower = runs first

  @override
  FutureOr<String?> check(BuildContext context, GoRouterState state, GuardMeta meta) {
    if (hasActiveSubscription) return null; // allow
    return '/subscribe';                    // redirect
  }
}
```

## Guard composition

Combine guards inline with `&` (AND), `|` (OR), and `~` (NOT):

```dart
guards: [AuthGuard(...) & (PremiumGuard(...) | TrialGuard(...))]
```

## Brownfield migration

Already have `redirect:` functions? Wrap them with `GuardChain`:

```dart
redirect: GuardChain
  .existing(myOldRedirect)
  .then(AuthGuard.stateless(isAuthenticated: () => auth.isLoggedIn))
  .existingWins(), // old redirect runs first; swap to .guardsWin() when ready
```

## Debugging

```dart
if (kDebugMode) GoGuardian.observer = DebugGuardObserver();
```

Prints every guard evaluation with timing to the console.

## Testing

Unit-test guards without a widget tree:

```dart
final harness = GuardTestHarness();
final result = await harness.check(AuthGuard.stateless(isAuthenticated: () => true));
expect(result, isNull); // null = allowed
```

---

## Example app

The [`example/`](example/) folder is a runnable Flutter app where you start as a guest and progressively unlock access — login, onboarding, admin promotion, and maintenance mode. It demonstrates guard inheritance, `DiscardedRoute`, and debug logging across four small files:

| File | Purpose |
|---|---|
| `main.dart` | App entry point and debug observer setup |
| `src/services.dart` | `AuthService` and `AppConfig` singletons |
| `src/router.dart` | Full `GoRouter` config with guards |
| `src/screens.dart` | All UI screens |

## Requirements

Dart `>=3.0.0`, Flutter `>=3.10.0`, go_router `>=13.0.0 <16.0.0`.

## License

MIT
