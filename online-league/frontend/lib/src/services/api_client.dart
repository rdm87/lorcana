import 'dart:convert';
import 'dart:html' as html;
import 'package:http/http.dart' as http;
import '../config.dart';
import '../models/tournament.dart';
import '../models/user.dart';

class ApiClient {
  String? get token => html.window.localStorage['lorcana_token'];
  set token(String? value) {
    if (value == null) html.window.localStorage.remove('lorcana_token');
    else html.window.localStorage['lorcana_token'] = value;
  }

  Uri _uri(String path) => Uri.parse('${AppConfig.apiBaseUrl}$path');
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };

  void loginWithDiscord() => html.window.location.href = '${AppConfig.apiBaseUrl}/auth/discord/login';
  void logout() => token = null;

  Future<AppUser> me() async {
    final r = await http.get(_uri('/me'), headers: _headers);
    if (r.statusCode >= 400) throw Exception(r.body);
    return AppUser.fromJson(jsonDecode(r.body));
  }

  Future<List<Tournament>> tournaments() async {
    final r = await http.get(_uri('/tournaments'), headers: _headers);
    if (r.statusCode >= 400) throw Exception(r.body);
    return (jsonDecode(r.body) as List).map((e) => Tournament.fromJson(e)).toList();
  }

  Future<void> register(int tournamentId) async {
    final r = await http.post(_uri('/tournaments/$tournamentId/register'), headers: _headers);
    if (r.statusCode >= 400) throw Exception(r.body);
  }

  Future<void> createTournament(Map<String, dynamic> payload) async {
    final r = await http.post(_uri('/tournaments'), headers: _headers, body: jsonEncode(payload));
    if (r.statusCode >= 400) throw Exception(r.body);
  }
}
