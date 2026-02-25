# go_guardian example

A runnable Flutter app demonstrating all go_guardian features: login, onboarding, role-based access, maintenance mode, and debug logging.

## Running

```bash
flutter run
```

## Structure

| File | Purpose |
|---|---|
| `lib/main.dart` | App entry point and debug observer |
| `lib/src/services.dart` | `AuthService` and `AppConfig` singletons |
| `lib/src/router.dart` | GoRouter config with guards |
| `lib/src/screens.dart` | All UI screens |
