import 'package:flutter/foundation.dart';
import '../models/user.dart';
import 'api_client.dart';

class Session extends ChangeNotifier {
  final ApiClient api;
  AppUser? user;
  bool loading = false;
  Session(this.api);
  bool get isLogged => user != null;
  bool get isAdmin => user?.isAdmin ?? false;

  Future<void> load() async {
    if (api.token == null) return;
    loading = true; notifyListeners();
    try { user = await api.me(); } catch (_) { api.logout(); user = null; }
    loading = false; notifyListeners();
  }

  void login() => api.loginWithDiscord();
  void logout() { api.logout(); user = null; notifyListeners(); }
}
