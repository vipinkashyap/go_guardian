import 'package:flutter/foundation.dart';

/// Simulates an auth backend.
/// The example app uses this to show guards unlocking progressively.
class AuthService extends ChangeNotifier {
  static final instance = AuthService._();
  AuthService._();

  String _userName = '';
  Set<String> _roles = {};
  bool _onboarded = false;
  bool _loggedIn = false;
  bool _isPremium = false;

  String get userName => _userName;
  Set<String> get roles => _roles;
  bool get isOnboarded => _onboarded;
  bool get isLoggedIn => _loggedIn;
  bool get isPremium => _isPremium;

  bool hasAnyRole(List<String> required) =>
      required.any((r) => _roles.contains(r));

  void login(String name) {
    _userName = name;
    _roles = {'user'};
    _onboarded = false;
    _loggedIn = true;
    _isPremium = false;
    notifyListeners();
  }

  void completeOnboarding() {
    _onboarded = true;
    notifyListeners();
  }

  void promoteToAdmin() {
    _roles = {..._roles, 'admin'};
    notifyListeners();
  }

  void demoteFromAdmin() {
    _roles = _roles.where((r) => r != 'admin').toSet();
    notifyListeners();
  }

  void togglePremium() {
    _isPremium = !_isPremium;
    notifyListeners();
  }

  void logout() {
    _userName = '';
    _roles = {};
    _onboarded = false;
    _loggedIn = false;
    _isPremium = false;
    notifyListeners();
  }
}

/// Simulates a remote config / feature-flag service.
class AppConfig extends ChangeNotifier {
  static final instance = AppConfig._();
  AppConfig._();

  bool _maintenance = false;
  bool get maintenance => _maintenance;

  void toggleMaintenance() {
    _maintenance = !_maintenance;
    notifyListeners();
  }
}
