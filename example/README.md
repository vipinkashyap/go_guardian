# go_guardian example

A runnable Flutter app demonstrating every go_guardian feature. Start as a guest and progressively unlock access — each screen showcases a different guard feature.

## Running

```bash
flutter run
```

## Flow

1. **Login** — `DiscardedRoute` skips this screen when already logged in
2. **Onboarding** — `OnboardingGuard` (inherited from shell) redirects here after login
3. **Home** — toggle controls to unlock Admin, Premium, VIP, and Maintenance
4. **Navigate tabs** — each tab demonstrates a different guard feature

## What each screen demos

| Tab / Screen | Feature |
|---|---|
| Login | `DiscardedRoute` + deep link `?continue=` banner |
| Onboarding | `OnboardingGuard` redirect (via shell guard inheritance) |
| Home | Inherited shell guards, toggle controls, access status |
| Admin | `RoleGuard` + `GuardMeta` |
| Premium | Custom `PremiumGuard` (extends `RouteGuard` directly) |
| VIP Lounge | Guard composition: `RoleGuard \| PremiumGuard` |
| Settings | `GuardChain` brownfield migration (plain `GoRoute` — opts out of shell inheritance) |
| Maintenance | `MaintenanceGuard` (priority -10) |

## Structure

| File | Purpose |
|---|---|
| `lib/main.dart` | App entry point and `DebugGuardObserver` setup |
| `lib/src/guards.dart` | Custom `PremiumGuard` — shows extending `RouteGuard` |
| `lib/src/services.dart` | `AuthService` and `AppConfig` singletons |
| `lib/src/router.dart` | Full `GoRouter` config with all guard features |
| `lib/src/screens.dart` | All UI screens with inline code snippets |
