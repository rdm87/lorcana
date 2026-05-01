import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/tournament.dart';
import '../services/api_client.dart';
import '../services/session.dart';

class HomeScreen extends StatefulWidget { final ApiClient api; const HomeScreen({super.key, required this.api}); @override State<HomeScreen> createState()=>_HomeScreenState(); }
class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Tournament>> future;
  @override void initState(){ super.initState(); future = widget.api.tournaments(); }
  Future<void> refresh() async => setState(()=>future = widget.api.tournaments());
  @override Widget build(BuildContext context) {
    final session = context.watch<Session>();
    return Scaffold(
      appBar: AppBar(title: const Text('Lorcana Tournament Manager'), actions: [
        if (session.isAdmin) TextButton(onPressed: ()=>context.go('/admin/tournaments/new'), child: const Text('Nuovo torneo')),
        if (session.isLogged) TextButton(onPressed: session.logout, child: Text('Logout ${session.user!.username}')) else TextButton(onPressed: session.login, child: const Text('Login Discord')),
      ]),
      floatingActionButton: session.isAdmin ? FloatingActionButton.extended(onPressed: ()=>context.go('/admin/tournaments/new'), label: const Text('Crea torneo'), icon: const Icon(Icons.add)) : null,
      body: FutureBuilder<List<Tournament>>(
        future: future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
          if (snap.hasError) return Center(child: Text('Errore: ${snap.error}'));
          final tournaments = snap.data ?? [];
          if (tournaments.isEmpty) return const Center(child: Text('Nessun torneo disponibile'));
          return RefreshIndicator(onRefresh: refresh, child: ListView.builder(padding: const EdgeInsets.all(16), itemCount: tournaments.length, itemBuilder: (_, i) => TournamentCard(t: tournaments[i], api: widget.api, onChanged: refresh)));
        },
      ),
    );
  }
}

class TournamentCard extends StatelessWidget {
  final Tournament t; final ApiClient api; final VoidCallback onChanged;
  const TournamentCard({super.key, required this.t, required this.api, required this.onChanged});
  @override Widget build(BuildContext context) {
    final df = DateFormat('dd/MM/yyyy HH:mm');
    final session = context.watch<Session>();
    return Card(margin: const EdgeInsets.only(bottom: 16), child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(t.title, style: Theme.of(context).textTheme.headlineSmall),
      const SizedBox(height: 8),
      Text('Periodo: ${df.format(t.startDate)} → ${df.format(t.endDate)}'),
      Text('Iscritti: ${t.registeredCount}/${t.cap} | Costo: € ${t.entryFeeEur.toStringAsFixed(2)}'),
      const SizedBox(height: 8), Text(t.rulesDescription), const SizedBox(height: 8),
      Text('Montepremi: ${t.prizeDistribution.map((p) => "${p.position}° ${p.percentage}%").join(" · ")}'),
      const SizedBox(height: 12), Wrap(spacing: 8, children: [
        FilledButton.tonal(onPressed: () => launchUrl(Uri.parse(t.paypalLink)), child: const Text('Pagamento PayPal')),
        FilledButton(onPressed: session.isLogged ? () async { await api.register(t.id); onChanged(); if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Iscrizione completata'))); } : null, child: const Text('Iscriviti')),
      ])
    ])));
  }
}
