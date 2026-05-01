import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/tournament.dart';
import '../services/api_client.dart';
import '../services/session.dart';

// ─── Predefined time slots ────────────────────────────────────────────────────

class _SlotDef {
  final String key, label, timeStart, timeEnd;
  const _SlotDef(this.key, this.label, this.timeStart, this.timeEnd);
}

const _kSlots = [
  _SlotDef('00:00', '00–02', '00:00', '02:00'),
  _SlotDef('02:00', '02–04', '02:00', '04:00'),
  _SlotDef('04:00', '04–06', '04:00', '06:00'),
  _SlotDef('06:00', '06–08', '06:00', '08:00'),
  _SlotDef('08:00', '08–10', '08:00', '10:00'),
  _SlotDef('10:00', '10–12', '10:00', '12:00'),
  _SlotDef('12:00', '12–14', '12:00', '14:00'),
  _SlotDef('14:00', '14–16', '14:00', '16:00'),
  _SlotDef('16:00', '16–18', '16:00', '18:00'),
  _SlotDef('18:00', '18–20', '18:00', '20:00'),
  _SlotDef('20:00', '20–22', '20:00', '22:00'),
  _SlotDef('22:00', '22–00', '22:00', '00:00'),
];

String _slotKey(String timeStart) => timeStart;

List<DateTime> _dateRange(DateTime start, DateTime end) {
  final dates = <DateTime>[];
  var d = DateTime(start.year, start.month, start.day);
  final last = DateTime(end.year, end.month, end.day);
  while (!d.isAfter(last)) {
    dates.add(d);
    d = d.add(const Duration(days: 1));
  }
  return dates;
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class AvailabilityScreen extends StatefulWidget {
  final ApiClient api;
  final int tournamentId;
  const AvailabilityScreen({super.key, required this.api, required this.tournamentId});

  @override
  State<AvailabilityScreen> createState() => _AvailabilityScreenState();
}

class _AvailabilityScreenState extends State<AvailabilityScreen>
    with TickerProviderStateMixin {
  late final TabController _tabs;

  TournamentDetail? _tournament;
  List<PlayerAvailability> _allAvail = [];
  int? _myRegId;
  bool _loading = true;
  bool _availForbidden = false;
  String? _error;

  // My edit state: Map<"YYYY-MM-DD", Set<slotKey>>
  Map<String, Set<String>> _mySlots = {};
  bool _dirty = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final t = await widget.api.tournament(widget.tournamentId);
      List<PlayerAvailability> avail = [];
      bool forbidden = false;
      try {
        avail = await widget.api.getAvailability(widget.tournamentId);
      } catch (_) {
        forbidden = true;
      }
      if (!mounted) return;
      setState(() {
        _tournament = t;
        _allAvail = avail;
        _availForbidden = forbidden;
        _myRegId = t.myRegistration?.id;
        _initMySlots(avail);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = '$e'; _loading = false; });
    }
  }

  void _initMySlots(List<PlayerAvailability> avail) {
    final rid = _myRegId;
    if (rid == null) return;
    _mySlots = {};
    try {
      final mine = avail.firstWhere((p) => p.regId == rid);
      for (final s in mine.slots) {
        _mySlots.putIfAbsent(s.slotDate, () => {}).add(_slotKey(s.timeStart));
      }
    } catch (_) {}
    _dirty = false;
  }

  void _toggle(String dateKey, String key) {
    setState(() {
      final set = _mySlots.putIfAbsent(dateKey, () => {});
      if (set.contains(key)) {
        set.remove(key);
        if (set.isEmpty) _mySlots.remove(dateKey);
      } else {
        set.add(key);
      }
      _dirty = true;
    });
  }

  void _toggleDay(String dateKey) {
    setState(() {
      final set = _mySlots[dateKey] ?? {};
      if (_kSlots.every((s) => set.contains(s.key))) {
        _mySlots.remove(dateKey);
      } else {
        _mySlots[dateKey] = _kSlots.map((s) => s.key).toSet();
      }
      _dirty = true;
    });
  }

  Future<void> _save() async {
    if (!_dirty) return;
    setState(() => _saving = true);
    try {
      final slots = <Map<String, dynamic>>[];
      _mySlots.forEach((dateKey, keys) {
        for (final k in keys) {
          final def = _kSlots.firstWhere((s) => s.key == k);
          slots.add({'slot_date': dateKey, 'time_start': def.timeStart, 'time_end': def.timeEnd});
        }
      });
      await widget.api.updateMyAvailability(widget.tournamentId, slots);
      final avail = await widget.api.getAvailability(widget.tournamentId);
      if (!mounted) return;
      setState(() { _allAvail = avail; _dirty = false; });
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Disponibilità salvata!')));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$e'), backgroundColor: Colors.red.shade700));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _saveForPlayer(int regId, Map<String, Set<String>> slots) async {
    setState(() => _saving = true);
    try {
      final list = <Map<String, dynamic>>[];
      slots.forEach((dateKey, keys) {
        for (final k in keys) {
          final def = _kSlots.firstWhere((s) => s.key == k);
          list.add({'slot_date': dateKey, 'time_start': def.timeStart, 'time_end': def.timeEnd});
        }
      });
      await widget.api.updatePlayerAvailability(widget.tournamentId, regId, list);
      final avail = await widget.api.getAvailability(widget.tournamentId);
      if (!mounted) return;
      setState(() => _allAvail = avail);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Disponibilità aggiornata!')));
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
    final t = _tournament;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.go('/tournaments/${widget.tournamentId}'),
          icon: const Icon(Icons.arrow_back_ios_new),
        ),
        title: Text(t != null ? 'Disponibilità · ${t.title}' : 'Disponibilità'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh), tooltip: 'Aggiorna'),
        ],
        bottom: TabBar(
          controller: _tabs,
          tabs: const [Tab(text: 'Le mie'), Tab(text: 'Tutti i giocatori')],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF3EEFF), Color(0xFFFFF8E7)],
          ),
        ),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                      const SizedBox(height: 12),
                      Text(_error!),
                      const SizedBox(height: 8),
                      FilledButton.icon(onPressed: _load, icon: const Icon(Icons.refresh), label: const Text('Riprova')),
                    ]),
                  )
                : TabBarView(
                    controller: _tabs,
                    children: [_buildMyTab(context), _buildAllTab(context)],
                  ),
      ),
    );
  }

  // ─── Tab "Le mie" ───────────────────────────────────────────────────────────

  Widget _buildMyTab(BuildContext context) {
    final session = context.watch<Session>();
    final t = _tournament!;

    if (!session.isLogged) {
      return _placeholder(Icons.login_outlined, 'Accedi per continuare',
          'Effettua il login con Discord per inserire le tue disponibilità.');
    }
    if (_myRegId == null) {
      return _placeholder(Icons.person_off_outlined, 'Non sei iscritto',
          'Devi essere iscritto al torneo per inserire le tue disponibilità.');
    }

    final dates = _dateRange(t.startDate, t.endDate);
    final dfHeader = DateFormat('MMMM yyyy', 'it_IT');
    final dfRow = DateFormat('EEE d MMM', 'it_IT');

    String? lastMonth;

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            itemCount: dates.length,
            itemBuilder: (context, i) {
              final date = dates[i];
              final dateKey = DateFormat('yyyy-MM-dd').format(date);
              final monthKey = dfHeader.format(date);
              final selected = _mySlots[dateKey] ?? {};
              final isToday = _isToday(date);

              Widget? monthHeader;
              if (monthKey != lastMonth) {
                lastMonth = monthKey;
                monthHeader = Padding(
                  padding: const EdgeInsets.only(top: 14, bottom: 6),
                  child: Text(
                    monthKey[0].toUpperCase() + monthKey.substring(1),
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF3C176E)),
                  ),
                );
              }

              final row = Container(
                margin: const EdgeInsets.only(bottom: 2),
                decoration: BoxDecoration(
                  color: isToday
                      ? const Color(0xFFEDE7FF)
                      : selected.isNotEmpty
                          ? const Color(0xFFF3EEFF)
                          : Colors.white.withValues(alpha: .7),
                  borderRadius: BorderRadius.circular(12),
                  border: isToday ? Border.all(color: const Color(0xFF5D2EA6).withValues(alpha: .4)) : null,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  child: Row(children: [
                    GestureDetector(
                      onTap: () => _toggleDay(dateKey),
                      child: Tooltip(
                        message: 'Tocca per selezionare/deselezionare tutto il giorno',
                        child: SizedBox(
                          width: 82,
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(
                              dfRow.format(date),
                              style: TextStyle(
                                fontWeight: isToday ? FontWeight.w800 : FontWeight.w500,
                                fontSize: 12,
                                color: isToday ? const Color(0xFF5D2EA6) : Colors.black87,
                              ),
                            ),
                            if (isToday)
                              Text('Oggi',
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.purple.shade400,
                                      fontWeight: FontWeight.w700)),
                          ]),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: _kSlots.map((s) {
                          final sel = selected.contains(s.key);
                          return FilterChip(
                            label: Text(s.label, style: const TextStyle(fontSize: 12)),
                            selected: sel,
                            onSelected: (_) => _toggle(dateKey, s.key),
                            showCheckmark: false,
                            selectedColor: const Color(0xFF5D2EA6).withValues(alpha: .15),
                            checkmarkColor: const Color(0xFF5D2EA6),
                            side: BorderSide(
                                color: sel
                                    ? const Color(0xFF5D2EA6)
                                    : Colors.grey.shade300),
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          );
                        }).toList(),
                      ),
                    ),
                  ]),
                ),
              );

              if (monthHeader != null) {
                return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [monthHeader, row]);
              }
              return row;
            },
          ),
        ),
        // Sticky save bar
        Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: .08), blurRadius: 12, offset: const Offset(0, -3))
            ],
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: (_dirty && !_saving) ? _save : null,
                icon: _saving
                    ? const SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save_outlined),
                label: Text(_saving
                    ? 'Salvataggio...'
                    : _dirty
                        ? 'Salva disponibilità'
                        : 'Nessuna modifica da salvare'),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Tab "Tutti" ────────────────────────────────────────────────────────────

  Widget _buildAllTab(BuildContext context) {
    final session = context.watch<Session>();
    final t = _tournament!;

    if (_availForbidden) {
      return _placeholder(Icons.lock_outline, 'Accesso non consentito',
          'Devi essere iscritto al torneo per consultare le disponibilità degli altri giocatori.');
    }
    if (_allAvail.isEmpty) {
      return _placeholder(Icons.event_busy_outlined, 'Nessuna disponibilità',
          'Nessun giocatore ha ancora inserito le proprie disponibilità.');
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      itemCount: _allAvail.length,
      itemBuilder: (context, i) {
        final player = _allAvail[i];
        return _PlayerCard(
          player: player,
          isMe: player.regId == _myRegId,
          onEdit: session.isAdmin
              ? () => _showAdminEdit(context, player, t)
              : null,
        );
      },
    );
  }

  void _showAdminEdit(BuildContext context, PlayerAvailability player, TournamentDetail t) {
    final initial = <String, Set<String>>{};
    for (final s in player.slots) {
      initial.putIfAbsent(s.slotDate, () => {}).add(_slotKey(s.timeStart));
    }
    showDialog(
      context: context,
      builder: (_) => _AdminEditDialog(
        player: player,
        tournament: t,
        initialSlots: initial,
        onSave: (slots) => _saveForPlayer(player.regId, slots),
      ),
    );
  }

  Widget _placeholder(IconData icon, String title, String sub) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 52, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(title,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text(sub,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              textAlign: TextAlign.center),
        ]),
      ),
    );
  }

  bool _isToday(DateTime d) {
    final n = DateTime.now();
    return d.year == n.year && d.month == n.month && d.day == n.day;
  }
}

// ─── Player availability card (collapsible) ───────────────────────────────────

class _PlayerCard extends StatefulWidget {
  final PlayerAvailability player;
  final bool isMe;
  final VoidCallback? onEdit;
  const _PlayerCard({required this.player, required this.isMe, this.onEdit});

  @override
  State<_PlayerCard> createState() => _PlayerCardState();
}

class _PlayerCardState extends State<_PlayerCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final player = widget.player;
    final byDate = <String, List<String>>{};
    for (final s in player.slots) {
      byDate.putIfAbsent(s.slotDate, () => []).add(_slotKey(s.timeStart));
    }
    final sortedDates = byDate.keys.toList()..sort();
    final df = DateFormat('EEE d MMM', 'it_IT');
    final daysCount = sortedDates.length;
    final totalSlots = player.slots.length;

    return Card(
      elevation: 0,
      color: widget.isMe ? const Color(0xFFF3EEFF) : Colors.white.withValues(alpha: .95),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: widget.isMe
            ? const BorderSide(color: Color(0xFF5D2EA6), width: .8)
            : BorderSide.none,
      ),
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: Column(children: [
        // ── Header row (always visible, tappable) ──────────────────────────
        InkWell(
          onTap: daysCount > 0 ? () => setState(() => _expanded = !_expanded) : null,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
            child: Row(children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: widget.isMe ? const Color(0xFF5D2EA6) : Colors.grey.shade400,
                child: Text(
                  '${player.firstName[0]}${player.lastName[0]}'.toUpperCase(),
                  style: const TextStyle(
                      color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Text(player.fullName,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    if (widget.isMe) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFF5D2EA6).withValues(alpha: .15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('Tu',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF5D2EA6))),
                      ),
                    ],
                  ]),
                  const SizedBox(height: 2),
                  Text(
                    daysCount == 0
                        ? 'Nessuna disponibilità inserita'
                        : '$daysCount ${daysCount == 1 ? 'giorno' : 'giorni'} · $totalSlots ${totalSlots == 1 ? 'fascia' : 'fasce'}',
                    style: TextStyle(
                        fontSize: 12,
                        color: daysCount == 0
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                        fontStyle:
                            daysCount == 0 ? FontStyle.italic : FontStyle.normal),
                  ),
                ]),
              ),
              if (widget.onEdit != null)
                IconButton(
                  onPressed: widget.onEdit,
                  icon: const Icon(Icons.edit_calendar_outlined, size: 18),
                  tooltip: 'Modifica disponibilità',
                  visualDensity: VisualDensity.compact,
                ),
              if (daysCount > 0)
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(Icons.expand_more, color: Colors.grey.shade600),
                )
              else
                const SizedBox(width: 8),
            ]),
          ),
        ),

        // ── Expandable detail ──────────────────────────────────────────────
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Divider(color: Colors.grey.shade200, height: 1),
                const SizedBox(height: 10),
                ...sortedDates.map((dateKey) {
                  final dt = DateTime.parse(dateKey);
                  final keys = byDate[dateKey]!;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(children: [
                      SizedBox(
                        width: 82,
                        child: Text(df.format(dt),
                            style: const TextStyle(
                                fontSize: 12, color: Colors.black54)),
                      ),
                      Expanded(
                        child: Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: keys.map((k) {
                            final def = _kSlots.firstWhere((s) => s.key == k,
                                orElse: () => _kSlots.first);
                            return Chip(
                              label: Text(def.label,
                                  style: const TextStyle(fontSize: 11)),
                              backgroundColor: const Color(0xFFF3EEFF),
                              side: BorderSide(
                                  color: const Color(0xFF5D2EA6)
                                      .withValues(alpha: .3)),
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            );
                          }).toList(),
                        ),
                      ),
                    ]),
                  );
                }),
              ],
            ),
          ),
          crossFadeState:
              _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 220),
          sizeCurve: Curves.easeInOut,
        ),
      ]),
    );
  }
}

// ─── Admin edit dialog ────────────────────────────────────────────────────────

class _AdminEditDialog extends StatefulWidget {
  final PlayerAvailability player;
  final TournamentDetail tournament;
  final Map<String, Set<String>> initialSlots;
  final Future<void> Function(Map<String, Set<String>>) onSave;
  const _AdminEditDialog({
    required this.player,
    required this.tournament,
    required this.initialSlots,
    required this.onSave,
  });

  @override
  State<_AdminEditDialog> createState() => _AdminEditDialogState();
}

class _AdminEditDialogState extends State<_AdminEditDialog> {
  late Map<String, Set<String>> _slots;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _slots = {for (final e in widget.initialSlots.entries) e.key: Set.from(e.value)};
  }

  void _toggle(String dateKey, String key) {
    setState(() {
      final set = _slots.putIfAbsent(dateKey, () => {});
      if (set.contains(key)) {
        set.remove(key);
        if (set.isEmpty) _slots.remove(dateKey);
      } else {
        set.add(key);
      }
    });
  }

  void _toggleDay(String dateKey) {
    setState(() {
      final set = _slots[dateKey] ?? {};
      if (_kSlots.every((s) => set.contains(s.key))) {
        _slots.remove(dateKey);
      } else {
        _slots[dateKey] = _kSlots.map((s) => s.key).toSet();
      }
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await widget.onSave(_slots);
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dates = _dateRange(widget.tournament.startDate, widget.tournament.endDate);
    final dfHeader = DateFormat('MMMM yyyy', 'it_IT');
    final dfRow = DateFormat('EEE d MMM', 'it_IT');
    String? lastMonth;

    return AlertDialog(
      title: Row(children: [
        const Icon(Icons.edit_calendar_outlined, color: Color(0xFF5D2EA6)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(widget.player.fullName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        ),
      ]),
      content: SizedBox(
        width: double.maxFinite,
        height: 460,
        child: ListView.builder(
          itemCount: dates.length,
          itemBuilder: (context, i) {
            final date = dates[i];
            final dateKey = DateFormat('yyyy-MM-dd').format(date);
            final monthKey = dfHeader.format(date);
            final sel = _slots[dateKey] ?? {};

            Widget? header;
            if (monthKey != lastMonth) {
              lastMonth = monthKey;
              header = Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 4),
                child: Text(
                  monthKey[0].toUpperCase() + monthKey.substring(1),
                  style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      color: Color(0xFF3C176E)),
                ),
              );
            }

            final row = Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(children: [
                GestureDetector(
                  onTap: () => _toggleDay(dateKey),
                  child: Tooltip(
                    message: 'Tocca per selezionare/deselezionare tutto il giorno',
                    child: SizedBox(
                      width: 80,
                      child: Text(dfRow.format(date),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                    ),
                  ),
                ),
                Expanded(
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: _kSlots.map((s) {
                      final selected = sel.contains(s.key);
                      return FilterChip(
                        label: Text(s.label, style: const TextStyle(fontSize: 11)),
                        selected: selected,
                        onSelected: (_) => _toggle(dateKey, s.key),
                        showCheckmark: false,
                        selectedColor: const Color(0xFF5D2EA6).withValues(alpha: .15),
                        checkmarkColor: const Color(0xFF5D2EA6),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      );
                    }).toList(),
                  ),
                ),
              ]),
            );

            if (header != null) {
              return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [header, row]);
            }
            return row;
          },
        ),
      ),
      actions: [
        TextButton(
            onPressed: _saving ? null : () => Navigator.of(context).pop(),
            child: const Text('Annulla')),
        FilledButton.icon(
          onPressed: _saving ? null : _save,
          icon: _saving
              ? const SizedBox(
                  width: 14, height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.save_outlined, size: 16),
          label: Text(_saving ? 'Salvataggio...' : 'Salva'),
        ),
      ],
    );
  }
}
