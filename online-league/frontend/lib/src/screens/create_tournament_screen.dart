import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../models/tournament.dart';
import '../services/api_client.dart';

class CreateTournamentScreen extends StatefulWidget {
  final ApiClient api;
  final Tournament? editTournament; // non-null → edit mode
  const CreateTournamentScreen({super.key, required this.api, this.editTournament});
  @override
  State<CreateTournamentScreen> createState() => _CreateTournamentScreenState();
}

class _CreateTournamentScreenState extends State<CreateTournamentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _cap = TextEditingController(text: '32');
  final _fee = TextEditingController(text: '10');
  final _paypal = TextEditingController();
  final _startCtrl = TextEditingController();
  final _endCtrl = TextEditingController();
  final _rules = TextEditingController();
  final _prizes = TextEditingController(text: '50,30,20');
  final _df = DateFormat('dd/MM/yyyy HH:mm');
  late DateTime _startDate;
  late DateTime _endDate;
  bool _saving = false;

  bool get _isEdit => widget.editTournament != null;

  List<double> get _parsedPrizes {
    try {
      return _prizes.text.split(',').map((e) => double.parse(e.trim())).toList();
    } catch (_) {
      return [];
    }
  }

  double get _prizeSum => _parsedPrizes.fold(0.0, (a, b) => a + b);

  @override
  void initState() {
    super.initState();
    final t = widget.editTournament;
    if (t != null) {
      _title.text = t.title;
      _cap.text = t.cap.toString();
      _fee.text = t.entryFeeEur.toStringAsFixed(t.entryFeeEur % 1 == 0 ? 0 : 2);
      _paypal.text = t.paypalLink;
      _startDate = t.startDate;
      _endDate = t.endDate;
      _rules.text = t.rulesDescription;
      _prizes.text = t.prizeDistribution.map((p) {
        final pct = p.percentage;
        return pct % 1 == 0 ? pct.toInt().toString() : pct.toStringAsFixed(2);
      }).join(',');
    } else {
      _startDate = DateTime.now().add(const Duration(days: 7));
      _endDate = _startDate.add(const Duration(hours: 4));
    }
    _syncDateControllers();
  }

  @override
  void dispose() {
    _title.dispose();
    _cap.dispose();
    _fee.dispose();
    _paypal.dispose();
    _startCtrl.dispose();
    _endCtrl.dispose();
    _rules.dispose();
    _prizes.dispose();
    super.dispose();
  }

  void _syncDateControllers() {
    _startCtrl.text = _df.format(_startDate);
    _endCtrl.text = _df.format(_endDate);
  }

  Future<void> _pickDateTime({required bool isStart}) async {
    final initial = isStart ? _startDate : _endDate;
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) return;
    final picked = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    setState(() {
      if (isStart) {
        _startDate = picked;
        if (!_endDate.isAfter(_startDate)) {
          _endDate = _startDate.add(const Duration(hours: 4));
        }
      } else {
        _endDate = picked;
      }
      _syncDateControllers();
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final perc = _parsedPrizes;
    final fee = double.parse(_fee.text.replaceAll(',', '.'));
    final payload = {
      'title': _title.text.trim(),
      'cap': int.parse(_cap.text),
      'entry_fee_eur': fee,
      'paypal_link': fee > 0 ? _paypal.text.trim() : null,
      'start_date': _startDate.toIso8601String(),
      'end_date': _endDate.toIso8601String(),
      'rules_description': _rules.text.trim(),
      'prize_players_count': perc.length,
      'prize_distribution': [
        for (var i = 0; i < perc.length; i++) {'position': i + 1, 'percentage': perc[i]}
      ],
    };
    try {
      if (_isEdit) {
        await widget.api.updateTournament(widget.editTournament!.id, payload);
        if (mounted) context.go('/tournaments/${widget.editTournament!.id}');
      } else {
        await widget.api.createTournament(payload);
        if (mounted) context.go('/');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: Colors.red.shade700),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => _isEdit
              ? context.go('/tournaments/${widget.editTournament!.id}')
              : context.go('/'),
          icon: Icon(_isEdit ? Icons.arrow_back : Icons.home_outlined),
          tooltip: _isEdit ? 'Torna al torneo' : 'Home',
        ),
        title: Text(_isEdit ? 'Modifica torneo' : 'Crea torneo'),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF3EEFF), Color(0xFFFFF8E7)],
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860),
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
                children: [
                  Card(
                    elevation: 0,
                    color: const Color(0xFF2D145C),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
                      child: Row(children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFD66B),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            _isEdit ? Icons.edit_outlined : Icons.add_circle_outline,
                            color: const Color(0xFF2D145C),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(
                              _isEdit ? 'Modifica torneo' : 'Nuovo torneo Lorcana',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                            Text(
                              _isEdit
                                  ? 'Aggiorna i dati del torneo.'
                                  : 'Compila i dati del torneo che vuoi creare.',
                              style: TextStyle(color: Colors.white.withValues(alpha: .75), fontSize: 13),
                            ),
                          ]),
                        ),
                      ]),
                    ),
                  ),

                  const SizedBox(height: 16),

                  _SectionHeader(label: 'Informazioni generali', icon: Icons.info_outline),
                  _FormCard(children: [
                    TextFormField(
                      controller: _title,
                      decoration: const InputDecoration(
                        labelText: 'Nome del torneo',
                        prefixIcon: Icon(Icons.auto_awesome_outlined),
                      ),
                      validator: (v) => v == null || v.length < 3 ? 'Minimo 3 caratteri' : null,
                    ),
                    const SizedBox(height: 12),
                    LayoutBuilder(builder: (ctx, c) {
                      final capField = TextFormField(
                        controller: _cap,
                        decoration: const InputDecoration(
                          labelText: 'CAP iscritti',
                          prefixIcon: Icon(Icons.groups_outlined),
                          hintText: 'Es: 32',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          final n = int.tryParse(v ?? '');
                          return n == null || n <= 0 ? 'Numero valido richiesto' : null;
                        },
                      );
                      final feeField = TextFormField(
                        controller: _fee,
                        decoration: const InputDecoration(
                          labelText: 'Quota iscrizione (€)',
                          prefixIcon: Icon(Icons.euro_outlined),
                          hintText: '0 = gratuito',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onChanged: (_) => setState(() {}),
                        validator: (v) {
                          final n = double.tryParse(v?.replaceAll(',', '.') ?? '');
                          return n == null || n < 0 ? 'Importo valido richiesto' : null;
                        },
                      );
                      if (c.maxWidth < 400) {
                        return Column(children: [capField, const SizedBox(height: 12), feeField]);
                      }
                      return Row(children: [
                        Expanded(child: capField),
                        const SizedBox(width: 12),
                        Expanded(child: feeField),
                      ]);
                    }),
                    if ((double.tryParse(_fee.text.replaceAll(',', '.')) ?? 0) > 0) ...[
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _paypal,
                        decoration: const InputDecoration(
                          labelText: 'Link PayPal',
                          prefixIcon: Icon(Icons.payments_outlined),
                          hintText: 'https://paypal.me/...',
                        ),
                        validator: (v) =>
                            v == null || !v.startsWith('http') ? 'Inserire un URL valido' : null,
                      ),
                    ],
                  ]),

                  _SectionHeader(label: 'Date e orari', icon: Icons.calendar_month_outlined),
                  _FormCard(children: [
                    LayoutBuilder(builder: (ctx, c) {
                      final startField = TextFormField(
                        controller: _startCtrl,
                        readOnly: true,
                        onTap: () => _pickDateTime(isStart: true),
                        decoration: const InputDecoration(
                          labelText: 'Inizio torneo',
                          prefixIcon: Icon(Icons.play_circle_outline),
                          suffixIcon: Icon(Icons.expand_more),
                        ),
                      );
                      final endField = TextFormField(
                        controller: _endCtrl,
                        readOnly: true,
                        onTap: () => _pickDateTime(isStart: false),
                        decoration: const InputDecoration(
                          labelText: 'Fine torneo',
                          prefixIcon: Icon(Icons.stop_circle_outlined),
                          suffixIcon: Icon(Icons.expand_more),
                        ),
                        validator: (_) =>
                            _endDate.isAfter(_startDate) ? null : 'La fine deve essere dopo l\'inizio',
                      );
                      if (c.maxWidth < 400) {
                        return Column(children: [startField, const SizedBox(height: 12), endField]);
                      }
                      return Row(children: [
                        Expanded(child: startField),
                        const SizedBox(width: 12),
                        Expanded(child: endField),
                      ]);
                    }),
                  ]),

                  _SectionHeader(label: 'Regole e descrizione', icon: Icons.menu_book_outlined),
                  _FormCard(children: [
                    TextFormField(
                      controller: _rules,
                      decoration: const InputDecoration(
                        labelText: 'Descrizione e regolamento',
                        prefixIcon: Padding(
                          padding: EdgeInsets.only(bottom: 80),
                          child: Icon(Icons.notes_outlined),
                        ),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 6,
                      validator: (v) => v == null || v.isEmpty ? 'Campo obbligatorio' : null,
                    ),
                  ]),

                  _SectionHeader(label: 'Distribuzione montepremi', icon: Icons.emoji_events_outlined),
                  _FormCard(children: [
                    TextFormField(
                      controller: _prizes,
                      decoration: const InputDecoration(
                        labelText: 'Percentuali premi (virgola separata)',
                        prefixIcon: Icon(Icons.percent_outlined),
                        hintText: 'Es: 50,30,20',
                        helperText: 'Un valore per ogni posizione premiata. La somma deve essere 100.',
                      ),
                      onChanged: (_) => setState(() {}),
                      validator: (v) {
                        try {
                          final sum = v!
                              .split(',')
                              .map((e) => double.parse(e.trim()))
                              .reduce((a, b) => a + b);
                          return (sum - 100).abs() < 0.01
                              ? null
                              : 'La somma deve essere 100 (attuale: ${sum.toStringAsFixed(1)})';
                        } catch (_) {
                          return 'Formato non valido. Usa numeri separati da virgola.';
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    if (_parsedPrizes.isNotEmpty) ...[
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _parsedPrizes.asMap().entries.map((e) {
                          final pos = e.key + 1;
                          final pct = e.value;
                          final medal = pos == 1 ? '🥇' : pos == 2 ? '🥈' : pos == 3 ? '🥉' : '$pos°';
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF7D6),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: const Color(0xFFFFD66B)),
                            ),
                            child: Text(
                              '$medal ${pct.toStringAsFixed(0)}%',
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 8),
                      _PrizeSumIndicator(sum: _prizeSum),
                    ],
                  ]),

                  const SizedBox(height: 24),

                  FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Icon(_isEdit ? Icons.save_outlined : Icons.add_circle_outline),
                    label: Text(_saving
                        ? (_isEdit ? 'Salvataggio...' : 'Creazione in corso...')
                        : (_isEdit ? 'Salva modifiche' : 'Crea torneo')),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Section header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  final IconData icon;
  const _SectionHeader({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 0, 8),
      child: Row(children: [
        Icon(icon, size: 18, color: const Color(0xFF5D2EA6)),
        const SizedBox(width: 8),
        Text(label,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF2D145C),
                )),
      ]),
    );
  }
}

// ─── Form card ────────────────────────────────────────────────────────────────

class _FormCard extends StatelessWidget {
  final List<Widget> children;
  const _FormCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white.withValues(alpha: .95),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
      ),
    );
  }
}

// ─── Prize sum indicator ──────────────────────────────────────────────────────

class _PrizeSumIndicator extends StatelessWidget {
  final double sum;
  const _PrizeSumIndicator({required this.sum});

  @override
  Widget build(BuildContext context) {
    final ok = (sum - 100).abs() < 0.01;
    final color = ok ? Colors.green.shade700 : Colors.orange.shade700;
    final bg = ok ? Colors.green.shade50 : Colors.orange.shade50;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(ok ? Icons.check_circle_outline : Icons.warning_amber_outlined, size: 16, color: color),
        const SizedBox(width: 6),
        Text(
          ok ? 'Totale: 100% ✓' : 'Totale: ${sum.toStringAsFixed(1)}% (deve essere 100)',
          style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ]),
    );
  }
}
