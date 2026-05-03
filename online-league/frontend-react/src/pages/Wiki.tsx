import { useState } from 'react';
import { Container, Accordion, Badge, Table, Button } from 'react-bootstrap';
import Layout from '../Layout';

type Lang = 'IT' | 'EN' | 'ES' | 'FR';

const T = {
  IT: {
    title: 'Guida alla Lega', subtitle: 'Tutto quello che devi sapere per partecipare',
    s1: 'Come iscriversi', s2: 'Formato torneo', s3: 'Inserimento risultati',
    s4: 'Disponibilità', s5: 'Classifica', s6: 'Assistenza',
    reg: ['Accedi tramite Discord cliccando su "Login Discord"',
      'Cerca il torneo nella home e clicca "Dettaglio"',
      'Compila il form con nome, cognome e account Discord',
      'Se il torneo è a pagamento, usa il link PayPal e aspetta la conferma dell\'admin'],
    fmt: ['Fase iscrizioni: tutti si iscrivono e l\'admin attiva il torneo',
      'Fase in corso: il sistema genera automaticamente tutte le partite (round-robin)',
      'Ogni giocatore sfida tutti gli altri una volta',
      'Fase conclusa: classifica finale congelata'],
    res: ['Vai al dettaglio torneo → tab Calendario',
      'Seleziona il tuo nome e trova la partita da inserire',
      'Proponi il risultato scegliendo il punteggio esatto',
      'Il tuo avversario riceve un DM Discord e può confermare o contestare'],
    scores: ['2-0', '2-1', '1-0', '1-1', '0-1', '1-2', '0-2'],
    av: ['Vai al torneo → "Le mie disponibilità"',
      'Seleziona i giorni e le fasce orarie in cui sei libero',
      'Quando tu e un avversario avete fasce in comune, ricevete un DM Discord',
      'Usate quelle fasce per accordarvi e giocare'],
    pts: 'Punti', v: 'Vittoria', p: 'Pareggio', s: 'Sconfitta',
    tie: ['Punti totali (decrescente)', 'Vittorie (decrescente)',
      'Differenza game (GV − GS)', 'Sconfitte (crescente)'],
    tieTitle: 'Criteri di spareggio (in ordine)',
    cols: { gv: 'GV = Game vinti', gs: 'GS = Game subiti', diff: 'GV−GS = Differenza game' },
    help: 'Per qualsiasi problema contatta un admin sul server Discord della lega.',
  },
  EN: {
    title: 'League Guide', subtitle: 'Everything you need to know to participate',
    s1: 'How to register', s2: 'Tournament format', s3: 'Submitting results',
    s4: 'Availability', s5: 'Standings', s6: 'Help',
    reg: ['Log in via Discord by clicking "Login Discord"',
      'Find the tournament on the home page and click "Details"',
      'Fill in the form with your name and Discord account',
      'If there is an entry fee, use the PayPal link and wait for admin confirmation'],
    fmt: ['Registration phase: everyone signs up and admin starts the tournament',
      'Ongoing phase: the system automatically generates all matches (round-robin)',
      'Each player faces all others once',
      'Completed phase: final standings are frozen'],
    res: ['Go to tournament detail → Calendar tab',
      'Select your name and find the match to report',
      'Propose the result by choosing the exact score',
      'Your opponent receives a Discord DM and can confirm or dispute'],
    scores: ['2-0', '2-1', '1-0', '1-1', '0-1', '1-2', '0-2'],
    av: ['Go to the tournament → "My availability"',
      'Select the days and time slots when you are free',
      'When you and an opponent share time slots, you both receive a Discord DM',
      'Use those slots to arrange and play your match'],
    pts: 'Points', v: 'Win', p: 'Draw', s: 'Loss',
    tie: ['Total points (descending)', 'Wins (descending)',
      'Game difference (GW − GL)', 'Losses (ascending)'],
    tieTitle: 'Tiebreaker criteria (in order)',
    cols: { gv: 'GW = Games Won', gs: 'GL = Games Lost', diff: 'GW−GL = Game difference' },
    help: 'For any issue, contact an admin on the league\'s Discord server.',
  },
  ES: {
    title: 'Guía de la Liga', subtitle: 'Todo lo que necesitas saber para participar',
    s1: 'Cómo inscribirse', s2: 'Formato del torneo', s3: 'Ingresar resultados',
    s4: 'Disponibilidad', s5: 'Clasificación', s6: 'Ayuda',
    reg: ['Inicia sesión con Discord haciendo clic en "Login Discord"',
      'Encuentra el torneo en la página principal y haz clic en "Detalle"',
      'Completa el formulario con tu nombre y cuenta de Discord',
      'Si hay cuota de inscripción, usa el enlace de PayPal y espera confirmación del admin'],
    fmt: ['Fase de inscripción: todos se inscriben y el admin inicia el torneo',
      'Fase en curso: el sistema genera automáticamente todos los partidos (round-robin)',
      'Cada jugador se enfrenta a todos los demás una vez',
      'Fase concluida: la clasificación final queda congelada'],
    res: ['Ve al detalle del torneo → pestaña Calendario',
      'Selecciona tu nombre y encuentra el partido a reportar',
      'Propone el resultado eligiendo la puntuación exacta',
      'Tu rival recibe un DM de Discord y puede confirmar o disputar'],
    scores: ['2-0', '2-1', '1-0', '1-1', '0-1', '1-2', '0-2'],
    av: ['Ve al torneo → "Mi disponibilidad"',
      'Selecciona los días y franjas horarias en que estás libre',
      'Cuando tú y un rival tenéis franjas comunes, recibís un DM de Discord',
      'Usad esas franjas para acordar y jugar'],
    pts: 'Puntos', v: 'Victoria', p: 'Empate', s: 'Derrota',
    tie: ['Puntos totales (descendente)', 'Victorias (descendente)',
      'Diferencia de juegos (JG − JP)', 'Derrotas (ascendente)'],
    tieTitle: 'Criterios de desempate (en orden)',
    cols: { gv: 'JG = Juegos ganados', gs: 'JP = Juegos perdidos', diff: 'JG−JP = Diferencia' },
    help: 'Para cualquier problema, contacta a un admin en el servidor de Discord de la liga.',
  },
  FR: {
    title: 'Guide de la Ligue', subtitle: 'Tout ce que vous devez savoir pour participer',
    s1: "S'inscrire", s2: 'Format du tournoi', s3: 'Saisir les résultats',
    s4: 'Disponibilités', s5: 'Classement', s6: 'Aide',
    reg: ['Connectez-vous via Discord en cliquant sur "Login Discord"',
      'Trouvez le tournoi sur la page d\'accueil et cliquez sur "Détail"',
      'Remplissez le formulaire avec votre nom et votre compte Discord',
      'Si le tournoi est payant, utilisez le lien PayPal et attendez la confirmation'],
    fmt: ['Phase d\'inscription : tout le monde s\'inscrit et l\'admin lance le tournoi',
      'Phase en cours : le système génère automatiquement tous les matchs (round-robin)',
      'Chaque joueur affronte tous les autres une fois',
      'Phase terminée : le classement final est figé'],
    res: ['Allez dans le détail du tournoi → onglet Calendrier',
      'Sélectionnez votre nom et trouvez le match à saisir',
      'Proposez le résultat en choisissant le score exact',
      'Votre adversaire reçoit un DM Discord et peut confirmer ou contester'],
    scores: ['2-0', '2-1', '1-0', '1-1', '0-1', '1-2', '0-2'],
    av: ['Allez au tournoi → "Mes disponibilités"',
      'Sélectionnez les jours et les créneaux horaires où vous êtes disponible',
      'Quand vous et un adversaire avez des créneaux en commun, vous recevez un DM Discord',
      'Utilisez ces créneaux pour vous mettre d\'accord et jouer'],
    pts: 'Points', v: 'Victoire', p: 'Nul', s: 'Défaite',
    tie: ['Points totaux (décroissant)', 'Victoires (décroissant)',
      'Différence de jeux (JG − JP)', 'Défaites (croissant)'],
    tieTitle: 'Critères de départage (dans l\'ordre)',
    cols: { gv: 'JG = Jeux gagnés', gs: 'JP = Jeux perdus', diff: 'JG−JP = Différence' },
    help: 'Pour tout problème, contactez un admin sur le serveur Discord de la ligue.',
  },
};

export default function Wiki() {
  const [lang, setLang] = useState<Lang>('IT');
  const t = T[lang];
  const flags: { code: Lang; flag: string }[] = [
    { code: 'IT', flag: '🇮🇹' }, { code: 'EN', flag: '🇬🇧' },
    { code: 'ES', flag: '🇪🇸' }, { code: 'FR', flag: '🇫🇷' },
  ];

  return (
    <Layout>
      <div className="hero-banner-sm mb-4">
        <Container fluid="xl" className="d-flex justify-content-between align-items-center flex-wrap gap-2">
          <div>
            <h2>📖 {t.title}</h2>
            <p>{t.subtitle}</p>
          </div>
          <div className="d-flex gap-2">
            {flags.map(f => (
              <Button
                key={f.code}
                size="sm"
                variant={lang === f.code ? 'warning' : 'outline-light'}
                className="fw-bold"
                onClick={() => setLang(f.code)}
              >
                {f.flag} {f.code}
              </Button>
            ))}
          </div>
        </Container>
      </div>

      <Container fluid="xl" style={{ maxWidth: 820 }}>
        <Accordion defaultActiveKey="0" flush className="mb-4">
          <Accordion.Item eventKey="0">
            <Accordion.Header>📋 {t.s1}</Accordion.Header>
            <Accordion.Body>
              <ol className="mb-0">{t.reg.map((s, i) => <li key={i} className="mb-1">{s}</li>)}</ol>
            </Accordion.Body>
          </Accordion.Item>

          <Accordion.Item eventKey="1">
            <Accordion.Header>🏆 {t.s2}</Accordion.Header>
            <Accordion.Body>
              <ol className="mb-0">{t.fmt.map((s, i) => <li key={i} className="mb-1">{s}</li>)}</ol>
            </Accordion.Body>
          </Accordion.Item>

          <Accordion.Item eventKey="2">
            <Accordion.Header>🎯 {t.s3}</Accordion.Header>
            <Accordion.Body>
              <ol className="mb-2">{t.res.map((s, i) => <li key={i} className="mb-1">{s}</li>)}</ol>
              <p className="fw-bold mb-1">Risultati validi:</p>
              <div className="d-flex flex-wrap gap-2">
                {t.scores.map(s => (
                  <Badge key={s} bg="primary" className="fs-6 px-3 py-2">{s}</Badge>
                ))}
              </div>
            </Accordion.Body>
          </Accordion.Item>

          <Accordion.Item eventKey="3">
            <Accordion.Header>📅 {t.s4}</Accordion.Header>
            <Accordion.Body>
              <ol className="mb-0">{t.av.map((s, i) => <li key={i} className="mb-1">{s}</li>)}</ol>
            </Accordion.Body>
          </Accordion.Item>

          <Accordion.Item eventKey="4">
            <Accordion.Header>📊 {t.s5}</Accordion.Header>
            <Accordion.Body>
              <Table size="sm" bordered className="mb-3">
                <thead><tr><th>Esito</th><th>{t.pts}</th></tr></thead>
                <tbody>
                  <tr><td>✅ {t.v}</td><td><strong>3</strong></td></tr>
                  <tr><td>🤝 {t.p}</td><td><strong>1</strong></td></tr>
                  <tr><td>❌ {t.s}</td><td><strong>0</strong></td></tr>
                </tbody>
              </Table>
              <p className="fw-bold mb-1">{t.tieTitle}:</p>
              <ol className="mb-2">{t.tie.map((s, i) => <li key={i}>{s}</li>)}</ol>
              <div className="text-muted small">
                <div>{t.cols.gv}</div>
                <div>{t.cols.gs}</div>
                <div>{t.cols.diff}</div>
              </div>
            </Accordion.Body>
          </Accordion.Item>

          <Accordion.Item eventKey="5">
            <Accordion.Header>💬 {t.s6}</Accordion.Header>
            <Accordion.Body>{t.help}</Accordion.Body>
          </Accordion.Item>
        </Accordion>
      </Container>
    </Layout>
  );
}
