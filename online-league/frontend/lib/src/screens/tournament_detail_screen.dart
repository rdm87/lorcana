import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/tournament.dart';
import '../services/api_client.dart';
import '../services/session.dart';

class TournamentDetailScreen extends StatefulWidget {
  final ApiClient api;
  final int tournamentId;
  const TournamentDetailScreen({super.key, required this.api, required this.tournamentId});
  @override
  State<TournamentDetailScreen> createState() => _TournamentDetailScreenState();
}

class _TournamentDetailScreenState extends State<TournamentDetailScreen>
    with TickerProviderStateMixin {
  late Future<TournamentDetail> _future;
  Future<List<MatchResult>>? _matchesFuture;
  Future<List<StandingEntry>>? _standingsFuture;
  TabController? _tabController;
  String? _lastStatus;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _future = widget.api.tournament(widget.tournamentId);
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (_) => _reload(silent: true));
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _tabController?.dispose();
    super.dispose();
  }

  void _ensureTabController(String status) {
    if (status == _lastStatus) return;
    _lastStatus = status;
    _tabController?.dispose();
    if (status == 'ongoing' || status == 'completed') {
      _tabController = TabController(length: 3, vsync: this);
      _matchesFuture = widget.api.matches(widget.tournamentId);
      _standingsFuture = widget.api.standings(widget.tournamentId);
    } else {
      _tabController = null;
    }
  }

  void _reload({bool silent = false}) {
    if (!mounted) return;
    setState(() {
      _future = widget.api.tournament(widget.tournamentId);
      if (_lastStatus == 'ongoing' || _lastStatus == 'completed') {
        _matchesFuture = widget.api.matches(widget.tournamentId);
        _standingsFuture = widget.api.standings(widget.tournamentId);
      }
    });
    if (!silent) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Dati aggiornati')));
    }
  }

  void _reloadMatches() {
    if (!mounted) return;
    setState(() {
      _matchesFuture = widget.api.matches(widget.tournamentId);
      _standingsFuture = widget.api.standings(widget.tournamentId);
    });
  }

  Map<int, String> _buildPlayerLabels(TournamentDetail t, bool isLogged) {
    if (isLogged) {
      return {for (final r in t.registrations) r.id: '${r.firstName} ${r.lastName}'};
    }
    return {
      for (int i = 0; i < t.registrations.length; i++)
        t.registrations[i].id: 'Giocatore ${i + 1}'
    };
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<TournamentDetail>(
      future: _future,
      builder: (context, snap) {
        final t = snap.data;
        if (t != null) _ensureTabController(t.status);
        final tc = _tabController;

        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              onPressed: () => context.go('/'),
              icon: const Icon(Icons.home_outlined),
              tooltip: 'Home',
            ),
            title: Text(t?.title ?? 'Dettaglio torneo'),
            actions: [
              IconButton(onPressed: _reload, icon: const Icon(Icons.refresh), tooltip: 'Aggiorna'),
            ],
            bottom: tc != null
                ? TabBar(
                    controller: tc,
                    tabs: const [
                      Tab(text: 'Informazioni'),
                      Tab(text: 'Calendario'),
                      Tab(text: 'Classifica'),
                    ],
                  )
                : null,
          ),
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFF3EEFF), Color(0xFFFFF8E7)],
              ),
            ),
            child: _buildBody(snap, tc),
          ),
        );
      },
    );
  }

  Widget _buildBody(AsyncSnapshot<TournamentDetail> snap, TabController? tc) {
    if (snap.connectionState != ConnectionState.done && snap.data == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (snap.hasError) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.grey),
          const SizedBox(height: 12),
          Text('${snap.error}'),
          const SizedBox(height: 8),
          FilledButton.icon(onPressed: _reload, icon: const Icon(Icons.refresh), label: const Text('Riprova')),
        ]),
      );
    }
    final t = snap.data!;

    if (tc != null) {
      final isLogged = context.read<Session>().isLogged;
      final playerLabels = _buildPlayerLabels(t, isLogged);
      return TabBarView(
        controller: tc,
        children: [
          _InfoTab(t: t, api: widget.api, onChanged: () => _reload(silent: true)),
          _CalendarTab(
            t: t,
            api: widget.api,
            matchesFuture: _matchesFuture!,
            onChanged: _reloadMatches,
            playerLabels: playerLabels,
          ),
          _StandingsTab(standingsFuture: _standingsFuture!, playerLabels: playerLabels),
        ],
      );
    }

    // Registration phase: original layout
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1050),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _HeroCard(t: t, api: widget.api, onChanged: () => _reload(silent: true)),
              const SizedBox(height: 18),
              LayoutBuilder(builder: (context, c) {
                final wide = c.maxWidth > 850;
                final registerPanel = _RegisterPanel(
                  t: t, api: widget.api, onChanged: () => _reload(silent: true),
                );
                final playersPanel = _PlayersPanel(
                  t: t, api: widget.api, onChanged: () => _reload(silent: true),
                );
                if (wide) {
                  return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(flex: 3, child: registerPanel),
                    const SizedBox(width: 18),
                    Expanded(flex: 2, child: playersPanel),
                  ]);
                }
                return Column(children: [
                  registerPanel,
                  const SizedBox(height: 18),
                  playersPanel,
                ]);
              }),
            ]),
          ),
        ),
      ],
    );
  }
}

// ─── Info tab (ongoing/completed tournaments) ─────────────────────────────────

class _InfoTab extends StatelessWidget {
  final TournamentDetail t;
  final ApiClient api;
  final VoidCallback onChanged;
  const _InfoTab({required this.t, required this.api, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1050),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _HeroCard(t: t, api: api, onChanged: onChanged),
              const SizedBox(height: 18),
              _PlayersPanel(t: t, api: api, onChanged: onChanged),
            ]),
          ),
        ),
      ],
    );
  }
}

// ─── Calendar tab ─────────────────────────────────────────────────────────────

class _CalendarTab extends StatefulWidget {
  final TournamentDetail t;
  final ApiClient api;
  final Future<List<MatchResult>> matchesFuture;
  final VoidCallback onChanged;
  final Map<int, String> playerLabels;
  const _CalendarTab({
    required this.t,
    required this.api,
    required this.matchesFuture,
    required this.onChanged,
    required this.playerLabels,
  });
  @override
  State<_CalendarTab> createState() => _CalendarTabState();
}

class _CalendarTabState extends State<_CalendarTab> {
  int? _selectedRegId;

  @override
  Widget build(BuildContext context) {
    return _selectedRegId == null ? _buildPlayerList(context) : _buildPlayerMatches(context);
  }

  Widget _buildPlayerList(BuildContext context) {
    final regs = widget.t.registrations;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                'Seleziona un giocatore',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800, color: const Color(0xFF2D145C)),
              ),
              const SizedBox(height: 4),
              Text('${regs.length} giocatori · ${regs.length * (regs.length - 1) ~/ 2} partite totali',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
              const SizedBox(height: 16),
              LayoutBuilder(builder: (ctx, c) {
                final cols = c.maxWidth > 500 ? 3 : 2;
                final itemW = (c.maxWidth - (cols - 1) * 10) / cols;
                return Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: regs.asMap().entries.map((entry) {
                    final i = entry.key;
                    final r = entry.value;
                    final label = widget.playerLabels[r.id] ?? '${r.firstName} ${r.lastName}';
                    final initials = label.trim().split(' ')
                        .where((w) => w.isNotEmpty)
                        .take(2)
                        .map((w) => w[0].toUpperCase())
                        .join();
                    final avatarColors = [
                      const Color(0xFF5D2EA6), const Color(0xFF1565C0),
                      const Color(0xFF2E7D32), const Color(0xFFC62828),
                      const Color(0xFF6A1B9A), const Color(0xFF00695C),
                      const Color(0xFF4E342E), const Color(0xFF0277BD),
                    ];
                    final color = avatarColors[i % avatarColors.length];
                    return SizedBox(
                      width: itemW,
                      child: Card(
                        elevation: 0,
                        color: Colors.white.withValues(alpha: .95),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () => setState(() => _selectedRegId = r.id),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: color,
                                child: Text(initials,
                                    style: const TextStyle(color: Colors.white,
                                        fontSize: 12, fontWeight: FontWeight.w800)),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(label,
                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                    overflow: TextOverflow.ellipsis),
                              ),
                              Icon(Icons.chevron_right, size: 18, color: Colors.grey.shade400),
                            ]),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              }),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildPlayerMatches(BuildContext context) {
    final reg = widget.t.registrations
        .firstWhere((r) => r.id == _selectedRegId, orElse: () => widget.t.registrations.first);
    final label = widget.playerLabels[_selectedRegId!] ?? '${reg.firstName} ${reg.lastName}';

    return FutureBuilder<List<MatchResult>>(
      future: widget.matchesFuture,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done && snap.data == null) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(child: Text('Errore: ${snap.error}'));
        }
        final all = snap.data ?? [];
        final mine = all
            .where((m) => m.reg1Id == _selectedRegId || m.reg2Id == _selectedRegId)
            .toList();

        final confirmed = mine.where((m) => m.resultStatus == 'confirmed').length;
        final pending = mine.length - confirmed;

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  // Header
                  Row(children: [
                    IconButton(
                      onPressed: () => setState(() => _selectedRegId = null),
                      icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                      tooltip: 'Tutti i giocatori',
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: .8),
                        padding: const EdgeInsets.all(8),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(label,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800, color: const Color(0xFF2D145C))),
                        Text('$confirmed/${mine.length} partite giocate · $pending da completare',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                      ]),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  if (mine.isEmpty)
                    Card(
                      elevation: 0,
                      color: Colors.white.withValues(alpha: .9),
                      child: const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: Text('Nessuna partita trovata.')),
                      ),
                    )
                  else
                    ...mine.map((m) => _MatchCard(
                          match: m,
                          tournament: widget.t,
                          api: widget.api,
                          onChanged: widget.onChanged,
                          playerLabels: widget.playerLabels,
                          focusRegId: _selectedRegId,
                        )),
                ]),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─── Match card ───────────────────────────────────────────────────────────────

class _MatchCard extends StatefulWidget {
  final MatchResult match;
  final TournamentDetail tournament;
  final ApiClient api;
  final VoidCallback onChanged;
  final Map<int, String> playerLabels;
  final int? focusRegId; // when set, shows "vs [opponent]" header
  const _MatchCard({required this.match, required this.tournament, required this.api, required this.onChanged, required this.playerLabels, this.focusRegId});
  @override
  State<_MatchCard> createState() => _MatchCardState();
}

class _MatchCardState extends State<_MatchCard> {
  bool _busy = false;

  int? _myRegId(Session session) {
    final uid = session.user?.id;
    if (uid == null) return null;
    final adminRegs = widget.tournament.adminRegistrations;
    if (adminRegs != null) {
      // admin: check by user_id on full registrations
      for (final r in adminRegs) {
        if (r.userId == uid && (r.id == widget.match.reg1Id || r.id == widget.match.reg2Id)) {
          return r.id;
        }
      }
      if (session.isAdmin) return null; // admin but not a player in this match
    }
    // check my_registration
    final my = widget.tournament.myRegistration;
    if (my != null && (my.id == widget.match.reg1Id || my.id == widget.match.reg2Id)) {
      return my.id;
    }
    return null;
  }

  Future<void> _propose(int gReg1, int gReg2) async {
    setState(() => _busy = true);
    try {
      await widget.api.proposeResult(widget.match.id, gReg1, gReg2);
      widget.onChanged();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$e'), backgroundColor: Colors.red.shade700));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirm() async {
    setState(() => _busy = true);
    try {
      await widget.api.confirmResult(widget.match.id);
      widget.onChanged();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$e'), backgroundColor: Colors.red.shade700));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reset() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Annulla risultato'),
        content: const Text('Sei sicuro di voler annullare il risultato? La partita tornerà in stato "Da giocare".'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            child: const Text('Sì, annulla'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await widget.api.resetResult(widget.match.id);
      widget.onChanged();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$e'), backgroundColor: Colors.red.shade700));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showResultDialog(int myRegId) {
    final m = widget.match;
    final label1 = widget.playerLabels[m.reg1Id] ?? m.reg1.fullName;
    final label2 = widget.playerLabels[m.reg2Id] ?? m.reg2.fullName;
    final short1 = label1.split(' ').first;
    final short2 = label2.split(' ').first;
    final options = [(2, 0), (2, 1), (1, 0), (1, 1), (0, 1), (1, 2), (0, 2)];
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Inserisci risultato'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$label1 vs $label2', style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            const Text('Seleziona il risultato (giochi vinti):', style: TextStyle(fontSize: 13)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: options.map((opt) {
                final (g1, g2) = opt;
                return OutlinedButton(
                  onPressed: () { Navigator.of(context).pop(); _propose(g1, g2); },
                  child: Text('$short1 $g1 – $g2 $short2'),
                );
              }).toList(),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Annulla')),
        ],
      ),
    );
  }

  Widget _buildMatchHeader(MatchResult m, bool hasResult) {
    final label1 = widget.playerLabels[m.reg1Id] ?? m.reg1.fullName;
    final label2 = widget.playerLabels[m.reg2Id] ?? m.reg2.fullName;
    final score = hasResult
        ? Text('${m.gamesReg1} – ${m.gamesReg2}',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18))
        : const Text('vs', style: TextStyle(color: Colors.grey));

    if (widget.focusRegId != null) {
      // focused view: show "vs [opponent]"
      final opponentLabel = widget.focusRegId == m.reg1Id ? label2 : label1;
      return Row(children: [
        Text('vs ', style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
        Expanded(
          child: Text(opponentLabel, style: const TextStyle(fontWeight: FontWeight.w700)),
        ),
        if (hasResult) ...[const SizedBox(width: 8), score],
      ]);
    }

    // default: show both players
    return Row(children: [
      Expanded(child: Text(label1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700))),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 10), child: score),
      Expanded(child: Text(label2, textAlign: TextAlign.end, overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w700))),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<Session>();
    final m = widget.match;
    final myRegId = _myRegId(session);
    final isAdmin = session.isAdmin;

    Color statusColor;
    String statusLabel;
    switch (m.resultStatus) {
      case 'confirmed':
        statusColor = Colors.green.shade700;
        statusLabel = 'Confermato';
      case 'proposed':
        statusColor = Colors.orange.shade700;
        statusLabel = 'In attesa';
      default:
        statusColor = Colors.grey.shade500;
        statusLabel = 'Da giocare';
    }

    final hasResult = m.gamesReg1 != null && m.gamesReg2 != null;
    final canPropose = isAdmin
        ? true
        : (myRegId != null &&
            m.resultStatus != 'confirmed' &&
            (m.resultStatus == 'pending' || m.proposedByRegId != myRegId));
    final canConfirm = m.resultStatus == 'proposed' &&
        (isAdmin || (myRegId != null && myRegId != m.proposedByRegId));
    final canReset = isAdmin && hasResult;

    return Card(
      elevation: 0,
      color: Colors.white.withValues(alpha: .95),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: _buildMatchHeader(m, hasResult)),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: statusColor.withValues(alpha: .35)),
              ),
              child: Text(statusLabel,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: statusColor)),
            ),
          ]),
          if (m.resultStatus == 'proposed' && hasResult)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Proposto da ${widget.playerLabels[m.proposedByRegId] ?? (m.proposedByRegId == m.reg1Id ? m.reg1.firstName : m.reg2.firstName)}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ),
          if (_busy)
            const Padding(
              padding: EdgeInsets.only(top: 10),
              child: LinearProgressIndicator(),
            )
          else if (canConfirm) ...[
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 8, children: [
              FilledButton.icon(
                onPressed: _confirm,
                icon: const Icon(Icons.check, size: 16),
                label: const Text('Conferma risultato'),
                style: FilledButton.styleFrom(visualDensity: VisualDensity.compact),
              ),
              OutlinedButton(
                onPressed: () => _showResultDialog(myRegId ?? m.reg1Id),
                style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
                child: const Text('Modifica'),
              ),
              if (canReset)
                OutlinedButton.icon(
                  onPressed: _reset,
                  icon: const Icon(Icons.cancel_outlined, size: 16),
                  label: const Text('Annulla risultato'),
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: Colors.red.shade700,
                    side: BorderSide(color: Colors.red.shade300),
                  ),
                ),
            ]),
          ] else if (canPropose) ...[
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 8, children: [
              OutlinedButton.icon(
                onPressed: () => _showResultDialog(myRegId ?? m.reg1Id),
                icon: Icon(hasResult ? Icons.edit_outlined : Icons.add_outlined, size: 16),
                label: Text(hasResult ? 'Modifica risultato' : 'Inserisci risultato'),
                style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
              ),
              if (canReset)
                OutlinedButton.icon(
                  onPressed: _reset,
                  icon: const Icon(Icons.cancel_outlined, size: 16),
                  label: const Text('Annulla risultato'),
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: Colors.red.shade700,
                    side: BorderSide(color: Colors.red.shade300),
                  ),
                ),
            ]),
          ],
        ]),
      ),
    );
  }
}

// ─── Standings tab ────────────────────────────────────────────────────────────

class _StandingsTab extends StatelessWidget {
  final Future<List<StandingEntry>> standingsFuture;
  final Map<int, String> playerLabels;
  const _StandingsTab({required this.standingsFuture, required this.playerLabels});

  Widget _header(double playerW) => Container(
    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
    decoration: BoxDecoration(color: const Color(0xFF3C176E), borderRadius: BorderRadius.circular(10)),
    child: Row(children: [
      const SizedBox(width: 32, child: Text('#', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12))),
      SizedBox(width: playerW, child: const Text('Giocatore', overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12))),
      const SizedBox(width: 36, child: Text('G', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12))),
      const SizedBox(width: 36, child: Text('V', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12))),
      const SizedBox(width: 36, child: Text('P', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12))),
      const SizedBox(width: 36, child: Text('S', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12))),
      const SizedBox(width: 42, child: Text('GV', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12))),
      const SizedBox(width: 42, child: Text('GS', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12))),
      const SizedBox(width: 42, child: Text('Pts', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12))),
    ]),
  );

  Widget _row(int pos, StandingEntry s, double playerW) {
    final bg = pos == 1
        ? const Color(0xFFFFF7D6)
        : pos == 2
            ? const Color(0xFFF5F5F5)
            : pos == 3
                ? const Color(0xFFF5EBE0)
                : Colors.transparent;
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Row(children: [
        SizedBox(width: 32, child: Text('$pos', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13))),
        SizedBox(width: playerW, child: Text(playerLabels[s.regId] ?? s.fullName, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
        SizedBox(width: 36, child: Text('${s.played}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 13))),
        SizedBox(width: 36, child: Text('${s.wins}', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Colors.green.shade700, fontWeight: FontWeight.w600))),
        SizedBox(width: 36, child: Text('${s.draws}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 13))),
        SizedBox(width: 36, child: Text('${s.losses}', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Colors.red.shade700))),
        SizedBox(width: 42, child: Text('${s.gamesWon}', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Colors.green.shade600))),
        SizedBox(width: 42, child: Text('${s.gamesLost}', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Colors.red.shade400))),
        SizedBox(width: 42, child: Text('${s.points}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF3C176E)))),
      ]),
    );
  }

  Widget _table(List<StandingEntry> entries, double playerW) => Column(children: [
    _header(playerW),
    const SizedBox(height: 6),
    ...entries.asMap().entries.map((e) => _row(e.key + 1, e.value, playerW)),
  ]);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<StandingEntry>>(
      future: standingsFuture,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(child: Text('Errore: ${snap.error}'));
        }
        final entries = snap.data ?? [];
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 700),
                child: Card(
                  elevation: 0,
                  color: Colors.white.withValues(alpha: .95),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: LayoutBuilder(builder: (ctx, c) {
                      const fixedW = 302.0;
                      const rowPad = 24.0;
                      final playerW = c.maxWidth - fixedW - rowPad;
                      if (playerW < 60) {
                        const scrollPlayerW = 100.0;
                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SizedBox(
                            width: fixedW + scrollPlayerW + rowPad,
                            child: _table(entries, scrollPlayerW),
                          ),
                        );
                      }
                      return _table(entries, playerW);
                    }),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

String _formatPrizeEur(double amount) {
  final frac = amount - amount.truncateToDouble();
  if (frac < 0.005) return '€${amount.toInt()}';
  if ((frac - 0.5).abs() < 0.005) return '€${amount.toStringAsFixed(2)}';
  return '€${amount.round()}';
}

// ─── Hero card ────────────────────────────────────────────────────────────────

class _HeroCard extends StatefulWidget {
  final TournamentDetail t;
  final ApiClient api;
  final VoidCallback onChanged;
  const _HeroCard({required this.t, required this.api, required this.onChanged});
  @override
  State<_HeroCard> createState() => _HeroCardState();
}

class _HeroCardState extends State<_HeroCard> {
  bool _starting = false;
  bool _deleting = false;
  String? _discordInviteUrl;
  String? _discordGuildId;
  bool? _discordInServer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadDiscordInfo());
  }

  Future<void> _loadDiscordInfo() async {
    if (!mounted || !context.read<Session>().isLogged) return;
    try {
      final info = await widget.api.getDiscordInfo();
      if (mounted) {
        setState(() {
          _discordInviteUrl = info['invite_url'] as String?;
          _discordGuildId = info['guild_id'] as String?;
          _discordInServer = info['in_server'] as bool?;
        });
      }
    } catch (_) {}
  }

  Widget? _discordButton() {
    if (_discordInServer == true && (_discordGuildId != null || _discordInviteUrl != null)) {
      final url = _discordGuildId != null
          ? 'https://discord.com/channels/$_discordGuildId'
          : _discordInviteUrl!;
      return OutlinedButton.icon(
        onPressed: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
        icon: const Icon(Icons.discord, size: 16),
        label: const Text('Visualizza su Discord'),
      );
    }
    if (_discordInServer == false && _discordInviteUrl != null) {
      return OutlinedButton.icon(
        onPressed: () => launchUrl(Uri.parse(_discordInviteUrl!), mode: LaunchMode.externalApplication),
        icon: const Icon(Icons.discord, size: 16),
        label: const Text('Unisciti al server'),
      );
    }
    return null;
  }

  Future<void> _delete() async {
    final t = widget.t;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Row(children: [
          Icon(Icons.delete_forever_outlined, color: Colors.red),
          SizedBox(width: 10),
          Text('Elimina torneo'),
        ]),
        content: RichText(
          text: TextSpan(
            style: Theme.of(context).textTheme.bodyMedium,
            children: [
              const TextSpan(text: 'Sei sicuro di voler eliminare '),
              TextSpan(
                text: t.title,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const TextSpan(
                text: '?\n\nVerranno eliminati anche tutti gli iscritti e le partite associate. L\'operazione è irreversibile.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annulla')),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.delete_forever_outlined, size: 16),
            label: const Text('Elimina'),
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    setState(() => _deleting = true);
    try {
      await widget.api.deleteTournament(t.id);
      if (mounted) context.go('/');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$e'), backgroundColor: Colors.red.shade700));
        setState(() => _deleting = false);
      }
    }
  }

  Future<void> _start() async {
    setState(() => _starting = true);
    try {
      await widget.api.startTournament(widget.t.id);
      widget.onChanged();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Torneo avviato!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$e'), backgroundColor: Colors.red.shade700));
      }
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<Session>();
    final t = widget.t;
    final df = DateFormat('dd MMM yyyy, HH:mm', 'it_IT');
    final ratio = t.cap == 0 ? 0.0 : t.registeredCount / t.cap;
    final progressColor = ratio >= 1.0
        ? Colors.red.shade600
        : ratio >= 0.8
            ? Colors.orange.shade600
            : Colors.green.shade600;

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF3C176E), Color(0xFF5D2EA6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD66B),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.auto_awesome, color: Color(0xFF2D145C), size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  t.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                ),
                const SizedBox(height: 8),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  _InfoChip(icon: Icons.event_outlined, text: df.format(t.startDate), light: true),
                  _InfoChip(icon: Icons.event_available_outlined, text: df.format(t.endDate), light: true),
                  _InfoChip(
                    icon: Icons.payments_outlined,
                    text: t.entryFeeEur == 0 ? 'Gratuito' : '€ ${t.entryFeeEur.toStringAsFixed(2)}',
                    light: true,
                  ),
                  _StatusChip(status: t.status),
                ]),
              ]),
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.all(22),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.groups_outlined, size: 16, color: Color(0xFF7A6A99)),
              const SizedBox(width: 6),
              Text(
                '${t.registeredCount} / ${t.cap} iscritti',
                style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF4A3A69)),
              ),
            ]),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: ratio.clamp(0.0, 1.0),
                minHeight: 10,
                color: progressColor,
                backgroundColor: progressColor.withValues(alpha: .15),
              ),
            ),
            const SizedBox(height: 18),
            const Divider(),
            const SizedBox(height: 14),
            Text('Regole',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800, color: const Color(0xFF2D145C))),
            const SizedBox(height: 6),
            Text(t.rulesDescription, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 16),
            Text('Montepremi',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800, color: const Color(0xFF2D145C))),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: t.prizeDistribution.map((p) {
                final medal = p.position == 1
                    ? '🥇'
                    : p.position == 2
                        ? '🥈'
                        : p.position == 3
                            ? '🥉'
                            : '${p.position}°';
                final prizeEur = t.entryFeeEur > 0
                    ? '  ·  ${_formatPrizeEur(t.entryFeeEur * t.registeredCount * p.percentage / 100)}'
                    : '';
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7D6),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0xFFFFD66B)),
                  ),
                  child: Text('$medal  ${p.percentage.toStringAsFixed(0)}%$prizeEur',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                );
              }).toList(),
            ),
            if (session.isLogged && (t.myRegistration != null || session.isAdmin)) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => context.go('/tournaments/${t.id}/availability'),
                    icon: const Icon(Icons.event_available_outlined, size: 16),
                    label: const Text('Disponibilità'),
                  ),
                  if (_discordButton() case final btn?) btn,
                ],
              ),
            ],
            if (session.isAdmin) ...[
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 14),
              if (t.status == 'registration') ...[
                Row(children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _starting ? null : _start,
                      icon: _starting
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.play_arrow_rounded),
                      label: Text(_starting ? 'Avvio in corso...' : 'Avvia torneo'),
                      style: FilledButton.styleFrom(backgroundColor: const Color(0xFF2D7D32)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton.icon(
                    onPressed: () => context.go('/admin/tournaments/${t.id}/edit', extra: t),
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: const Text('Modifica'),
                  ),
                ]),
                Padding(
                  padding: const EdgeInsets.only(top: 6, bottom: 12),
                  child: Text(
                    'Il torneo si avvia anche automaticamente quando la data di inizio è passata e tutti i giocatori risultano pagati.',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ),
              ],
              OutlinedButton.icon(
                onPressed: _deleting ? null : _delete,
                icon: _deleting
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.delete_outline, size: 16),
                label: Text(_deleting ? 'Eliminazione...' : 'Elimina torneo'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red.shade700,
                  side: BorderSide(color: Colors.red.shade300),
                ),
              ),
            ],
          ]),
        ),
      ]),
    );
  }
}

// ─── Status chip ──────────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'ongoing' => ('In corso', Colors.green.shade300),
      'completed' => ('Concluso', Colors.grey.shade400),
      _ => ('Iscrizioni aperte', Colors.amber.shade300),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .25),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color),
      ),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white.withValues(alpha: .9))),
    );
  }
}

// ─── Registration panel (user) ────────────────────────────────────────────────

class _RegisterPanel extends StatefulWidget {
  final TournamentDetail t;
  final ApiClient api;
  final VoidCallback onChanged;
  const _RegisterPanel({required this.t, required this.api, required this.onChanged});
  @override
  State<_RegisterPanel> createState() => _RegisterPanelState();
}

class _RegisterPanelState extends State<_RegisterPanel> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _discord;
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<Session>().user;
    _discord = TextEditingController(text: user?.username ?? '');
    final parts = (user?.username ?? '').trim().split(' ');
    _firstName.text = parts.first;
    _lastName.text = parts.length > 1 ? parts.sublist(1).join(' ') : '';
  }

  @override
  void dispose() {
    _discord.dispose();
    _firstName.dispose();
    _lastName.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await widget.api.register(widget.t.id, {
        'discord_account': _discord.text.trim(),
        'first_name': _firstName.text.trim(),
        'last_name': _lastName.text.trim(),
      });
      widget.onChanged();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Iscrizione completata!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$e'), backgroundColor: Colors.red.shade700));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _cancel() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancella iscrizione'),
        content: const Text('Sei sicuro di voler cancellare la tua iscrizione?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Sì, cancella')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _saving = true);
    try {
      await widget.api.cancelMyRegistration(widget.t.id);
      widget.onChanged();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Iscrizione cancellata')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$e'), backgroundColor: Colors.red.shade700));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _openPayPal() async {
    final uri = Uri.tryParse(widget.t.paypalLink);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<Session>();
    final myReg = widget.t.myRegistration;
    final isFull = widget.t.registeredCount >= widget.t.cap;

    return Card(
      elevation: 0,
      color: Colors.white.withValues(alpha: .95),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            myReg == null ? 'Iscrizione al torneo' : 'La tua iscrizione',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          if (!session.isLogged) ...[
            Text('Effettua il login con Discord per iscriverti.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700)),
            const SizedBox(height: 16),
            FilledButton.icon(
                onPressed: session.login,
                icon: const Icon(Icons.login),
                label: const Text('Login con Discord')),
          ] else if (myReg != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: const Color(0xFFF3EEFF), borderRadius: BorderRadius.circular(16)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const CircleAvatar(
                      backgroundColor: Color(0xFF5D2EA6),
                      child: Icon(Icons.check, color: Colors.white)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('${myReg.firstName} ${myReg.lastName}',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                      Text('Discord: ${myReg.discordAccount}',
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
                    ]),
                  ),
                ]),
                if (widget.t.entryFeeEur > 0) ...[
                  const SizedBox(height: 12),
                  _PaymentBadge(paid: myReg.paid),
                ],
              ]),
            ),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _saving ? null : _cancel,
                  icon: const Icon(Icons.cancel_outlined, size: 18),
                  label: Text(_saving ? 'Cancellazione...' : 'Cancella iscrizione'),
                ),
              ),
              if (widget.t.entryFeeEur > 0) ...[
                const SizedBox(width: 10),
                FilledButton.icon(
                    onPressed: _openPayPal,
                    icon: const Icon(Icons.payments_outlined, size: 18),
                    label: const Text('Paga su PayPal')),
              ],
            ]),
          ] else if (isFull) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.red.shade200)),
              child: Row(children: [
                Icon(Icons.lock_outline, color: Colors.red.shade700),
                const SizedBox(width: 10),
                Expanded(
                    child: Text('Il torneo ha raggiunto il numero massimo di iscritti.',
                        style: TextStyle(color: Colors.red.shade700))),
              ]),
            ),
          ] else ...[
            Text('Compila i dati per iscriverti. L\'account Discord viene precompilato.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700)),
            const SizedBox(height: 16),
            Form(
              key: _formKey,
              child: Column(children: [
                TextFormField(
                  controller: _discord,
                  decoration: const InputDecoration(
                      labelText: 'Account Discord',
                      prefixIcon: Icon(Icons.person_pin_outlined)),
                  validator: (v) =>
                      v == null || v.trim().length < 2 ? 'Campo obbligatorio' : null,
                ),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                    child: TextFormField(
                      controller: _firstName,
                      decoration: const InputDecoration(
                          labelText: 'Nome', prefixIcon: Icon(Icons.person_outlined)),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Obbligatorio' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _lastName,
                      decoration: const InputDecoration(
                          labelText: 'Cognome', prefixIcon: Icon(Icons.badge_outlined)),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Obbligatorio' : null,
                    ),
                  ),
                ]),
                const SizedBox(height: 18),
                Row(children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _saving ? null : _submit,
                      icon: const Icon(Icons.how_to_reg_outlined),
                      label: Text(_saving ? 'Iscrizione in corso...' : 'Conferma iscrizione'),
                    ),
                  ),
                  if (widget.t.entryFeeEur > 0) ...[
                    const SizedBox(width: 10),
                    OutlinedButton.icon(
                        onPressed: _openPayPal,
                        icon: const Icon(Icons.payments_outlined, size: 18),
                        label: const Text('PayPal')),
                  ],
                ]),
              ]),
            ),
          ],
        ]),
      ),
    );
  }
}

// ─── Players panel ────────────────────────────────────────────────────────────

class _PlayersPanel extends StatelessWidget {
  final TournamentDetail t;
  final ApiClient api;
  final VoidCallback onChanged;
  const _PlayersPanel({required this.t, required this.api, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final isAdmin = t.adminRegistrations != null;
    final df = DateFormat('dd/MM HH:mm');

    return Card(
      elevation: 0,
      color: Colors.white.withValues(alpha: .95),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.groups_outlined, size: 20, color: Color(0xFF5D2EA6)),
            const SizedBox(width: 8),
            Text('Giocatori iscritti',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                  color: const Color(0xFF5D2EA6).withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(20)),
              child: Text('${t.registeredCount}',
                  style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF5D2EA6))),
            ),
            if (isAdmin && t.status == 'registration') ...[
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: () => _showAddDialog(context),
                icon: const Icon(Icons.person_add_outlined, size: 16),
                label: const Text('Aggiungi'),
                style: FilledButton.styleFrom(visualDensity: VisualDensity.compact),
              ),
            ],
          ]),
          const SizedBox(height: 14),
          if (isAdmin)
            _AdminRegistrationList(registrations: t.adminRegistrations!, api: api, df: df, onChanged: onChanged)
          else if (t.registrations.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text('Nessun iscritto al momento.', style: TextStyle(color: Colors.grey.shade600)),
            )
          else
            ...t.registrations.asMap().entries.map((entry) {
              final i = entry.key;
              final r = entry.value;
              final isLogged = context.watch<Session>().isLogged;
              final name = isLogged ? '${r.firstName} ${r.lastName}' : 'Giocatore ${i + 1}';
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(children: [
                  _PositionBadge(position: i + 1),
                  const SizedBox(width: 10),
                  Expanded(child: Text(name,
                      style: const TextStyle(fontWeight: FontWeight.w600))),
                  if (isLogged)
                    Text(df.format(r.createdAt),
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                ]),
              );
            }),
        ]),
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => _AddPlayerDialog(tournamentId: t.id, api: api, onAdded: onChanged),
    );
  }
}

// ─── Admin registration list ──────────────────────────────────────────────────

class _AdminRegistrationList extends StatefulWidget {
  final List<FullRegistration> registrations;
  final ApiClient api;
  final DateFormat df;
  final VoidCallback onChanged;
  const _AdminRegistrationList({required this.registrations, required this.api, required this.df, required this.onChanged});
  @override
  State<_AdminRegistrationList> createState() => _AdminRegistrationListState();
}

class _AdminRegistrationListState extends State<_AdminRegistrationList> {
  final Set<int> _busy = {};

  Future<void> _togglePaid(FullRegistration reg) async {
    if (_busy.contains(reg.id)) return;
    setState(() => _busy.add(reg.id));
    try {
      if (reg.paid) {
        await widget.api.unmarkPaid(reg.id);
      } else {
        await widget.api.markPaid(reg.id);
      }
      widget.onChanged();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$e'), backgroundColor: Colors.red.shade700));
      }
    } finally {
      if (mounted) setState(() => _busy.remove(reg.id));
    }
  }

  Future<void> _delete(FullRegistration reg) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Rimuovi iscrizione'),
        content: Text('Vuoi rimuovere l\'iscrizione di ${reg.firstName} ${reg.lastName}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annulla')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            child: const Text('Rimuovi'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _busy.add(reg.id));
    try {
      await widget.api.deleteRegistration(reg.id);
      widget.onChanged();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$e'), backgroundColor: Colors.red.shade700));
      }
    } finally {
      if (mounted) setState(() => _busy.remove(reg.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.registrations.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text('Nessun iscritto al momento.', style: TextStyle(color: Colors.grey.shade600)),
      );
    }
    return Column(
      children: widget.registrations.asMap().entries.map((entry) {
        final i = entry.key;
        final reg = entry.value;
        final isBusy = _busy.contains(reg.id);
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
          decoration: BoxDecoration(
            color: reg.paid ? Colors.green.shade50 : const Color(0xFFF8F4FF),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: reg.paid ? Colors.green.shade200 : const Color(0xFFE0D6F5)),
          ),
          child: Row(children: [
            _PositionBadge(position: i + 1),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Flexible(child: Text('${reg.firstName} ${reg.lastName}',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                      overflow: TextOverflow.ellipsis)),
                  if (reg.userId == null) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(color: Colors.indigo.shade100, borderRadius: BorderRadius.circular(6)),
                      child: Text('admin', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.indigo.shade700)),
                    ),
                  ],
                ]),
                Text(reg.discordAccount, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ]),
            ),
            const SizedBox(width: 8),
            if (isBusy)
              const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
            else
              Tooltip(
                message: reg.paid ? 'Segna come non pagato' : 'Segna come pagato',
                child: InkWell(
                  onTap: () => _togglePaid(reg),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: reg.paid ? Colors.green.shade100 : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(reg.paid ? Icons.check_circle : Icons.radio_button_unchecked,
                          size: 15, color: reg.paid ? Colors.green.shade700 : Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(reg.paid ? 'Pagato' : 'Non pagato',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                              color: reg.paid ? Colors.green.shade700 : Colors.grey.shade600)),
                    ]),
                  ),
                ),
              ),
            const SizedBox(width: 6),
            IconButton(
              onPressed: isBusy ? null : () => _delete(reg),
              icon: Icon(Icons.delete_outline, color: Colors.red.shade400, size: 20),
              tooltip: 'Rimuovi iscrizione',
              visualDensity: VisualDensity.compact,
            ),
          ]),
        );
      }).toList(),
    );
  }
}

// ─── Add player dialog ────────────────────────────────────────────────────────

class _AddPlayerDialog extends StatefulWidget {
  final int tournamentId;
  final ApiClient api;
  final VoidCallback onAdded;
  const _AddPlayerDialog({required this.tournamentId, required this.api, required this.onAdded});
  @override
  State<_AddPlayerDialog> createState() => _AddPlayerDialogState();
}

class _AddPlayerDialogState extends State<_AddPlayerDialog> {
  final _formKey = GlobalKey<FormState>();
  final _discord = TextEditingController();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _discord.dispose();
    _firstName.dispose();
    _lastName.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await widget.api.adminRegister(widget.tournamentId, {
        'discord_account': _discord.text.trim(),
        'first_name': _firstName.text.trim(),
        'last_name': _lastName.text.trim(),
      });
      widget.onAdded();
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$e'), backgroundColor: Colors.red.shade700));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(children: [
        Icon(Icons.person_add_outlined, color: Color(0xFF5D2EA6)),
        SizedBox(width: 10),
        Text('Aggiungi giocatore'),
      ]),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextFormField(
              controller: _discord,
              decoration: const InputDecoration(labelText: 'Account Discord', prefixIcon: Icon(Icons.person_pin_outlined)),
              autofocus: true,
              validator: (v) => v == null || v.trim().length < 2 ? 'Campo obbligatorio' : null,
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: TextFormField(
                  controller: _firstName,
                  decoration: const InputDecoration(labelText: 'Nome', prefixIcon: Icon(Icons.person_outlined)),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Obbligatorio' : null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: _lastName,
                  decoration: const InputDecoration(labelText: 'Cognome', prefixIcon: Icon(Icons.badge_outlined)),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Obbligatorio' : null,
                ),
              ),
            ]),
          ]),
        ),
      ),
      actions: [
        TextButton(onPressed: _saving ? null : () => Navigator.of(context).pop(), child: const Text('Annulla')),
        FilledButton.icon(
          onPressed: _saving ? null : _submit,
          icon: _saving
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.add),
          label: Text(_saving ? 'Aggiunta...' : 'Aggiungi'),
        ),
      ],
    );
  }
}

// ─── Shared widgets ───────────────────────────────────────────────────────────

class _PositionBadge extends StatelessWidget {
  final int position;
  const _PositionBadge({required this.position});

  @override
  Widget build(BuildContext context) {
    final colors = [const Color(0xFFFFD66B), Colors.grey.shade300, Colors.brown.shade200];
    final bg = position <= 3 ? colors[position - 1] : const Color(0xFFF1E7FF);
    return Container(
      width: 28, height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text('$position', style: TextStyle(
        fontSize: 12, fontWeight: FontWeight.w800,
        color: position <= 3 ? const Color(0xFF2D145C) : const Color(0xFF5D2EA6),
      )),
    );
  }
}

class _PaymentBadge extends StatelessWidget {
  final bool paid;
  const _PaymentBadge({required this.paid});

  @override
  Widget build(BuildContext context) {
    if (paid) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: Colors.green.shade100, borderRadius: BorderRadius.circular(20)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.check_circle_outline, color: Colors.green.shade700, size: 16),
          const SizedBox(width: 6),
          Text('Pagamento confermato',
              style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.w600, fontSize: 13)),
        ]),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.pending_outlined, color: Colors.orange.shade700, size: 16),
        const SizedBox(width: 6),
        Text('In attesa di pagamento',
            style: TextStyle(color: Colors.orange.shade700, fontWeight: FontWeight.w600, fontSize: 13)),
      ]),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool light;
  const _InfoChip({required this.icon, required this.text, this.light = false});

  @override
  Widget build(BuildContext context) {
    final fg = light ? Colors.white.withValues(alpha: .9) : const Color(0xFF5D2EA6);
    final bg = light ? Colors.white.withValues(alpha: .15) : const Color(0xFFF1E7FF);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: fg),
        const SizedBox(width: 5),
        Text(text, style: TextStyle(fontSize: 12, color: fg, fontWeight: FontWeight.w500)),
      ]),
    );
  }
}
