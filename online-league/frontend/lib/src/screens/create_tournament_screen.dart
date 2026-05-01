import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/api_client.dart';

class CreateTournamentScreen extends StatefulWidget {
  final ApiClient api;
  const CreateTournamentScreen({super.key, required this.api});
  @override State<CreateTournamentScreen> createState() => _CreateTournamentScreenState();
}

class _CreateTournamentScreenState extends State<CreateTournamentScreen> {
  final formKey = GlobalKey<FormState>();
  final title = TextEditingController();
  final cap = TextEditingController(text: '32');
  final fee = TextEditingController(text: '10');
  final paypal = TextEditingController();
  final start = TextEditingController(text: DateTime.now().add(const Duration(days: 7)).toIso8601String());
  final end = TextEditingController(text: DateTime.now().add(const Duration(days: 7, hours: 4)).toIso8601String());
  final rules = TextEditingController();
  final prizes = TextEditingController(text: '50,30,20');
  bool saving = false;

  Future<void> save() async {
    if (!formKey.currentState!.validate()) return;
    setState(() => saving = true);
    final perc = prizes.text.split(',').map((e) => double.parse(e.trim())).toList();
    final payload = {
      'title': title.text.trim(),
      'cap': int.parse(cap.text),
      'entry_fee_eur': double.parse(fee.text.replaceAll(',', '.')),
      'paypal_link': paypal.text.trim(),
      'start_date': DateTime.parse(start.text.trim()).toIso8601String(),
      'end_date': DateTime.parse(end.text.trim()).toIso8601String(),
      'rules_description': rules.text.trim(),
      'prize_players_count': perc.length,
      'prize_distribution': [for (var i = 0; i < perc.length; i++) {'position': i + 1, 'percentage': perc[i]}],
    };
    try {
      await widget.api.createTournament(payload);
      if (mounted) context.go('/');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Errore: $e')));
    } finally { if (mounted) setState(() => saving = false); }
  }

  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Crea torneo')),
    body: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 900), child: Form(key: formKey, child: ListView(padding: const EdgeInsets.all(24), children: [
      TextFormField(controller: title, decoration: const InputDecoration(labelText: 'Nome torneo'), validator: (v) => v == null || v.length < 3 ? 'Minimo 3 caratteri' : null),
      TextFormField(controller: cap, decoration: const InputDecoration(labelText: 'CAP utenti'), keyboardType: TextInputType.number),
      TextFormField(controller: fee, decoration: const InputDecoration(labelText: 'Costo iscrizione €'), keyboardType: TextInputType.number),
      TextFormField(controller: paypal, decoration: const InputDecoration(labelText: 'Link PayPal'), validator: (v) => v == null || !v.startsWith('http') ? 'Inserire URL valido' : null),
      TextFormField(controller: start, decoration: const InputDecoration(labelText: 'Data inizio ISO 8601')),
      TextFormField(controller: end, decoration: const InputDecoration(labelText: 'Data fine ISO 8601')),
      TextFormField(controller: rules, decoration: const InputDecoration(labelText: 'Regole / descrizione'), maxLines: 6, validator: (v) => v == null || v.isEmpty ? 'Campo obbligatorio' : null),
      TextFormField(controller: prizes, decoration: const InputDecoration(labelText: 'Percentuali premi, separate da virgola. Es: 50,30,20'), validator: (v) {
        try { final sum = v!.split(',').map((e) => double.parse(e.trim())).reduce((a,b)=>a+b); return sum == 100 ? null : 'La somma deve essere 100'; } catch (_) { return 'Formato non valido'; }
      }),
      const SizedBox(height: 24), FilledButton.icon(onPressed: saving ? null : save, icon: const Icon(Icons.save), label: Text(saving ? 'Salvataggio...' : 'Salva torneo')),
    ])))));
}
