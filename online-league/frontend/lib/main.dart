import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'src/screens/auth_callback_screen.dart';
import 'src/screens/create_tournament_screen.dart';
import 'src/screens/home_screen.dart';
import 'src/services/api_client.dart';
import 'src/services/session.dart';

void main() {
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
      GoRoute(path: '/admin/tournaments/new', builder: (_, __) => CreateTournamentScreen(api: api)),
      GoRoute(path: '/auth/callback', builder: (_, state) => AuthCallbackScreen(token: state.uri.queryParameters['token'])),
    ]);
    return MaterialApp.router(
      title: 'Lorcana Tournament Manager',
      theme: ThemeData(colorSchemeSeed: Colors.deepPurple, useMaterial3: true),
      routerConfig: router,
    );
  }
}
