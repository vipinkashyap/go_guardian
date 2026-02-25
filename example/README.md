# go_guardian example

A runnable Flutter app demonstrating every go_guardian feature. Start as a guest and progressively unlock access — each tab showcases a different guard feature.

## Running

```bash
flutter run
```

## What each screen demos

| Tab / Screen | Feature |
|---|---|
| Login | `DiscardedRoute` + deep link `?continue=` banner |
| Onboarding | `OnboardingGuard` redirect |
| Home | Inherited shell guards, toggle controls, access status |
| Admin | `RoleGuard` + `GuardMeta` |
| Premium | Custom `PremiumGuard` (extends `RouteGuard` directly) |
| VIP Lounge | Guard composition: `RoleGuard \| PremiumGuard` |
| Settings | `GuardChain` brownfield migration |
| Maintenance | `MaintenanceGuard` (priority -10) |

## Structure

| File | Purpose |
|---|---|
| `lib/main.dart` | App entry point and `DebugGuardObserver` setup |
| `lib/src/guards.dart` | Custom `PremiumGuard` — shows extending `RouteGuard` |
| `lib/src/services.dart` | `AuthService` and `AppConfig` singletons |
| `lib/src/router.dart` | Full `GoRouter` config with all guard features |
| `lib/src/screens.dart` | All UI screens with inline code snippets |
