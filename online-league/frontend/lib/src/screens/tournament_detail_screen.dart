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

class _TournamentDetailScreenState extends State<TournamentDetailScreen> {
  late Future<TournamentDetail> _future;
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
    super.dispose();
  }

  void _reload({bool silent = false}) {
    if (!mounted) return;
    setState(() {
      _future = widget.api.tournament(widget.tournamentId);
    });
    if (!silent) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Dati aggiornati')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.go('/'),
          icon: const Icon(Icons.home_outlined),
          tooltip: 'Home',
        ),
        title: const Text('Dettaglio torneo'),
        actions: [
          IconButton(onPressed: _reload, icon: const Icon(Icons.refresh), tooltip: 'Aggiorna'),
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
        child: FutureBuilder<TournamentDetail>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                  const SizedBox(height: 12),
                  Text('${snap.error}'),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                      onPressed: _reload,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Riprova')),
                ]),
              );
            }
            final t = snap.data!;
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1050),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      _HeroCard(t: t),
                      const SizedBox(height: 18),
                      LayoutBuilder(builder: (context, c) {
                        final wide = c.maxWidth > 850;
                        final registerPanel = _RegisterPanel(
                          t: t,
                          api: widget.api,
                          onChanged: () => _reload(silent: true),
                        );
                        final playersPanel = _PlayersPanel(
                          t: t,
                          api: widget.api,
                          onChanged: () => _reload(silent: true),
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
          },
        ),
      ),
    );
  }
}

// ─── Hero card ────────────────────────────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  final TournamentDetail t;
  const _HeroCard({required this.t});

  @override
  Widget build(BuildContext context) {
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
                  _InfoChip(
                      icon: Icons.event_available_outlined,
                      text: df.format(t.endDate),
                      light: true),
                  _InfoChip(
                    icon: Icons.payments_outlined,
                    text: t.entryFeeEur == 0 ? 'Gratuito' : '€ ${t.entryFeeEur.toStringAsFixed(2)}',
                    light: true,
                  ),
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
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7D6),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0xFFFFD66B)),
                  ),
                  child: Text('$medal  ${p.percentage.toStringAsFixed(0)}%',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                );
              }).toList(),
            ),
          ]),
        ),
      ]),
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
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Colors.grey.shade700)),
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
                const SizedBox(height: 12),
                _PaymentBadge(paid: myReg.paid),
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
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Colors.grey.shade700)),
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
          // Header
          Row(children: [
            const Icon(Icons.groups_outlined, size: 20, color: Color(0xFF5D2EA6)),
            const SizedBox(width: 8),
            Text('Giocatori iscritti',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                  color: const Color(0xFF5D2EA6).withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(20)),
              child: Text('${t.registeredCount}',
                  style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF5D2EA6))),
            ),
            if (isAdmin) ...[
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
            // ── Admin view ──
            _AdminRegistrationList(
              registrations: t.adminRegistrations!,
              api: api,
              df: df,
              onChanged: onChanged,
            )
          else if (t.registrations.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text('Nessun iscritto al momento.',
                  style: TextStyle(color: Colors.grey.shade600)),
            )
          else
            // ── Public view ──
            ...t.registrations.asMap().entries.map((entry) {
              final i = entry.key;
              final r = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(children: [
                  _PositionBadge(position: i + 1),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text('${r.firstName} ${r.lastName}',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                  ),
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
      builder: (_) => _AddPlayerDialog(
        tournamentId: t.id,
        api: api,
        onAdded: onChanged,
      ),
    );
  }
}

// ─── Admin registration list ──────────────────────────────────────────────────

class _AdminRegistrationList extends StatefulWidget {
  final List<FullRegistration> registrations;
  final ApiClient api;
  final DateFormat df;
  final VoidCallback onChanged;
  const _AdminRegistrationList({
    required this.registrations,
    required this.api,
    required this.df,
    required this.onChanged,
  });
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
        content: Text(
            'Vuoi rimuovere l\'iscrizione di ${reg.firstName} ${reg.lastName}?'),
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
        child: Text('Nessun iscritto al momento.',
            style: TextStyle(color: Colors.grey.shade600)),
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
            color: reg.paid
                ? Colors.green.shade50
                : const Color(0xFFF8F4FF),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: reg.paid
                  ? Colors.green.shade200
                  : const Color(0xFFE0D6F5),
            ),
          ),
          child: Row(children: [
            _PositionBadge(position: i + 1),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Flexible(
                    child: Text(
                      '${reg.firstName} ${reg.lastName}',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (reg.userId == null) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.indigo.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('admin',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.indigo.shade700)),
                    ),
                  ],
                ]),
                Text(reg.discordAccount,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ]),
            ),
            const SizedBox(width: 8),
            // Paid toggle
            if (isBusy)
              const SizedBox(
                  width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
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
                      Icon(
                        reg.paid ? Icons.check_circle : Icons.radio_button_unchecked,
                        size: 15,
                        color: reg.paid ? Colors.green.shade700 : Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        reg.paid ? 'Pagato' : 'Non pagato',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: reg.paid ? Colors.green.shade700 : Colors.grey.shade600,
                        ),
                      ),
                    ]),
                  ),
                ),
              ),
            const SizedBox(width: 6),
            // Delete button
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
  const _AddPlayerDialog(
      {required this.tournamentId, required this.api, required this.onAdded});
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
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextFormField(
              controller: _discord,
              decoration: const InputDecoration(
                labelText: 'Account Discord',
                prefixIcon: Icon(Icons.person_pin_outlined),
              ),
              autofocus: true,
              validator: (v) =>
                  v == null || v.trim().length < 2 ? 'Campo obbligatorio' : null,
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: TextFormField(
                  controller: _firstName,
                  decoration: const InputDecoration(
                    labelText: 'Nome',
                    prefixIcon: Icon(Icons.person_outlined),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Obbligatorio' : null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: _lastName,
                  decoration: const InputDecoration(
                    labelText: 'Cognome',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Obbligatorio' : null,
                ),
              ),
            ]),
          ]),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Annulla'),
        ),
        FilledButton.icon(
          onPressed: _saving ? null : _submit,
          icon: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
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
    final colors = [
      const Color(0xFFFFD66B),
      Colors.grey.shade300,
      Colors.brown.shade200,
    ];
    final bg = position <= 3 ? colors[position - 1] : const Color(0xFFF1E7FF);
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(
        '$position',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: position <= 3 ? const Color(0xFF2D145C) : const Color(0xFF5D2EA6),
        ),
      ),
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
        decoration:
            BoxDecoration(color: Colors.green.shade100, borderRadius: BorderRadius.circular(20)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.check_circle_outline, color: Colors.green.shade700, size: 16),
          const SizedBox(width: 6),
          Text('Pagamento confermato',
              style: TextStyle(
                  color: Colors.green.shade700, fontWeight: FontWeight.w600, fontSize: 13)),
        ]),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration:
          BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.pending_outlined, color: Colors.orange.shade700, size: 16),
        const SizedBox(width: 6),
        Text('In attesa di pagamento',
            style: TextStyle(
                color: Colors.orange.shade700, fontWeight: FontWeight.w600, fontSize: 13)),
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
        Text(text,
            style: TextStyle(fontSize: 12, color: fg, fontWeight: FontWeight.w500)),
      ]),
    );
  }
}
