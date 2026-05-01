import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'src/models/tournament.dart';
import 'src/screens/auth_callback_screen.dart';
import 'src/screens/create_tournament_screen.dart';
import 'src/screens/home_screen.dart';
import 'src/screens/tournament_detail_screen.dart';
import 'src/services/api_client.dart';
import 'src/services/session.dart';

void main() async {
  await initializeDateFormatting('it_IT', null);
  usePathUrlStrategy();
  final api = ApiClient();
  runApp(ChangeNotifierProvider(create: (_) => Session(api)..load(), child: MyApp(api: api)));
}

class MyApp extends StatelessWidget {
  final ApiClient api;
  const MyApp({super.key, required this.api});

  @override
  Widget build(BuildContext context) {
    final router = GoRouter(routes: [
      GoRoute(path: '/', builder: (_, __) => HomeScreen(api: api)),
      GoRoute(
        path: '/tournaments/:id',
        builder: (_, state) => TournamentDetailScreen(
          api: api,
          tournamentId: int.parse(state.pathParameters['id']!),
        ),
      ),
      GoRoute(path: '/admin/tournaments/new', builder: (_, __) => CreateTournamentScreen(api: api)),
      GoRoute(
        path: '/admin/tournaments/:id/edit',
        builder: (_, state) => CreateTournamentScreen(
          api: api,
          editTournament: state.extra as Tournament?,
        ),
      ),
      GoRoute(
        path: '/auth/callback',
        builder: (_, state) => AuthCallbackScreen(token: state.uri.queryParameters['token']),
      ),
    ]);

    return MaterialApp.router(
      title: 'Lorcana League',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF5D2EA6),
          primary: const Color(0xFF5D2EA6),
          secondary: const Color(0xFFFFD66B),
        ),
        useMaterial3: true,
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          filled: true,
          fillColor: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
      ),
      routerConfig: router,
    );
  }
}
