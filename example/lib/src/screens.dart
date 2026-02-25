// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';
import 'package:go_guardian/go_guardian.dart';

import 'services.dart';

// ── Login ──────────────────────────────────────────────────────────

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
                  context.go('/home');
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

// ── Onboarding ─────────────────────────────────────────────────────

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

// ── App Shell ──────────────────────────────────────────────────────

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _navIndex(context),
        onDestinationSelected: (i) =>
            context.go(['/home', '/admin', '/settings'][i]),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(
              icon: Icon(Icons.admin_panel_settings_outlined), label: 'Admin'),
          NavigationDestination(
              icon: Icon(Icons.settings_outlined), label: 'Settings'),
        ],
      ),
    );
  }

  int _navIndex(BuildContext context) {
    final loc = GoRouterState.of(context).uri.path;
    if (loc.startsWith('/admin')) return 1;
    if (loc.startsWith('/settings')) return 2;
    return 0;
  }
}

// ── Home ───────────────────────────────────────────────────────────

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
              // Access status
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
                        _accessRow(Icons.construction, 'Maintenance OFF',
                            !config.maintenance),
                      ]),
                ),
              ),
              const SizedBox(height: 24),

              // Controls
              Text('Try it',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(
                'Toggle these, then tap Admin in the bottom nav.',
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
}

// ── Admin ──────────────────────────────────────────────────────────

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin')),
      body: const Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.admin_panel_settings, size: 56, color: Colors.teal),
          SizedBox(height: 12),
          Text('Admin Dashboard',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          SizedBox(height: 4),
          Text('You made it! RoleGuard confirmed your "admin" role.'),
        ]),
      ),
    );
  }
}

// ── Settings ───────────────────────────────────────────────────────

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: const Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.settings, size: 56, color: Colors.blueGrey),
          SizedBox(height: 12),
          Text('Settings',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          SizedBox(height: 4),
          Text('No extra guard — just the inherited shell guards.'),
        ]),
      ),
    );
  }
}

// ── Reusable message screen ────────────────────────────────────────

class MessageScreen extends StatelessWidget {
  const MessageScreen({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

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
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => context.go('/home'),
              child: const Text('Go home'),
            ),
          ]),
        ),
      ),
    );
  }
}
