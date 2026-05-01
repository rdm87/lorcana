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

  Future<void> deleteTournament(int tournamentId) async {
    final r = await http.delete(_uri('/tournaments/$tournamentId'), headers: _headers);
    if (r.statusCode >= 400) throw Exception(_parseError(r));
  }

  Future<void> updateTournament(int tournamentId, Map<String, dynamic> payload) async {
    final r = await http.put(_uri('/tournaments/$tournamentId'), headers: _headers, body: jsonEncode(payload));
    if (r.statusCode >= 400) throw Exception(_parseError(r));
  }

  Future<Tournament> generateTestTournament(int playerCount, double entryFeeEur) async {
    final r = await http.post(
      _uri('/admin/test-tournament'),
      headers: _headers,
      body: jsonEncode({'player_count': playerCount, 'entry_fee_eur': entryFeeEur}),
    );
    if (r.statusCode >= 400) throw Exception(_parseError(r));
    return Tournament.fromJson(jsonDecode(r.body));
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

  // ── Discord bot ─────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getDiscordInfo() async {
    final r = await http.get(_uri('/discord/invite'), headers: _headers);
    if (r.statusCode == 404 || r.statusCode >= 400) {
      return {'invite_url': null, 'guild_id': null, 'in_server': null};
    }
    final body = jsonDecode(r.body) as Map<String, dynamic>;
    return {
      'invite_url': body['invite_url'] as String?,
      'guild_id': body['guild_id'] as String?,
      'in_server': body['in_server'] as bool?,
    };
  }

  Future<Map<String, dynamic>> getBotConfig() async {
    final r = await http.get(_uri('/admin/bot-config'), headers: _headers);
    if (r.statusCode >= 400) throw Exception(_parseError(r));
    return jsonDecode(r.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> saveBotConfig(Map<String, dynamic> payload) async {
    final r = await http.put(_uri('/admin/bot-config'), headers: _headers, body: jsonEncode(payload));
    if (r.statusCode >= 400) throw Exception(_parseError(r));
    return jsonDecode(r.body) as Map<String, dynamic>;
  }

  Future<String> getBotOAuthUrl() async {
    final r = await http.get(_uri('/admin/bot-config/bot-oauth-url'), headers: _headers);
    if (r.statusCode >= 400) throw Exception(_parseError(r));
    return jsonDecode(r.body)['url'] as String;
  }

  Future<String> generateDiscordInvite() async {
    final r = await http.post(_uri('/admin/bot-config/generate-invite'), headers: _headers);
    if (r.statusCode >= 400) throw Exception(_parseError(r));
    return jsonDecode(r.body)['invite_url'] as String;
  }

  // ── Availability ────────────────────────────────────────────────────────────

  Future<List<PlayerAvailability>> getAvailability(int tournamentId) async {
    final r = await http.get(_uri('/tournaments/$tournamentId/availability'), headers: _headers);
    if (r.statusCode >= 400) throw Exception(_parseError(r));
    return (jsonDecode(r.body) as List).map((e) => PlayerAvailability.fromJson(e)).toList();
  }

  Future<void> updateMyAvailability(int tournamentId, List<Map<String, dynamic>> slots) async {
    final r = await http.put(
      _uri('/tournaments/$tournamentId/availability/me'),
      headers: _headers,
      body: jsonEncode({'slots': slots}),
    );
    if (r.statusCode >= 400) throw Exception(_parseError(r));
  }

  Future<void> updatePlayerAvailability(int tournamentId, int regId, List<Map<String, dynamic>> slots) async {
    final r = await http.put(
      _uri('/tournaments/$tournamentId/availability/$regId'),
      headers: _headers,
      body: jsonEncode({'slots': slots}),
    );
    if (r.statusCode >= 400) throw Exception(_parseError(r));
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
