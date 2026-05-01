import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class WikiScreen extends StatelessWidget {
  const WikiScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.go('/'),
          icon: const Icon(Icons.home_outlined),
          tooltip: 'Home',
        ),
        title: const Text('Guida alla Lorcana League'),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF3EEFF), Color(0xFFFFF8E7)],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 48),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 820),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const _WikiHero(),
                  const SizedBox(height: 28),
                  const _SectionCard(
                    icon: Icons.login_outlined,
                    iconColor: Color(0xFF5D2EA6),
                    title: 'Come iscriversi a un torneo',
                    child: _HowToRegisterSection(),
                  ),
                  const SizedBox(height: 16),
                  const _SectionCard(
                    icon: Icons.emoji_events_outlined,
                    iconColor: Color(0xFFC8960A),
                    title: 'Come funziona il torneo',
                    child: _TournamentFormatSection(),
                  ),
                  const SizedBox(height: 16),
                  const _SectionCard(
                    icon: Icons.scoreboard_outlined,
                    iconColor: Color(0xFF2E7D32),
                    title: 'Inserimento e conferma risultati',
                    child: _ResultsSection(),
                  ),
                  const SizedBox(height: 16),
                  const _SectionCard(
                    icon: Icons.event_available_outlined,
                    iconColor: Color(0xFF1565C0),
                    title: 'Disponibilità per le partite',
                    child: _AvailabilitySection(),
                  ),
                  const SizedBox(height: 16),
                  const _SectionCard(
                    icon: Icons.leaderboard_outlined,
                    iconColor: Color(0xFF6A1B9A),
                    title: 'Classifica e punteggio',
                    child: _StandingsSection(),
                  ),
                  const SizedBox(height: 16),
                  const _SectionCard(
                    icon: Icons.help_outline,
                    iconColor: Color(0xFF00695C),
                    title: 'Bisogno di aiuto?',
                    child: _HelpSection(),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Hero ─────────────────────────────────────────────────────────────────────

class _WikiHero extends StatelessWidget {
  const _WikiHero();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: const Color(0xFF2D145C),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFD66B),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.menu_book_outlined, color: Color(0xFF2D145C), size: 32),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                'Guida completa',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tutto quello che ti serve sapere per partecipare ai tornei online di Lorcana Campania: come iscriversi, come funzionano le partite e come consultare la classifica.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withValues(alpha: .82),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ─── Section card wrapper ─────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final Widget child;
  const _SectionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white.withValues(alpha: .95),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF2D145C),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 18),
          const Divider(height: 1),
          const SizedBox(height: 16),
          child,
        ]),
      ),
    );
  }
}

// ─── Step widget ──────────────────────────────────────────────────────────────

class _Step extends StatelessWidget {
  final int number;
  final String title;
  final String description;
  const _Step({
    required this.number,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: Color(0xFF5D2EA6),
            shape: BoxShape.circle,
          ),
          child: Text(
            '$number',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Color(0xFF2D145C))),
            const SizedBox(height: 4),
            Text(description,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade700, height: 1.5)),
          ]),
        ),
      ]),
    );
  }
}

// ─── Info pill ────────────────────────────────────────────────────────────────

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  const _InfoPill({required this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: .3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Flexible(
          child: Text(text,
              style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w600)),
        ),
      ]),
    );
  }
}

// ─── Section: Come iscriversi ─────────────────────────────────────────────────

class _HowToRegisterSection extends StatelessWidget {
  const _HowToRegisterSection();

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const _Step(
        number: 1,
        title: 'Accedi con Discord',
        description:
            'Clicca il pulsante "Login Discord" in alto a destra. Verrai reindirizzato alla pagina di autorizzazione di Discord. Dopo aver accettato, tornerai automaticamente al sito.',
      ),
      const _Step(
        number: 2,
        title: 'Scegli un torneo aperto',
        description:
            'Nella home trovi l\'elenco dei tornei disponibili. Quelli con lo stato "Aperto" accettano ancora iscrizioni. Clicca su un torneo per vederne i dettagli: date, quota di iscrizione, regole e montepremi.',
      ),
      const _Step(
        number: 3,
        title: 'Compila il modulo di iscrizione',
        description:
            'Nella pagina del torneo trovi il pannello "Iscrizione al torneo". Verifica o modifica il tuo account Discord, inserisci nome e cognome, poi clicca "Conferma iscrizione".',
      ),
      const _Step(
        number: 4,
        title: 'Paga la quota di iscrizione (se prevista)',
        description:
            'Se il torneo ha una quota di partecipazione, clicca "Paga su PayPal" e completa il pagamento. Una volta verificato dall\'admin, il tuo stato diventerà "Pagato" e la tua iscrizione sarà confermata definitivamente.',
      ),
      const SizedBox(height: 4),
      Wrap(spacing: 10, runSpacing: 10, children: const [
        _InfoPill(
          icon: Icons.discord,
          text: 'Account Discord obbligatorio',
          color: Color(0xFF5865F2),
        ),
        _InfoPill(
          icon: Icons.lock_open_outlined,
          text: 'Tornei gratuiti: subito confermato',
          color: Color(0xFF2E7D32),
        ),
        _InfoPill(
          icon: Icons.payments_outlined,
          text: 'Tornei a pagamento: attendi conferma admin',
          color: Color(0xFFC8960A),
        ),
      ]),
    ]);
  }
}

// ─── Section: Come funziona ───────────────────────────────────────────────────

class _TournamentFormatSection extends StatelessWidget {
  const _TournamentFormatSection();

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(
        'Formato Round Robin (tutti contro tutti)',
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: const Color(0xFF2D145C),
        ),
      ),
      const SizedBox(height: 10),
      Text(
        'Ogni giocatore iscritto affronta tutti gli altri esattamente una volta. Il numero totale di partite è n×(n−1)/2, dove n è il numero di iscritti.',
        style: TextStyle(fontSize: 14, color: Colors.grey.shade700, height: 1.55),
      ),
      const SizedBox(height: 16),
      Text(
        'Fasi del torneo',
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: const Color(0xFF2D145C),
        ),
      ),
      const SizedBox(height: 10),
      _phaseRow(context, Icons.app_registration_outlined, const Color(0xFF1565C0), 'Iscrizioni',
          'Gli utenti si iscrivono e (se richiesto) pagano la quota. Il torneo parte automaticamente alla data di inizio oppure quando tutti i giocatori risultano pagati.'),
      const SizedBox(height: 10),
      _phaseRow(context, Icons.play_circle_outline, const Color(0xFF2E7D32), 'In corso',
          'Il calendario viene generato automaticamente con tutte le partite. Ogni giocatore può vedere le proprie sfide nel tab "Calendario" e inserire i risultati.'),
      const SizedBox(height: 10),
      _phaseRow(context, Icons.flag_outlined, const Color(0xFF6A1B9A), 'Concluso',
          'Tutte le partite sono state giocate. La classifica finale è consultabile nel tab "Classifica".'),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF7D6),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFFFD66B)),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.info_outline, color: Color(0xFFC8960A), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Le partite si svolgono online, concordando orario e modalità direttamente con l\'avversario. Usa la funzione Disponibilità per trovare fasce orarie in comune.',
              style: TextStyle(fontSize: 13, color: Colors.brown.shade700, height: 1.5),
            ),
          ),
        ]),
      ),
    ]);
  }

  Widget _phaseRow(BuildContext context, IconData icon, Color color, String label, String desc) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF2D145C))),
          const SizedBox(height: 3),
          Text(desc, style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.5)),
        ]),
      ),
    ]);
  }
}

// ─── Section: Risultati ───────────────────────────────────────────────────────

class _ResultsSection extends StatelessWidget {
  const _ResultsSection();

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(
        'Come si riporta un risultato',
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: const Color(0xFF2D145C),
        ),
      ),
      const SizedBox(height: 12),
      const _Step(
        number: 1,
        title: 'Trova la tua partita',
        description:
            'Vai nella pagina del torneo → tab "Calendario" → seleziona il tuo nome. Vedrai tutte le tue partite con lo stato attuale.',
      ),
      const _Step(
        number: 2,
        title: 'Inserisci il risultato',
        description:
            'Clicca "Inserisci risultato" e scegli il numero di giochi vinti da ciascun giocatore (es. 2–1 significa che hai vinto 2 giochi e il tuo avversario 1). Il risultato viene marcato come "In attesa".',
      ),
      const _Step(
        number: 3,
        title: 'L\'avversario conferma',
        description:
            'Il tuo avversario vedrà il risultato proposto e potrà confermarlo cliccando "Conferma risultato". Solo dopo la conferma di entrambi il risultato diventa definitivo.',
      ),
      const SizedBox(height: 4),
      Text(
        'Risultati validi',
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: const Color(0xFF2D145C),
        ),
      ),
      const SizedBox(height: 10),
      Wrap(spacing: 8, runSpacing: 8, children: [
        _resultChip('2 – 0', 'Vittoria netta', const Color(0xFF2E7D32)),
        _resultChip('2 – 1', 'Vittoria al tie-break', const Color(0xFF2E7D32)),
        _resultChip('1 – 0', 'Vittoria corta', const Color(0xFF2E7D32)),
        _resultChip('1 – 1', 'Pareggio', const Color(0xFF1565C0)),
        _resultChip('0 – 1', 'Sconfitta corta', Colors.red.shade700),
        _resultChip('1 – 2', 'Sconfitta al tie-break', Colors.red.shade700),
        _resultChip('0 – 2', 'Sconfitta netta', Colors.red.shade700),
      ]),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.warning_amber_outlined, color: Colors.red.shade700, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'In caso di disaccordo sul risultato, contatta un amministratore tramite il server Discord. Gli admin possono modificare o annullare qualsiasi risultato.',
              style: TextStyle(fontSize: 13, color: Colors.red.shade800, height: 1.5),
            ),
          ),
        ]),
      ),
    ]);
  }

  Widget _resultChip(String score, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: .3)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(score,
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: color)),
        const SizedBox(height: 2),
        Text(label,
            style: TextStyle(fontSize: 11, color: color.withValues(alpha: .8))),
      ]),
    );
  }
}

// ─── Section: Disponibilità ───────────────────────────────────────────────────

class _AvailabilitySection extends StatelessWidget {
  const _AvailabilitySection();

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(
        'Coordinarsi con gli avversari',
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: const Color(0xFF2D145C),
        ),
      ),
      const SizedBox(height: 10),
      Text(
        'Le partite del torneo vanno giocate online entro la data di fine torneo, accordandosi direttamente con l\'avversario. La funzione Disponibilità ti aiuta a trovare orari in comune in modo automatico.',
        style: TextStyle(fontSize: 14, color: Colors.grey.shade700, height: 1.55),
      ),
      const SizedBox(height: 16),
      const _Step(
        number: 1,
        title: 'Apri la pagina Disponibilità',
        description:
            'Nella pagina del torneo, clicca il pulsante "Disponibilità". Potrai accedervi solo se sei iscritto al torneo.',
      ),
      const _Step(
        number: 2,
        title: 'Seleziona le tue fasce orarie',
        description:
            'Scegli la data e le fasce di due ore in cui sei disponibile a giocare (copertura completa 00:00–24:00). Puoi selezionare più fasce per lo stesso giorno.',
      ),
      const _Step(
        number: 3,
        title: 'Salva e ricevi notifiche',
        description:
            'Appena salvi le disponibilità, il sistema confronta automaticamente le tue fasce con quelle di ogni tuo avversario. Per ogni coppia con orari in comune, entrambi i giocatori ricevono un messaggio privato su Discord con i dettagli e un link diretto al torneo.',
      ),
      const SizedBox(height: 4),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFE8EAF6),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF5865F2).withValues(alpha: .4)),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.discord, color: Color(0xFF5865F2), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Le notifiche vengono inviate come messaggi privati Discord dal bot del torneo. Assicurati di avere i DM abilitati dal server o di non aver bloccato i messaggi privati.',
              style: const TextStyle(fontSize: 13, color: Color(0xFF283593), height: 1.5),
            ),
          ),
        ]),
      ),
    ]);
  }
}

// ─── Section: Classifica ─────────────────────────────────────────────────────

class _StandingsSection extends StatelessWidget {
  const _StandingsSection();

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(
        'Sistema di punteggio',
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: const Color(0xFF2D145C),
        ),
      ),
      const SizedBox(height: 12),
      LayoutBuilder(builder: (context, c) {
        final wide = c.maxWidth > 400;
        final items = [
          _PointsRow(icon: Icons.emoji_events, color: const Color(0xFFF9A825), label: 'Vittoria', points: '3 punti'),
          _PointsRow(icon: Icons.handshake_outlined, color: const Color(0xFF1565C0), label: 'Pareggio', points: '1 punto'),
          _PointsRow(icon: Icons.close, color: Colors.red.shade700, label: 'Sconfitta', points: '0 punti'),
        ];
        return wide
            ? Row(children: items.map((w) => Expanded(child: w)).toList())
            : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: items);
      }),
      const SizedBox(height: 16),
      Text(
        'Criteri di spareggio',
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: const Color(0xFF2D145C),
        ),
      ),
      const SizedBox(height: 10),
      _tiebreaker(context, '1°', 'Punti totali', 'Somma dei punti accumulati in tutte le partite'),
      const SizedBox(height: 8),
      _tiebreaker(context, '2°', 'Vittorie', 'Numero di partite vinte'),
      const SizedBox(height: 8),
      _tiebreaker(context, '3°', 'Differenza giochi', 'Giochi vinti meno giochi persi'),
      const SizedBox(height: 8),
      _tiebreaker(context, '4°', 'Sconfitte', 'Meno sconfitte è meglio'),
      const SizedBox(height: 16),
      Text(
        'Legenda colonne',
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: const Color(0xFF2D145C),
        ),
      ),
      const SizedBox(height: 10),
      Wrap(spacing: 8, runSpacing: 8, children: const [
        _LegendChip('G', 'Partite giocate'),
        _LegendChip('V', 'Vittorie'),
        _LegendChip('P', 'Pareggi'),
        _LegendChip('S', 'Sconfitte'),
        _LegendChip('GV', 'Giochi vinti'),
        _LegendChip('GS', 'Giochi subiti'),
        _LegendChip('Pts', 'Punti totali'),
      ]),
    ]);
  }

  Widget _tiebreaker(BuildContext context, String pos, String label, String desc) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: 28,
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFF1E7FF),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(pos,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF5D2EA6))),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF2D145C))),
          Text(desc, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
        ]),
      ),
    ]);
  }
}

class _PointsRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String points;
  const _PointsRow({required this.icon, required this.color, required this.label, required this.points});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(4),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: .25)),
      ),
      child: Column(children: [
        Icon(icon, color: color, size: 26),
        const SizedBox(height: 6),
        Text(label, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: color)),
        const SizedBox(height: 2),
        Text(points,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color)),
      ]),
    );
  }
}

class _LegendChip extends StatelessWidget {
  final String abbr;
  final String full;
  const _LegendChip(this.abbr, this.full);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1E7FF),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(abbr,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF5D2EA6))),
        const SizedBox(width: 6),
        Text(full, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
      ]),
    );
  }
}

// ─── Section: Aiuto ───────────────────────────────────────────────────────────

class _HelpSection extends StatelessWidget {
  const _HelpSection();

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(
        'Hai domande o problemi? Contatta gli amministratori tramite il server Discord di Lorcana Campania. Puoi segnalare:',
        style: TextStyle(fontSize: 14, color: Colors.grey.shade700, height: 1.55),
      ),
      const SizedBox(height: 12),
      _bullet('Risultati errati o contestati'),
      _bullet('Problemi con l\'iscrizione o il pagamento'),
      _bullet('Avversari non raggiungibili entro i tempi del torneo'),
      _bullet('Qualsiasi altro problema tecnico con il sito'),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFE8EAF6),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF5865F2).withValues(alpha: .4)),
        ),
        child: Row(children: [
          const Icon(Icons.discord, color: Color(0xFF5865F2), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Il pulsante "Visualizza su Discord" nella pagina del torneo ti porta direttamente al server. Se non sei ancora nel server, trovi il link di invito nella stessa pagina.',
              style: const TextStyle(fontSize: 13, color: Color(0xFF283593), height: 1.5),
            ),
          ),
        ]),
      ),
    ]);
  }

  Widget _bullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Container(
            width: 6, height: 6,
            decoration: const BoxDecoration(
              color: Color(0xFF5D2EA6),
              shape: BoxShape.circle,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text, style: TextStyle(fontSize: 14, color: Colors.grey.shade700)),
        ),
      ]),
    );
  }
}
