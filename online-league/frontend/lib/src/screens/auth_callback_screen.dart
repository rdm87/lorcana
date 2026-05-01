import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../services/session.dart';

class AuthCallbackScreen extends StatefulWidget {
  final String? token;
  const AuthCallbackScreen({super.key, required this.token});
  @override State<AuthCallbackScreen> createState() => _AuthCallbackScreenState();
}
class _AuthCallbackScreenState extends State<AuthCallbackScreen> {
  @override void initState() { super.initState(); _complete(); }
  Future<void> _complete() async {
    final session = context.read<Session>();
    session.api.token = widget.token;
    await session.load();
    if (mounted) context.go('/');
  }
  @override Widget build(BuildContext context) => const Scaffold(body: Center(child: CircularProgressIndicator()));
}
