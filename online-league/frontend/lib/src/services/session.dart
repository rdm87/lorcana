import 'package:flutter/foundation.dart';
import '../models/user.dart';
import 'api_client.dart';

class Session extends ChangeNotifier {
  final ApiClient api;
  AppUser? user;
  bool loading = false;
  bool _adminViewActive = true;
  Session(this.api);
  bool get isLogged => user != null;
  bool get isAdmin => user?.isAdmin ?? false;
  bool get adminViewActive => _adminViewActive;
  bool get effectiveIsAdmin => isAdmin && _adminViewActive;

  void toggleAdminView() {
    if (!isAdmin) return;
    _adminViewActive = !_adminViewActive;
    notifyListeners();
  }

  Future<void> load() async {
    if (api.token == null) return;
    loading = true; notifyListeners();
    try { user = await api.me(); } catch (_) { api.logout(); user = null; }
    loading = false; notifyListeners();
  }

  void login() => api.loginWithDiscord();
  void logout() { api.logout(); user = null; _adminViewActive = true; notifyListeners(); }
}
