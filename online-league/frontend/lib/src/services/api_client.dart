import 'dart:convert';
import 'dart:html' as html;
import 'package:http/http.dart' as http;
import '../config.dart';
import '../models/tournament.dart';
import '../models/user.dart';

class ApiClient {
  String? get token => html.window.localStorage['lorcana_token'];
  set token(String? value) {
    if (value == null) {
      html.window.localStorage.remove('lorcana_token');
    } else {
      html.window.localStorage['lorcana_token'] = value;
    }
  }

  Uri _uri(String path) => Uri.parse('${AppConfig.apiBaseUrl}/api$path');

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  void loginWithDiscord() =>
      html.window.location.href = '${AppConfig.apiBaseUrl}/api/auth/discord/login';

  void logout() => token = null;

  static String _parseError(http.Response r) {
    try {
      final body = jsonDecode(r.body);
      if (body is Map && body.containsKey('detail')) {
        return body['detail'].toString();
      }
    } catch (_) {}
    return 'Errore ${r.statusCode}';
  }

  // ── Auth ────────────────────────────────────────────────────────────────────

  Future<AppUser> me() async {
    final r = await http.get(_uri('/me'), headers: _headers);
    if (r.statusCode >= 400) throw Exception(_parseError(r));
    return AppUser.fromJson(jsonDecode(r.body));
  }

  // ── Tournaments ─────────────────────────────────────────────────────────────

  Future<List<Tournament>> tournaments() async {
    final r = await http.get(_uri('/tournaments'), headers: _headers);
    if (r.statusCode >= 400) throw Exception(_parseError(r));
    return (jsonDecode(r.body) as List).map((e) => Tournament.fromJson(e)).toList();
  }

  Future<TournamentDetail> tournament(int tournamentId) async {
    final r = await http.get(_uri('/tournaments/$tournamentId'), headers: _headers);
    if (r.statusCode >= 400) throw Exception(_parseError(r));
    return TournamentDetail.fromJson(jsonDecode(r.body));
  }

  Future<void> createTournament(Map<String, dynamic> payload) async {
    final r = await http.post(_uri('/tournaments'), headers: _headers, body: jsonEncode(payload));
    if (r.statusCode >= 400) throw Exception(_parseError(r));
  }

  Future<void> startTournament(int tournamentId) async {
    final r = await http.post(_uri('/tournaments/$tournamentId/start'), headers: _headers);
    if (r.statusCode >= 400) throw Exception(_parseError(r));
  }

  // ── Registrations (user) ────────────────────────────────────────────────────

  Future<void> register(int tournamentId, Map<String, dynamic> payload) async {
    final r = await http.post(
      _uri('/tournaments/$tournamentId/register'),
      headers: _headers,
      body: jsonEncode(payload),
    );
    if (r.statusCode >= 400) throw Exception(_parseError(r));
  }

  Future<void> cancelMyRegistration(int tournamentId) async {
    final r = await http.delete(
      _uri('/tournaments/$tournamentId/registration/me'),
      headers: _headers,
    );
    if (r.statusCode >= 400) throw Exception(_parseError(r));
  }

  // ── Registrations (admin) ───────────────────────────────────────────────────

  Future<FullRegistration> adminRegister(
      int tournamentId, Map<String, dynamic> payload) async {
    final r = await http.post(
      _uri('/tournaments/$tournamentId/admin/register'),
      headers: _headers,
      body: jsonEncode(payload),
    );
    if (r.statusCode >= 400) throw Exception(_parseError(r));
    return FullRegistration.fromJson(jsonDecode(r.body));
  }

  Future<void> deleteRegistration(int registrationId) async {
    final r = await http.delete(_uri('/registrations/$registrationId'), headers: _headers);
    if (r.statusCode >= 400) throw Exception(_parseError(r));
  }

  Future<FullRegistration> markPaid(int registrationId) async {
    final r = await http.post(_uri('/registrations/$registrationId/paid'), headers: _headers);
    if (r.statusCode >= 400) throw Exception(_parseError(r));
    return FullRegistration.fromJson(jsonDecode(r.body));
  }

  Future<FullRegistration> unmarkPaid(int registrationId) async {
    final r = await http.delete(_uri('/registrations/$registrationId/paid'), headers: _headers);
    if (r.statusCode >= 400) throw Exception(_parseError(r));
    return FullRegistration.fromJson(jsonDecode(r.body));
  }

  // ── Matches ─────────────────────────────────────────────────────────────────

  Future<List<MatchResult>> matches(int tournamentId) async {
    final r = await http.get(_uri('/tournaments/$tournamentId/matches'), headers: _headers);
    if (r.statusCode >= 400) throw Exception(_parseError(r));
    return (jsonDecode(r.body) as List).map((e) => MatchResult.fromJson(e)).toList();
  }

  Future<List<StandingEntry>> standings(int tournamentId) async {
    final r = await http.get(_uri('/tournaments/$tournamentId/standings'), headers: _headers);
    if (r.statusCode >= 400) throw Exception(_parseError(r));
    return (jsonDecode(r.body) as List).map((e) => StandingEntry.fromJson(e)).toList();
  }

  Future<MatchResult> proposeResult(int matchId, int gamesReg1, int gamesReg2) async {
    final r = await http.post(
      _uri('/matches/$matchId/result'),
      headers: _headers,
      body: jsonEncode({'games_reg1': gamesReg1, 'games_reg2': gamesReg2}),
    );
    if (r.statusCode >= 400) throw Exception(_parseError(r));
    return MatchResult.fromJson(jsonDecode(r.body));
  }

  Future<MatchResult> confirmResult(int matchId) async {
    final r = await http.post(_uri('/matches/$matchId/confirm'), headers: _headers);
    if (r.statusCode >= 400) throw Exception(_parseError(r));
    return MatchResult.fromJson(jsonDecode(r.body));
  }
}
