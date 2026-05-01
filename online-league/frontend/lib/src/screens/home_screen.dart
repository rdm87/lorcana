import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../models/tournament.dart';
import '../services/api_client.dart';
import '../services/session.dart';

enum _TournamentStatus { upcoming, open, full, ongoing, concluded }

_TournamentStatus _statusOf(Tournament t) {
  if (t.status == 'ongoing') return _TournamentStatus.ongoing;
  if (t.status == 'completed') return _TournamentStatus.concluded;
  final now = DateTime.now();
  if (now.isAfter(t.endDate)) return _TournamentStatus.concluded;
  if (t.registeredCount >= t.cap) return _TournamentStatus.full;
  if (now.isBefore(t.startDate)) return _TournamentStatus.upcoming;
  return _TournamentStatus.open;
}

class HomeScreen extends StatefulWidget {
  final ApiClient api;
  const HomeScreen({super.key, required this.api});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Tournament>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.api.tournaments();
  }

  Future<void> _refresh() async => setState(() => _future = widget.api.tournaments());

  Future<void> _showTestTournamentDialog(BuildContext context) async {
    int playerCount = 4;
    final feeCtrl = TextEditingController(text: '0');
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          title: const Row(children: [
            Icon(Icons.science_outlined, color: Color(0xFF5D2EA6)),
            SizedBox(width: 10),
            Text('Genera torneo di test'),
          ]),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Inserisci il numero di giocatori da simulare:',
                style: TextStyle(fontSize: 14)),
            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              IconButton(
                onPressed: playerCount > 2 ? () => setDlg(() => playerCount--) : null,
                icon: const Icon(Icons.remove_circle_outline),
              ),
              Container(
                width: 64,
                alignment: Alignment.center,
                child: Text('$playerCount',
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
              ),
              IconButton(
                onPressed: playerCount < 50 ? () => setDlg(() => playerCount++) : null,
                icon: const Icon(Icons.add_circle_outline),
              ),
            ]),
            const SizedBox(height: 4),
            Text('${playerCount * (playerCount - 1) ~/ 2} partite (tutti contro tutti)',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            const SizedBox(height: 16),
            TextField(
              controller: feeCtrl,
              decoration: const InputDecoration(
                labelText: 'Quota iscrizione (€)',
                prefixIcon: Icon(Icons.euro_outlined),
                hintText: '0 = gratuito',
                isDense: true,
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annulla')),
            FilledButton.icon(
              onPressed: () async {
                final fee = double.tryParse(feeCtrl.text.replaceAll(',', '.')) ?? 0;
                Navigator.pop(ctx);
                try {
                  final t = await widget.api.generateTestTournament(playerCount, fee);
                  if (context.mounted) context.go('/tournaments/${t.id}');
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('$e'), backgroundColor: Colors.red.shade700));
                  }
                }
              },
              icon: const Icon(Icons.rocket_launch_outlined, size: 16),
              label: const Text('Genera'),
            ),
          ],
        ),
      ),
    );
    feeCtrl.dispose();
  }

  List<Widget> _buildSections(BuildContext context, List<Tournament> tournaments) {
    final ongoing = tournaments.where((t) => t.status == 'ongoing').toList();
    final upcoming = tournaments.where((t) => t.status == 'registration').toList();
    final concluded = tournaments.where((t) => t.status == 'completed' || (t.status == 'registration' && DateTime.now().isAfter(t.endDate))).toList();

    Widget sectionHeader(String label, int count) => Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(children: [
        Text(label, style: Theme.of(context).textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w800, color: const Color(0xFF2D145C))),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFF5D2EA6).withValues(alpha: .12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text('$count', style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF5D2EA6))),
        ),
      ]),
    );

    Widget grid(List<Tournament> list) => LayoutBuilder(builder: (context, c) {
      final twoCols = c.maxWidth > 760;
      return Wrap(
        spacing: 16, runSpacing: 16,
        children: list.map((t) => SizedBox(
          width: twoCols ? (c.maxWidth - 16) / 2 : c.maxWidth,
          child: TournamentCard(t: t),
        )).toList(),
      );
    });

    if (tournaments.isEmpty) return [const _EmptyState()];

    return [
      if (ongoing.isNotEmpty) ...[
        sectionHeader('Tornei in corso', ongoing.length),
        grid(ongoing),
        const SizedBox(height: 28),
      ],
      if (upcoming.isNotEmpty) ...[
        sectionHeader('Prossimi tornei', upcoming.length),
        grid(upcoming),
        const SizedBox(height: 28),
      ],
      if (concluded.isNotEmpty) ...[
        sectionHeader('Tornei conclusi', concluded.length),
        grid(concluded),
      ],
    ];
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<Session>();
    final isNarrow = MediaQuery.sizeOf(context).width < 600;
    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: const Color(0xFFFFD66B), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.auto_awesome, color: Color(0xFF2D145C), size: 18),
          ),
          const SizedBox(width: 10),
          const Text('Lorcana League', style: TextStyle(fontWeight: FontWeight.w800)),
        ]),
        actions: [
          IconButton(
            onPressed: () => context.go('/wiki'),
            icon: const Icon(Icons.help_outline),
            tooltip: 'Guida',
          ),
          if (session.isAdmin) ...[
            IconButton(
              onPressed: () => context.go('/admin/bot-config'),
              icon: const Icon(Icons.smart_toy_outlined),
              tooltip: 'Configura bot Discord',
            ),
            IconButton(
              onPressed: () => _showTestTournamentDialog(context),
              icon: const Icon(Icons.science_outlined),
              tooltip: 'Genera torneo di test',
            ),
            isNarrow
                ? IconButton(
                    onPressed: () => context.go('/admin/tournaments/new'),
                    icon: const Icon(Icons.add_circle_outline),
                    tooltip: 'Nuovo torneo',
                  )
                : TextButton.icon(
                    onPressed: () => context.go('/admin/tournaments/new'),
                    icon: const Icon(Icons.add_circle_outline, size: 18),
                    label: const Text('Nuovo torneo'),
                  ),
          ],
          if (session.isLogged) ...[
            const SizedBox(width: 4),
            _UserAvatar(session: session, compact: isNarrow),
            const SizedBox(width: 4),
          ] else ...[
            isNarrow
                ? IconButton(
                    onPressed: session.login,
                    icon: const Icon(Icons.login),
                    tooltip: 'Login con Discord',
                  )
                : Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilledButton.icon(
                      onPressed: session.login,
                      icon: const Icon(Icons.login, size: 18),
                      label: const Text('Login Discord'),
                    ),
                  ),
          ],
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF3EEFF), Color(0xFFFFF8E7)],
          ),
        ),
        child: FutureBuilder<List<Tournament>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.wifi_off_rounded, size: 48, color: Colors.grey),
                  const SizedBox(height: 12),
                  Text('Impossibile caricare i tornei', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  FilledButton.icon(onPressed: _refresh, icon: const Icon(Icons.refresh), label: const Text('Riprova')),
                ]),
              );
            }
            final tournaments = snap.data ?? [];
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1100),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const _HomeHero(),
                        const SizedBox(height: 16),
                        ..._buildSections(context, tournaments),
                      ]),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ─── User avatar widget in AppBar ────────────────────────────────────────────

class _UserAvatar extends StatelessWidget {
  final Session session;
  final bool compact;
  const _UserAvatar({required this.session, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final user = session.user!;
    return PopupMenuButton<String>(
      tooltip: user.username,
      offset: const Offset(0, 44),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: const Color(0xFF5D2EA6),
            backgroundImage: user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
            child: user.avatarUrl == null
                ? Text(
                    user.username.isNotEmpty ? user.username[0].toUpperCase() : '?',
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
                  )
                : null,
          ),
          if (!compact) ...[
            const SizedBox(width: 8),
            Text(user.username, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(width: 4),
            const Icon(Icons.expand_more, size: 18),
          ],
        ]),
      ),
      itemBuilder: (_) => [
        PopupMenuItem(
          enabled: false,
          child: Text(user.isAdmin ? 'Admin' : 'Giocatore',
              style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'logout',
          child: const Row(children: [
            Icon(Icons.logout, size: 18),
            SizedBox(width: 8),
            Text('Logout'),
          ]),
        ),
      ],
      onSelected: (v) { if (v == 'logout') session.logout(); },
    );
  }
}

// ─── Hero banner ─────────────────────────────────────────────────────────────

class _HomeHero extends StatelessWidget {
  const _HomeHero();

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 480;
    final icon = Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: const Color(0xFFFFD66B), borderRadius: BorderRadius.circular(20)),
      child: const Icon(Icons.auto_awesome, color: Color(0xFF2D145C), size: 34),
    );
    final text = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(
        'Lorcana Campania ti dà il benvenuto',
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w900,
        ),
      ),
      const SizedBox(height: 6),
      Text(
        'Con questa applicazione potrai gestire i tuoi tornei di Lorcana tra amici.',
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: Colors.white.withValues(alpha: .82),
        ),
      ),
    ]);
    return Card(
      elevation: 0,
      color: const Color(0xFF2D145C),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.all(26),
        child: narrow
            ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                icon,
                const SizedBox(height: 14),
                text,
              ])
            : Row(children: [
                icon,
                const SizedBox(width: 18),
                Expanded(child: text),
              ]),
      ),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white.withValues(alpha: .9),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: const Padding(
        padding: EdgeInsets.symmetric(vertical: 40, horizontal: 28),
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.event_busy_rounded, size: 48, color: Color(0xFFB0A0CC)),
            SizedBox(height: 12),
            Text('Nessun torneo disponibile al momento.',
                style: TextStyle(color: Color(0xFF7A6A99), fontSize: 16)),
          ]),
        ),
      ),
    );
  }
}

// ─── Tournament card ──────────────────────────────────────────────────────────

class TournamentCard extends StatelessWidget {
  final Tournament t;
  const TournamentCard({super.key, required this.t});

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd MMM yyyy, HH:mm', 'it_IT');
    final status = _statusOf(t);
    final ratio = t.cap == 0 ? 0.0 : t.registeredCount / t.cap;
    final progressColor = ratio >= 1.0
        ? Colors.red.shade600
        : ratio >= 0.8
            ? Colors.orange.shade600
            : Colors.green.shade600;

    return Card(
      elevation: 0,
      color: Colors.white.withValues(alpha: .95),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => context.go('/tournaments/${t.id}'),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Header: icon + title + status badge
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD66B),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.castle, color: Color(0xFF3C176E), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(
                    t.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF2D145C),
                    ),
                  ),
                  const SizedBox(height: 4),
                  _StatusBadge(status: status),
                ]),
              ),
            ]),

            const SizedBox(height: 14),

            // Date range
            Row(children: [
              const Icon(Icons.event_outlined, size: 15, color: Color(0xFF7A6A99)),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  '${df.format(t.startDate)} → ${df.format(t.endDate)}',
                  style: const TextStyle(fontSize: 13, color: Color(0xFF5A4A79)),
                ),
              ),
            ]),

            const SizedBox(height: 12),

            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: ratio.clamp(0.0, 1.0),
                minHeight: 8,
                color: progressColor,
                backgroundColor: progressColor.withValues(alpha: .15),
              ),
            ),

            const SizedBox(height: 8),

            // Footer: iscritti + fee
            Row(children: [
              Icon(Icons.groups_outlined, size: 15, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Text(
                '${t.registeredCount}/${t.cap} iscritti',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1E7FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  t.entryFeeEur == 0 ? 'Gratuito' : '€ ${t.entryFeeEur.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: Color(0xFF5D2EA6),
                  ),
                ),
              ),
            ]),

            const SizedBox(height: 14),

            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.tonalIcon(
                onPressed: () => context.go('/tournaments/${t.id}'),
                icon: Icon(status == _TournamentStatus.full ? Icons.lock_outline : Icons.arrow_forward, size: 16),
                label: Text(switch (status) {
                  _TournamentStatus.full => 'Completo',
                  _TournamentStatus.ongoing => 'Partite',
                  _TournamentStatus.open => 'Iscriviti',
                  _ => 'Dettaglio',
                }),
                style: FilledButton.styleFrom(visualDensity: VisualDensity.compact),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ─── Status badge ─────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final _TournamentStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      _TournamentStatus.open => ('Aperto', Colors.green.shade700),
      _TournamentStatus.full => ('Completo', Colors.red.shade700),
      _TournamentStatus.upcoming => ('In arrivo', Colors.indigo.shade600),
      _TournamentStatus.ongoing => ('In corso', Colors.deepPurple.shade600),
      _TournamentStatus.concluded => ('Concluso', Colors.grey.shade600),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: .35)),
      ),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
    );
  }
}
