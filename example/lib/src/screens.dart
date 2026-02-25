// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';
import 'package:go_guardian/go_guardian.dart';

import 'services.dart';

// ── Login ──────────────────────────────────────────────────────────────

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _controller = TextEditingController(text: 'Alex');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // ── Deep link preservation ──────────────────────────────────────
    // AuthGuard appends ?continue=/original/path when redirecting here.
    // Read it from the URL and show a banner so the user sees it working.
    final continueUrl =
        GoRouterState.of(context).uri.queryParameters['continue'];

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.shield, size: 64, color: theme.colorScheme.primary),
            const SizedBox(height: 12),
            Text('go_guardian demo',
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Log in to start exploring guards',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.outline)),

            // Deep link banner
            if (continueUrl != null) ...[
              const SizedBox(height: 16),
              Card(
                color: theme.colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(children: [
                    Icon(Icons.link,
                        size: 18, color: theme.colorScheme.onPrimaryContainer),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Deep link preserved! After login you\'ll return to $continueUrl',
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer),
                      ),
                    ),
                  ]),
                ),
              ),
            ],

            const SizedBox(height: 32),
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'Your name',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.login),
                label: const Text('Log in'),
                onPressed: () {
                  final name = _controller.text.trim();
                  if (name.isEmpty) return;
                  AuthService.instance.login(name);
                  // If there's a deep link, go there; otherwise /home.
                  context.go(continueUrl ?? '/home');
                },
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'AuthGuard blocks all protected routes until you log in.\n'
              'After login, OnboardingGuard will redirect you to onboarding.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.outline),
            ),
          ]),
        ),
      ),
    );
  }
}

// ── Onboarding ─────────────────────────────────────────────────────────

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Welcome')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.rocket_launch, size: 56, color: Colors.orange),
            const SizedBox(height: 16),
            Text('Complete your profile',
                style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'OnboardingGuard redirected you here because\n'
              'isOnboarded is false. Tap below to continue.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.outline),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              icon: const Icon(Icons.check),
              label: const Text('Finish onboarding'),
              onPressed: () {
                AuthService.instance.completeOnboarding();
                context.go('/home');
              },
            ),
          ]),
        ),
      ),
    );
  }
}

// ── App Shell ──────────────────────────────────────────────────────────

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _navIndex(context),
        onDestinationSelected: (i) => context.go(
            ['/home', '/admin', '/premium', '/vip-lounge', '/settings'][i]),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(
              icon: Icon(Icons.admin_panel_settings_outlined), label: 'Admin'),
          NavigationDestination(
              icon: Icon(Icons.star_outline), label: 'Premium'),
          NavigationDestination(
              icon: Icon(Icons.diamond_outlined), label: 'VIP'),
          NavigationDestination(
              icon: Icon(Icons.settings_outlined), label: 'Settings'),
        ],
      ),
    );
  }

  int _navIndex(BuildContext context) {
    final loc = GoRouterState.of(context).uri.path;
    if (loc.startsWith('/admin')) return 1;
    if (loc.startsWith('/premium')) return 2;
    if (loc.startsWith('/vip')) return 3;
    if (loc.startsWith('/settings')) return 4;
    return 0;
  }
}

// ── Home ───────────────────────────────────────────────────────────────

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AuthService.instance;
    final config = AppConfig.instance;
    final theme = Theme.of(context);

    return ListenableBuilder(
      listenable: Listenable.merge([auth, config]),
      builder: (context, _) {
        final isAdmin = auth.roles.contains('admin');

        return CustomScrollView(slivers: [
          SliverAppBar.large(
            title: Text('Hi, ${auth.userName}'),
            actions: [
              IconButton(
                tooltip: 'Log out',
                icon: const Icon(Icons.logout),
                onPressed: () {
                  auth.logout();
                  context.go('/login');
                },
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            sliver: SliverList.list(children: [
              // ── Access status card ────────────────────────────────
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Your access',
                            style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.primary)),
                        const SizedBox(height: 12),
                        _accessRow(Icons.check_circle, 'Logged in', true),
                        _accessRow(Icons.check_circle, 'Onboarded',
                            auth.isOnboarded),
                        _accessRow(
                            Icons.admin_panel_settings, 'Admin role', isAdmin),
                        _accessRow(Icons.star, 'Premium', auth.isPremium),
                        _accessRow(Icons.construction, 'Maintenance OFF',
                            !config.maintenance),
                      ]),
                ),
              ),
              const SizedBox(height: 24),

              // ── Controls ─────────────────────────────────────────
              Text('Try it',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(
                'Toggle these, then tap a tab in the bottom nav.',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.outline),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text('Admin role'),
                subtitle: Text(isAdmin
                    ? 'RoleGuard will allow /admin'
                    : 'RoleGuard will block /admin'),
                secondary: Icon(isAdmin
                    ? Icons.admin_panel_settings
                    : Icons.person),
                value: isAdmin,
                onChanged: (_) =>
                    isAdmin ? auth.demoteFromAdmin() : auth.promoteToAdmin(),
              ),
              SwitchListTile(
                title: const Text('Premium'),
                subtitle: Text(auth.isPremium
                    ? 'PremiumGuard will allow /premium'
                    : 'PremiumGuard will block /premium'),
                secondary: Icon(auth.isPremium
                    ? Icons.star
                    : Icons.star_outline),
                value: auth.isPremium,
                onChanged: (_) => auth.togglePremium(),
              ),
              SwitchListTile(
                title: const Text('Maintenance mode'),
                subtitle: Text(config.maintenance
                    ? 'MaintenanceGuard blocks everything'
                    : 'All routes accessible'),
                secondary: Icon(config.maintenance
                    ? Icons.construction
                    : Icons.check_circle_outline),
                value: config.maintenance,
                onChanged: (_) => config.toggleMaintenance(),
              ),

              const SizedBox(height: 24),

              // ── Feature legend ────────────────────────────────────
              Card(
                color: theme.colorScheme.surfaceContainerHighest,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('What each tab demos',
                            style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        _legend('Admin', 'RoleGuard + GuardMeta'),
                        _legend('Premium', 'Custom PremiumGuard'),
                        _legend('VIP', 'Composition: Admin | Premium'),
                        _legend('Settings', 'GuardChain brownfield'),
                      ]),
                ),
              ),
            ]),
          ),
        ]);
      },
    );
  }

  Widget _accessRow(IconData icon, String label, bool ok) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(children: [
        Icon(icon,
            size: 18, color: ok ? Colors.green : Colors.red.shade300),
        const SizedBox(width: 8),
        Text(label,
            style: TextStyle(
                color: ok ? null : Colors.red.shade300,
                fontWeight: ok ? FontWeight.normal : FontWeight.w500)),
      ]),
    );
  }

  Widget _legend(String tab, String feature) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(children: [
        SizedBox(
          width: 70,
          child: Text(tab,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(feature,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
        ),
      ]),
    );
  }
}

// ── Admin ──────────────────────────────────────────────────────────────

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _FeatureScreen(
      icon: Icons.admin_panel_settings,
      color: Colors.teal,
      title: 'Admin Dashboard',
      subtitle: 'RoleGuard confirmed your "admin" role via GuardMeta.',
      feature: 'RoleGuard + GuardMeta',
      code: 'GuardedRoute(\n'
          '  path: \'/admin\',\n'
          '  guards: [RoleGuard.stateless(hasRole: ...)],\n'
          '  guardMeta: GuardMeta({\'roles\': [\'admin\']}),\n'
          ')',
    );
  }
}

// ── Premium ────────────────────────────────────────────────────────────

class PremiumScreen extends StatelessWidget {
  const PremiumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _FeatureScreen(
      icon: Icons.star,
      color: Colors.amber.shade700,
      title: 'Premium Content',
      subtitle: 'Custom PremiumGuard (extends RouteGuard) allowed this.',
      feature: 'Custom guard',
      code: 'class PremiumGuard extends RouteGuard {\n'
          '  @override\n'
          '  FutureOr<String?> check(...) {\n'
          '    if (isPremium) return null;\n'
          '    return \'/paywall\';\n'
          '  }\n'
          '}',
    );
  }
}

// ── VIP Lounge ─────────────────────────────────────────────────────────

class VipLoungeScreen extends StatelessWidget {
  const VipLoungeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AuthService.instance;
    final isAdmin = auth.roles.contains('admin');
    final reason =
        isAdmin ? 'your admin role' : (auth.isPremium ? 'premium status' : '?');

    return _FeatureScreen(
      icon: Icons.diamond,
      color: Colors.purple,
      title: 'VIP Lounge',
      subtitle: 'You got in via $reason.\n'
          'Guard composition: RoleGuard | PremiumGuard.',
      feature: 'Composition: | (OR)',
      code: 'guards: [\n'
          '  RoleGuard.stateless(...) |\n'
          '      PremiumGuard.stateless(...),\n'
          ']',
    );
  }
}

// ── Settings ───────────────────────────────────────────────────────────

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _FeatureScreen(
      icon: Icons.settings,
      color: Colors.blueGrey,
      title: 'Settings',
      subtitle: 'This route uses GuardChain to wrap a legacy redirect\n'
          'alongside go_guardian guards. Brownfield migration.',
      feature: 'GuardChain brownfield',
      code: 'redirect: GuardChain\n'
          '  .existing(myLegacyRedirect)\n'
          '  .then(AuthGuard.stateless(...))\n'
          '  .existingWins(),',
    );
  }
}

// ── Reusable feature screen ────────────────────────────────────────────

class _FeatureScreen extends StatelessWidget {
  const _FeatureScreen({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.feature,
    required this.code,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String feature;
  final String code;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 56, color: color),
            const SizedBox(height: 12),
            Text(title,
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(subtitle, textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.outline)),
            const SizedBox(height: 20),
            // Feature badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(feature,
                  style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w600,
                      fontSize: 13)),
            ),
            const SizedBox(height: 16),
            // Code snippet
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(code,
                  style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: theme.colorScheme.onSurfaceVariant)),
            ),
          ]),
        ),
      ),
    );
  }
}

// ── Reusable message screen ────────────────────────────────────────────

class MessageScreen extends StatelessWidget {
  const MessageScreen({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    this.goTo,
    this.goLabel,
  });

  final IconData icon;
  final String title;
  final String body;
  final String? goTo;
  final String? goLabel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 56, color: Colors.red),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(body, textAlign: TextAlign.center),
            if (goTo != null) ...[
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => context.go(goTo!),
                child: Text(goLabel ?? 'Go back'),
              ),
            ],
          ]),
        ),
      ),
    );
  }
}
