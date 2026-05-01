import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// ─── Language enum & flag selector ───────────────────────────────────────────

enum _Lang { it, en, es, fr }

const _kLangFlag = {
  _Lang.it: '🇮🇹',
  _Lang.en: '🇬🇧',
  _Lang.es: '🇪🇸',
  _Lang.fr: '🇫🇷',
};

// ─── Translation strings ──────────────────────────────────────────────────────

class _S {
  // App / hero
  final String appBarTitle;
  final String heroTitle;
  final String heroSubtitle;
  // Section titles
  final String secReg;
  final String secFormat;
  final String secResults;
  final String secAvail;
  final String secStandings;
  final String secHelp;
  // ── Registration ──
  final String regStep1T, regStep1D;
  final String regStep2T, regStep2D;
  final String regStep3T, regStep3D;
  final String regStep4T, regStep4D;
  final String regPill1, regPill2, regPill3;
  // ── Format ──
  final String fmtSubtitle, fmtBody;
  final String fmtPhasesTitle;
  final String fmtP1L, fmtP1D;
  final String fmtP2L, fmtP2D;
  final String fmtP3L, fmtP3D;
  final String fmtNote;
  // ── Results ──
  final String resSubtitle;
  final String resStep1T, resStep1D;
  final String resStep2T, resStep2D;
  final String resStep3T, resStep3D;
  final String resValidTitle;
  final String resC1, resC2, resC3, resC4, resC5, resC6, resC7;
  final String resWarning;
  // ── Availability ──
  final String availSubtitle, availBody;
  final String availStep1T, availStep1D;
  final String availStep2T, availStep2D;
  final String availStep3T, availStep3D;
  final String availDiscord;
  // ── Standings ──
  final String stSubtitle;
  final String stWinL, stWinPts;
  final String stDrawL, stDrawPts;
  final String stLossL, stLossPts;
  final String stTbTitle;
  final String stTb1L, stTb1D;
  final String stTb2L, stTb2D;
  final String stTb3L, stTb3D;
  final String stTb4L, stTb4D;
  final String stLegTitle;
  final String stLegG, stLegV, stLegP, stLegS, stLegGV, stLegGS, stLegPts;
  // ── Help ──
  final String helpBody;
  final String helpB1, helpB2, helpB3, helpB4;
  final String helpDiscord;

  const _S({
    required this.appBarTitle, required this.heroTitle, required this.heroSubtitle,
    required this.secReg, required this.secFormat, required this.secResults,
    required this.secAvail, required this.secStandings, required this.secHelp,
    required this.regStep1T, required this.regStep1D,
    required this.regStep2T, required this.regStep2D,
    required this.regStep3T, required this.regStep3D,
    required this.regStep4T, required this.regStep4D,
    required this.regPill1, required this.regPill2, required this.regPill3,
    required this.fmtSubtitle, required this.fmtBody,
    required this.fmtPhasesTitle,
    required this.fmtP1L, required this.fmtP1D,
    required this.fmtP2L, required this.fmtP2D,
    required this.fmtP3L, required this.fmtP3D,
    required this.fmtNote,
    required this.resSubtitle,
    required this.resStep1T, required this.resStep1D,
    required this.resStep2T, required this.resStep2D,
    required this.resStep3T, required this.resStep3D,
    required this.resValidTitle,
    required this.resC1, required this.resC2, required this.resC3, required this.resC4,
    required this.resC5, required this.resC6, required this.resC7,
    required this.resWarning,
    required this.availSubtitle, required this.availBody,
    required this.availStep1T, required this.availStep1D,
    required this.availStep2T, required this.availStep2D,
    required this.availStep3T, required this.availStep3D,
    required this.availDiscord,
    required this.stSubtitle,
    required this.stWinL, required this.stWinPts,
    required this.stDrawL, required this.stDrawPts,
    required this.stLossL, required this.stLossPts,
    required this.stTbTitle,
    required this.stTb1L, required this.stTb1D,
    required this.stTb2L, required this.stTb2D,
    required this.stTb3L, required this.stTb3D,
    required this.stTb4L, required this.stTb4D,
    required this.stLegTitle,
    required this.stLegG, required this.stLegV, required this.stLegP,
    required this.stLegS, required this.stLegGV, required this.stLegGS, required this.stLegPts,
    required this.helpBody,
    required this.helpB1, required this.helpB2, required this.helpB3, required this.helpB4,
    required this.helpDiscord,
  });

  // ── Italian ────────────────────────────────────────────────────────────────
  static const it = _S(
    appBarTitle: 'Guida alla Lorcana League',
    heroTitle: 'Guida completa',
    heroSubtitle: 'Tutto quello che ti serve sapere per partecipare ai tornei online di Lorcana Campania: come iscriversi, come funzionano le partite e come consultare la classifica.',
    secReg: 'Come iscriversi a un torneo',
    secFormat: 'Come funziona il torneo',
    secResults: 'Inserimento e conferma risultati',
    secAvail: 'Disponibilità per le partite',
    secStandings: 'Classifica e punteggio',
    secHelp: 'Bisogno di aiuto?',
    regStep1T: 'Accedi con Discord',
    regStep1D: 'Clicca il pulsante "Login Discord" in alto a destra. Verrai reindirizzato alla pagina di autorizzazione di Discord. Dopo aver accettato, tornerai automaticamente al sito.',
    regStep2T: 'Scegli un torneo aperto',
    regStep2D: 'Nella home trovi l\'elenco dei tornei disponibili. Quelli con lo stato "Aperto" accettano ancora iscrizioni. Clicca su un torneo per vederne i dettagli: date, quota di iscrizione, regole e montepremi.',
    regStep3T: 'Compila il modulo di iscrizione',
    regStep3D: 'Nella pagina del torneo trovi il pannello "Iscrizione al torneo". Verifica o modifica il tuo account Discord, inserisci nome e cognome, poi clicca "Conferma iscrizione".',
    regStep4T: 'Paga la quota di iscrizione (se prevista)',
    regStep4D: 'Se il torneo ha una quota di partecipazione, clicca "Paga su PayPal" e completa il pagamento. Una volta verificato dall\'admin, il tuo stato diventerà "Pagato" e la tua iscrizione sarà confermata definitivamente.',
    regPill1: 'Account Discord obbligatorio',
    regPill2: 'Tornei gratuiti: subito confermato',
    regPill3: 'Tornei a pagamento: attendi conferma admin',
    fmtSubtitle: 'Formato Round Robin (tutti contro tutti)',
    fmtBody: 'Ogni giocatore iscritto affronta tutti gli altri esattamente una volta. Il numero totale di partite è n×(n−1)/2, dove n è il numero di iscritti.',
    fmtPhasesTitle: 'Fasi del torneo',
    fmtP1L: 'Iscrizioni',
    fmtP1D: 'Gli utenti si iscrivono e (se richiesto) pagano la quota. Il torneo parte automaticamente alla data di inizio oppure quando tutti i giocatori risultano pagati.',
    fmtP2L: 'In corso',
    fmtP2D: 'Il calendario viene generato automaticamente con tutte le partite. Ogni giocatore può vedere le proprie sfide nel tab "Calendario" e inserire i risultati.',
    fmtP3L: 'Concluso',
    fmtP3D: 'Tutte le partite sono state giocate. La classifica finale è consultabile nel tab "Classifica".',
    fmtNote: 'Le partite si svolgono online, concordando orario e modalità direttamente con l\'avversario. Usa la funzione Disponibilità per trovare fasce orarie in comune.',
    resSubtitle: 'Come si riporta un risultato',
    resStep1T: 'Trova la tua partita',
    resStep1D: 'Vai nella pagina del torneo → tab "Calendario" → seleziona il tuo nome. Vedrai tutte le tue partite con lo stato attuale.',
    resStep2T: 'Inserisci il risultato',
    resStep2D: 'Clicca "Inserisci risultato" e scegli il numero di giochi vinti da ciascun giocatore (es. 2–1 significa che hai vinto 2 giochi e il tuo avversario 1). Il risultato viene marcato come "In attesa".',
    resStep3T: 'L\'avversario conferma',
    resStep3D: 'Il tuo avversario vedrà il risultato proposto e potrà confermarlo cliccando "Conferma risultato". Solo dopo la conferma di entrambi il risultato diventa definitivo.',
    resValidTitle: 'Risultati validi',
    resC1: 'Vittoria netta', resC2: 'Vittoria al tie-break', resC3: 'Vittoria corta',
    resC4: 'Pareggio',
    resC5: 'Sconfitta corta', resC6: 'Sconfitta al tie-break', resC7: 'Sconfitta netta',
    resWarning: 'In caso di disaccordo sul risultato, contatta un amministratore tramite il server Discord. Gli admin possono modificare o annullare qualsiasi risultato.',
    availSubtitle: 'Coordinarsi con gli avversari',
    availBody: 'Le partite del torneo vanno giocate online entro la data di fine torneo, accordandosi direttamente con l\'avversario. La funzione Disponibilità ti aiuta a trovare orari in comune in modo automatico.',
    availStep1T: 'Apri la pagina Disponibilità',
    availStep1D: 'Nella pagina del torneo, clicca il pulsante "Disponibilità". Potrai accedervi solo se sei iscritto al torneo.',
    availStep2T: 'Seleziona le tue fasce orarie',
    availStep2D: 'Scegli la data e le fasce di due ore in cui sei disponibile a giocare (copertura completa 00:00–24:00). Puoi selezionare più fasce per lo stesso giorno.',
    availStep3T: 'Salva e ricevi notifiche',
    availStep3D: 'Appena salvi le disponibilità, il sistema confronta automaticamente le tue fasce con quelle di ogni tuo avversario. Per ogni coppia con orari in comune, entrambi i giocatori ricevono un messaggio privato su Discord con i dettagli e un link diretto al torneo.',
    availDiscord: 'Le notifiche vengono inviate come messaggi privati Discord dal bot del torneo. Assicurati di avere i DM abilitati dal server o di non aver bloccato i messaggi privati.',
    stSubtitle: 'Sistema di punteggio',
    stWinL: 'Vittoria', stWinPts: '3 punti',
    stDrawL: 'Pareggio', stDrawPts: '1 punto',
    stLossL: 'Sconfitta', stLossPts: '0 punti',
    stTbTitle: 'Criteri di spareggio',
    stTb1L: 'Punti totali', stTb1D: 'Somma dei punti accumulati in tutte le partite',
    stTb2L: 'Vittorie', stTb2D: 'Numero di partite vinte',
    stTb3L: 'Differenza giochi', stTb3D: 'Giochi vinti meno giochi persi',
    stTb4L: 'Sconfitte', stTb4D: 'Meno sconfitte è meglio',
    stLegTitle: 'Legenda colonne',
    stLegG: 'Partite giocate', stLegV: 'Vittorie', stLegP: 'Pareggi',
    stLegS: 'Sconfitte', stLegGV: 'Giochi vinti', stLegGS: 'Giochi subiti', stLegPts: 'Punti totali',
    helpBody: 'Hai domande o problemi? Contatta gli amministratori tramite il server Discord di Lorcana Campania. Puoi segnalare:',
    helpB1: 'Risultati errati o contestati',
    helpB2: 'Problemi con l\'iscrizione o il pagamento',
    helpB3: 'Avversari non raggiungibili entro i tempi del torneo',
    helpB4: 'Qualsiasi altro problema tecnico con il sito',
    helpDiscord: 'Il pulsante "Visualizza su Discord" nella pagina del torneo ti porta direttamente al server. Se non sei ancora nel server, trovi il link di invito nella stessa pagina.',
  );

  // ── English ────────────────────────────────────────────────────────────────
  static const en = _S(
    appBarTitle: 'Lorcana League Guide',
    heroTitle: 'Complete Guide',
    heroSubtitle: 'Everything you need to know to participate in Lorcana Campania\'s online tournaments: how to register, how matches work, and how to read the standings.',
    secReg: 'How to register for a tournament',
    secFormat: 'How the tournament works',
    secResults: 'Entering and confirming results',
    secAvail: 'Match availability',
    secStandings: 'Standings and scoring',
    secHelp: 'Need help?',
    regStep1T: 'Log in with Discord',
    regStep1D: 'Click the "Login Discord" button at the top right. You will be redirected to Discord\'s authorization page. Once you accept, you will be automatically returned to the site.',
    regStep2T: 'Choose an open tournament',
    regStep2D: 'On the home page you\'ll find the list of available tournaments. Those with the "Open" status still accept registrations. Click on a tournament to see its details: dates, entry fee, rules, and prize pool.',
    regStep3T: 'Fill in the registration form',
    regStep3D: 'On the tournament page, find the "Tournament Registration" panel. Verify or update your Discord account, enter your first and last name, then click "Confirm registration".',
    regStep4T: 'Pay the entry fee (if applicable)',
    regStep4D: 'If the tournament has an entry fee, click "Pay on PayPal" and complete the payment. Once verified by the admin, your status will become "Paid" and your registration will be permanently confirmed.',
    regPill1: 'Discord account required',
    regPill2: 'Free tournaments: immediately confirmed',
    regPill3: 'Paid tournaments: await admin confirmation',
    fmtSubtitle: 'Round Robin format (everyone vs. everyone)',
    fmtBody: 'Each registered player faces every other player exactly once. The total number of matches is n×(n−1)/2, where n is the number of registered players.',
    fmtPhasesTitle: 'Tournament phases',
    fmtP1L: 'Registrations',
    fmtP1D: 'Players register and (if required) pay the entry fee. The tournament starts automatically on the start date or when all players are marked as paid.',
    fmtP2L: 'Ongoing',
    fmtP2D: 'The schedule is generated automatically with all matches. Each player can see their matches in the "Calendar" tab and enter results.',
    fmtP3L: 'Completed',
    fmtP3D: 'All matches have been played. The final standings can be viewed in the "Standings" tab.',
    fmtNote: 'Matches are played online, agreeing on time and format directly with the opponent. Use the Availability feature to find common time slots.',
    resSubtitle: 'How to report a result',
    resStep1T: 'Find your match',
    resStep1D: 'Go to the tournament page → "Calendar" tab → select your name. You will see all your matches with their current status.',
    resStep2T: 'Enter the result',
    resStep2D: 'Click "Enter result" and choose the number of games won by each player (e.g. 2–1 means you won 2 games and your opponent won 1). The result is marked as "Pending".',
    resStep3T: 'Your opponent confirms',
    resStep3D: 'Your opponent will see the proposed result and can confirm it by clicking "Confirm result". The result only becomes final after both players confirm.',
    resValidTitle: 'Valid results',
    resC1: 'Clean win', resC2: 'Tie-break win', resC3: 'Short win',
    resC4: 'Draw',
    resC5: 'Short loss', resC6: 'Tie-break loss', resC7: 'Clean loss',
    resWarning: 'In case of disagreement on the result, contact an administrator through the Discord server. Admins can modify or cancel any result.',
    availSubtitle: 'Coordinating with opponents',
    availBody: 'Tournament matches must be played online before the tournament end date, by agreeing directly with your opponent. The Availability feature helps you find common time slots automatically.',
    availStep1T: 'Open the Availability page',
    availStep1D: 'On the tournament page, click the "Availability" button. You can only access it if you are registered for the tournament.',
    availStep2T: 'Select your time slots',
    availStep2D: 'Choose the date and two-hour slots when you are available to play (full coverage 00:00–24:00). You can select multiple slots for the same day.',
    availStep3T: 'Save and receive notifications',
    availStep3D: 'As soon as you save your availability, the system automatically compares your slots with those of each opponent. For every pair with common time slots, both players receive a private Discord message with the details and a direct link to the tournament.',
    availDiscord: 'Notifications are sent as private Discord messages from the tournament bot. Make sure you have DMs enabled from the server or have not blocked private messages.',
    stSubtitle: 'Scoring system',
    stWinL: 'Win', stWinPts: '3 points',
    stDrawL: 'Draw', stDrawPts: '1 point',
    stLossL: 'Loss', stLossPts: '0 points',
    stTbTitle: 'Tiebreaker criteria',
    stTb1L: 'Total points', stTb1D: 'Sum of points accumulated across all matches',
    stTb2L: 'Wins', stTb2D: 'Number of matches won',
    stTb3L: 'Game difference', stTb3D: 'Games won minus games lost',
    stTb4L: 'Losses', stTb4D: 'Fewer losses is better',
    stLegTitle: 'Column legend',
    stLegG: 'Matches played', stLegV: 'Wins', stLegP: 'Draws',
    stLegS: 'Losses', stLegGV: 'Games won', stLegGS: 'Games conceded', stLegPts: 'Total points',
    helpBody: 'Have questions or issues? Contact the administrators through the Lorcana Campania Discord server. You can report:',
    helpB1: 'Incorrect or disputed results',
    helpB2: 'Issues with registration or payment',
    helpB3: 'Opponents unreachable within the tournament timeframe',
    helpB4: 'Any other technical issues with the site',
    helpDiscord: 'The "View on Discord" button on the tournament page takes you directly to the server. If you are not yet in the server, you will find the invite link on the same page.',
  );

  // ── Spanish ────────────────────────────────────────────────────────────────
  static const es = _S(
    appBarTitle: 'Guía de la Lorcana League',
    heroTitle: 'Guía completa',
    heroSubtitle: 'Todo lo que necesitas saber para participar en los torneos en línea de Lorcana Campania: cómo inscribirse, cómo funcionan las partidas y cómo consultar la clasificación.',
    secReg: 'Cómo inscribirse en un torneo',
    secFormat: 'Cómo funciona el torneo',
    secResults: 'Introducción y confirmación de resultados',
    secAvail: 'Disponibilidad para las partidas',
    secStandings: 'Clasificación y puntuación',
    secHelp: '¿Necesitas ayuda?',
    regStep1T: 'Inicia sesión con Discord',
    regStep1D: 'Haz clic en el botón "Login Discord" en la parte superior derecha. Serás redirigido a la página de autorización de Discord. Una vez que aceptes, volverás automáticamente al sitio.',
    regStep2T: 'Elige un torneo abierto',
    regStep2D: 'En la página principal encontrarás la lista de torneos disponibles. Los que tienen el estado "Abierto" aún aceptan inscripciones. Haz clic en un torneo para ver sus detalles: fechas, cuota de inscripción, reglas y premios.',
    regStep3T: 'Rellena el formulario de inscripción',
    regStep3D: 'En la página del torneo encontrarás el panel "Inscripción al torneo". Verifica o modifica tu cuenta de Discord, introduce nombre y apellidos, y luego haz clic en "Confirmar inscripción".',
    regStep4T: 'Paga la cuota de inscripción (si procede)',
    regStep4D: 'Si el torneo tiene una cuota de inscripción, haz clic en "Pagar con PayPal" y completa el pago. Una vez verificado por el admin, tu estado pasará a "Pagado" y tu inscripción quedará definitivamente confirmada.',
    regPill1: 'Cuenta Discord obligatoria',
    regPill2: 'Torneos gratuitos: confirmación inmediata',
    regPill3: 'Torneos de pago: esperar confirmación del admin',
    fmtSubtitle: 'Formato Round Robin (todos contra todos)',
    fmtBody: 'Cada jugador inscrito se enfrenta a todos los demás exactamente una vez. El número total de partidas es n×(n−1)/2, donde n es el número de inscritos.',
    fmtPhasesTitle: 'Fases del torneo',
    fmtP1L: 'Inscripciones',
    fmtP1D: 'Los jugadores se inscriben y (si se requiere) pagan la cuota. El torneo comienza automáticamente en la fecha de inicio o cuando todos los jugadores están marcados como pagados.',
    fmtP2L: 'En curso',
    fmtP2D: 'El calendario se genera automáticamente con todas las partidas. Cada jugador puede ver sus enfrentamientos en la pestaña "Calendario" e introducir los resultados.',
    fmtP3L: 'Concluido',
    fmtP3D: 'Todas las partidas han sido jugadas. La clasificación final está disponible en la pestaña "Clasificación".',
    fmtNote: 'Las partidas se juegan en línea, acordando horario y modalidad directamente con el adversario. Usa la función Disponibilidad para encontrar franjas horarias en común.',
    resSubtitle: 'Cómo registrar un resultado',
    resStep1T: 'Encuentra tu partida',
    resStep1D: 'Ve a la página del torneo → pestaña "Calendario" → selecciona tu nombre. Verás todas tus partidas con su estado actual.',
    resStep2T: 'Introduce el resultado',
    resStep2D: 'Haz clic en "Introducir resultado" y elige el número de juegos ganados por cada jugador (p. ej., 2–1 significa que ganaste 2 juegos y tu adversario 1). El resultado queda marcado como "En espera".',
    resStep3T: 'El adversario confirma',
    resStep3D: 'Tu adversario verá el resultado propuesto y podrá confirmarlo haciendo clic en "Confirmar resultado". El resultado solo se vuelve definitivo tras la confirmación de ambos.',
    resValidTitle: 'Resultados válidos',
    resC1: 'Victoria clara', resC2: 'Victoria en tie-break', resC3: 'Victoria corta',
    resC4: 'Empate',
    resC5: 'Derrota corta', resC6: 'Derrota en tie-break', resC7: 'Derrota clara',
    resWarning: 'En caso de desacuerdo sobre el resultado, contacta con un administrador a través del servidor de Discord. Los admins pueden modificar o anular cualquier resultado.',
    availSubtitle: 'Coordinarse con los adversarios',
    availBody: 'Las partidas del torneo deben jugarse en línea antes de la fecha de finalización del torneo, acordándolo directamente con el adversario. La función Disponibilidad te ayuda a encontrar horarios en común de forma automática.',
    availStep1T: 'Abre la página de Disponibilidad',
    availStep1D: 'En la página del torneo, haz clic en el botón "Disponibilidad". Solo podrás acceder si estás inscrito en el torneo.',
    availStep2T: 'Selecciona tus franjas horarias',
    availStep2D: 'Elige la fecha y las franjas de dos horas en las que estás disponible para jugar (cobertura completa 00:00–24:00). Puedes seleccionar múltiples franjas para el mismo día.',
    availStep3T: 'Guarda y recibe notificaciones',
    availStep3D: 'En cuanto guardas la disponibilidad, el sistema compara automáticamente tus franjas con las de cada adversario. Por cada pareja con horarios en común, ambos jugadores reciben un mensaje privado en Discord con los detalles y un enlace directo al torneo.',
    availDiscord: 'Las notificaciones se envían como mensajes privados de Discord desde el bot del torneo. Asegúrate de tener los DMs habilitados desde el servidor o de no haber bloqueado los mensajes privados.',
    stSubtitle: 'Sistema de puntuación',
    stWinL: 'Victoria', stWinPts: '3 puntos',
    stDrawL: 'Empate', stDrawPts: '1 punto',
    stLossL: 'Derrota', stLossPts: '0 puntos',
    stTbTitle: 'Criterios de desempate',
    stTb1L: 'Puntos totales', stTb1D: 'Suma de puntos acumulados en todas las partidas',
    stTb2L: 'Victorias', stTb2D: 'Número de partidas ganadas',
    stTb3L: 'Diferencia de juegos', stTb3D: 'Juegos ganados menos juegos perdidos',
    stTb4L: 'Derrotas', stTb4D: 'Menos derrotas es mejor',
    stLegTitle: 'Leyenda de columnas',
    stLegG: 'Partidas jugadas', stLegV: 'Victorias', stLegP: 'Empates',
    stLegS: 'Derrotas', stLegGV: 'Juegos ganados', stLegGS: 'Juegos encajados', stLegPts: 'Puntos totales',
    helpBody: '¿Tienes preguntas o problemas? Contacta con los administradores a través del servidor de Discord de Lorcana Campania. Puedes reportar:',
    helpB1: 'Resultados incorrectos o disputados',
    helpB2: 'Problemas con la inscripción o el pago',
    helpB3: 'Adversarios no disponibles dentro del plazo del torneo',
    helpB4: 'Cualquier otro problema técnico con el sitio',
    helpDiscord: 'El botón "Ver en Discord" en la página del torneo te lleva directamente al servidor. Si aún no estás en el servidor, encontrarás el enlace de invitación en la misma página.',
  );

  // ── French ─────────────────────────────────────────────────────────────────
  static const fr = _S(
    appBarTitle: 'Guide de la Lorcana League',
    heroTitle: 'Guide complet',
    heroSubtitle: 'Tout ce que vous devez savoir pour participer aux tournois en ligne de Lorcana Campania : comment s\'inscrire, comment fonctionnent les matchs et comment consulter le classement.',
    secReg: 'Comment s\'inscrire à un tournoi',
    secFormat: 'Comment fonctionne le tournoi',
    secResults: 'Saisie et confirmation des résultats',
    secAvail: 'Disponibilité pour les matchs',
    secStandings: 'Classement et scores',
    secHelp: 'Besoin d\'aide ?',
    regStep1T: 'Connectez-vous avec Discord',
    regStep1D: 'Cliquez sur le bouton "Login Discord" en haut à droite. Vous serez redirigé vers la page d\'autorisation de Discord. Après avoir accepté, vous reviendrez automatiquement sur le site.',
    regStep2T: 'Choisissez un tournoi ouvert',
    regStep2D: 'Sur la page d\'accueil, vous trouverez la liste des tournois disponibles. Ceux avec le statut "Ouvert" acceptent encore des inscriptions. Cliquez sur un tournoi pour voir ses détails : dates, frais d\'inscription, règles et prix.',
    regStep3T: 'Remplissez le formulaire d\'inscription',
    regStep3D: 'Sur la page du tournoi, trouvez le panneau "Inscription au tournoi". Vérifiez ou modifiez votre compte Discord, entrez votre prénom et nom de famille, puis cliquez sur "Confirmer l\'inscription".',
    regStep4T: 'Payez les frais d\'inscription (si applicable)',
    regStep4D: 'Si le tournoi a des frais d\'inscription, cliquez sur "Payer sur PayPal" et effectuez le paiement. Une fois vérifié par l\'admin, votre statut deviendra "Payé" et votre inscription sera définitivement confirmée.',
    regPill1: 'Compte Discord obligatoire',
    regPill2: 'Tournois gratuits : confirmation immédiate',
    regPill3: 'Tournois payants : attendre la confirmation admin',
    fmtSubtitle: 'Format Round Robin (tout le monde contre tout le monde)',
    fmtBody: 'Chaque joueur inscrit affronte tous les autres exactement une fois. Le nombre total de matchs est n×(n−1)/2, où n est le nombre d\'inscrits.',
    fmtPhasesTitle: 'Phases du tournoi',
    fmtP1L: 'Inscriptions',
    fmtP1D: 'Les joueurs s\'inscrivent et (si requis) paient les frais. Le tournoi démarre automatiquement à la date de début ou lorsque tous les joueurs sont marqués comme payés.',
    fmtP2L: 'En cours',
    fmtP2D: 'Le calendrier est généré automatiquement avec tous les matchs. Chaque joueur peut voir ses rencontres dans l\'onglet "Calendrier" et saisir les résultats.',
    fmtP3L: 'Terminé',
    fmtP3D: 'Tous les matchs ont été joués. Le classement final est consultable dans l\'onglet "Classement".',
    fmtNote: 'Les matchs se jouent en ligne, en se mettant d\'accord sur l\'horaire et le format directement avec l\'adversaire. Utilisez la fonction Disponibilité pour trouver des créneaux communs.',
    resSubtitle: 'Comment rapporter un résultat',
    resStep1T: 'Trouvez votre match',
    resStep1D: 'Allez sur la page du tournoi → onglet "Calendrier" → sélectionnez votre nom. Vous verrez tous vos matchs avec leur statut actuel.',
    resStep2T: 'Saisissez le résultat',
    resStep2D: 'Cliquez sur "Saisir le résultat" et choisissez le nombre de jeux remportés par chaque joueur (ex. 2–1 signifie que vous avez gagné 2 jeux et votre adversaire 1). Le résultat est marqué comme "En attente".',
    resStep3T: 'L\'adversaire confirme',
    resStep3D: 'Votre adversaire verra le résultat proposé et pourra le confirmer en cliquant sur "Confirmer le résultat". Le résultat ne devient définitif qu\'après la confirmation des deux joueurs.',
    resValidTitle: 'Résultats valides',
    resC1: 'Victoire nette', resC2: 'Victoire au tie-break', resC3: 'Courte victoire',
    resC4: 'Nul',
    resC5: 'Courte défaite', resC6: 'Défaite au tie-break', resC7: 'Défaite nette',
    resWarning: 'En cas de désaccord sur le résultat, contactez un administrateur via le serveur Discord. Les admins peuvent modifier ou annuler n\'importe quel résultat.',
    availSubtitle: 'Se coordonner avec les adversaires',
    availBody: 'Les matchs du tournoi doivent être joués en ligne avant la date de fin du tournoi, en s\'accordant directement avec l\'adversaire. La fonction Disponibilité vous aide à trouver des créneaux communs automatiquement.',
    availStep1T: 'Ouvrez la page Disponibilité',
    availStep1D: 'Sur la page du tournoi, cliquez sur le bouton "Disponibilité". Vous ne pouvez y accéder que si vous êtes inscrit au tournoi.',
    availStep2T: 'Sélectionnez vos créneaux',
    availStep2D: 'Choisissez la date et les créneaux de deux heures où vous êtes disponible pour jouer (couverture complète 00:00–24:00). Vous pouvez sélectionner plusieurs créneaux pour le même jour.',
    availStep3T: 'Enregistrez et recevez des notifications',
    availStep3D: 'Dès que vous enregistrez vos disponibilités, le système compare automatiquement vos créneaux avec ceux de chaque adversaire. Pour chaque paire avec des créneaux communs, les deux joueurs reçoivent un message privé Discord avec les détails et un lien direct vers le tournoi.',
    availDiscord: 'Les notifications sont envoyées en messages privés Discord depuis le bot du tournoi. Assurez-vous d\'avoir les DM activés depuis le serveur ou de ne pas avoir bloqué les messages privés.',
    stSubtitle: 'Système de points',
    stWinL: 'Victoire', stWinPts: '3 points',
    stDrawL: 'Nul', stDrawPts: '1 point',
    stLossL: 'Défaite', stLossPts: '0 point',
    stTbTitle: 'Critères de départage',
    stTb1L: 'Points totaux', stTb1D: 'Somme des points accumulés dans tous les matchs',
    stTb2L: 'Victoires', stTb2D: 'Nombre de matchs gagnés',
    stTb3L: 'Différence de jeux', stTb3D: 'Jeux gagnés moins jeux perdus',
    stTb4L: 'Défaites', stTb4D: 'Moins de défaites est mieux',
    stLegTitle: 'Légende des colonnes',
    stLegG: 'Matchs joués', stLegV: 'Victoires', stLegP: 'Nuls',
    stLegS: 'Défaites', stLegGV: 'Jeux gagnés', stLegGS: 'Jeux encaissés', stLegPts: 'Points totaux',
    helpBody: 'Vous avez des questions ou des problèmes ? Contactez les administrateurs via le serveur Discord de Lorcana Campania. Vous pouvez signaler :',
    helpB1: 'Résultats incorrects ou contestés',
    helpB2: 'Problèmes avec l\'inscription ou le paiement',
    helpB3: 'Adversaires injoignables dans les délais du tournoi',
    helpB4: 'Tout autre problème technique avec le site',
    helpDiscord: 'Le bouton "Voir sur Discord" sur la page du tournoi vous amène directement au serveur. Si vous n\'êtes pas encore dans le serveur, vous trouverez le lien d\'invitation sur la même page.',
  );
}

const _kStrings = {
  _Lang.it: _S.it,
  _Lang.en: _S.en,
  _Lang.es: _S.es,
  _Lang.fr: _S.fr,
};

// ─── Screen ───────────────────────────────────────────────────────────────────

class WikiScreen extends StatefulWidget {
  const WikiScreen({super.key});
  @override
  State<WikiScreen> createState() => _WikiScreenState();
}

class _WikiScreenState extends State<WikiScreen> {
  _Lang _lang = _Lang.it;

  @override
  Widget build(BuildContext context) {
    final s = _kStrings[_lang]!;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.go('/'),
          icon: const Icon(Icons.home_outlined),
          tooltip: 'Home',
        ),
        title: Text(s.appBarTitle),
        actions: [
          ..._Lang.values.map((l) => _LangButton(
                lang: l,
                selected: _lang == l,
                onTap: () => setState(() => _lang = l),
              )),
          const SizedBox(width: 8),
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
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 48),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 820),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _WikiHero(s: s),
                  const SizedBox(height: 28),
                  _SectionCard(
                    icon: Icons.login_outlined,
                    iconColor: const Color(0xFF5D2EA6),
                    title: s.secReg,
                    child: _RegSection(s: s),
                  ),
                  const SizedBox(height: 16),
                  _SectionCard(
                    icon: Icons.emoji_events_outlined,
                    iconColor: const Color(0xFFC8960A),
                    title: s.secFormat,
                    child: _FormatSection(s: s),
                  ),
                  const SizedBox(height: 16),
                  _SectionCard(
                    icon: Icons.scoreboard_outlined,
                    iconColor: const Color(0xFF2E7D32),
                    title: s.secResults,
                    child: _ResultsSection(s: s),
                  ),
                  const SizedBox(height: 16),
                  _SectionCard(
                    icon: Icons.event_available_outlined,
                    iconColor: const Color(0xFF1565C0),
                    title: s.secAvail,
                    child: _AvailSection(s: s),
                  ),
                  const SizedBox(height: 16),
                  _SectionCard(
                    icon: Icons.leaderboard_outlined,
                    iconColor: const Color(0xFF6A1B9A),
                    title: s.secStandings,
                    child: _StandingsSection(s: s),
                  ),
                  const SizedBox(height: 16),
                  _SectionCard(
                    icon: Icons.help_outline,
                    iconColor: const Color(0xFF00695C),
                    title: s.secHelp,
                    child: _HelpSection(s: s),
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

// ─── Language button ──────────────────────────────────────────────────────────

class _LangButton extends StatelessWidget {
  final _Lang lang;
  final bool selected;
  final VoidCallback onTap;
  const _LangButton({required this.lang, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF5D2EA6).withValues(alpha: .14) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: selected
              ? Border.all(color: const Color(0xFF5D2EA6), width: 1.5)
              : Border.all(color: Colors.transparent),
        ),
        child: Text(
          _kLangFlag[lang]!,
          style: const TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}

// ─── Hero ─────────────────────────────────────────────────────────────────────

class _WikiHero extends StatelessWidget {
  final _S s;
  const _WikiHero({required this.s});

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
              Text(s.heroTitle,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              Text(s.heroSubtitle,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.white.withValues(alpha: .82))),
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
    required this.icon, required this.iconColor,
    required this.title, required this.child,
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
              child: Text(title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800, color: const Color(0xFF2D145C))),
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

// ─── Shared: step row ─────────────────────────────────────────────────────────

class _Step extends StatelessWidget {
  final int number;
  final String title;
  final String description;
  const _Step({required this.number, required this.title, required this.description});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 32, height: 32,
          alignment: Alignment.center,
          decoration: const BoxDecoration(color: Color(0xFF5D2EA6), shape: BoxShape.circle),
          child: Text('$number',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
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

// ─── Shared: info pill ────────────────────────────────────────────────────────

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
        Flexible(child: Text(text, style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w600))),
      ]),
    );
  }
}

// ─── Section: Registration ────────────────────────────────────────────────────

class _RegSection extends StatelessWidget {
  final _S s;
  const _RegSection({required this.s});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _Step(number: 1, title: s.regStep1T, description: s.regStep1D),
      _Step(number: 2, title: s.regStep2T, description: s.regStep2D),
      _Step(number: 3, title: s.regStep3T, description: s.regStep3D),
      _Step(number: 4, title: s.regStep4T, description: s.regStep4D),
      const SizedBox(height: 4),
      Wrap(spacing: 10, runSpacing: 10, children: [
        _InfoPill(icon: Icons.discord, text: s.regPill1, color: const Color(0xFF5865F2)),
        _InfoPill(icon: Icons.lock_open_outlined, text: s.regPill2, color: const Color(0xFF2E7D32)),
        _InfoPill(icon: Icons.payments_outlined, text: s.regPill3, color: const Color(0xFFC8960A)),
      ]),
    ]);
  }
}

// ─── Section: Tournament format ───────────────────────────────────────────────

class _FormatSection extends StatelessWidget {
  final _S s;
  const _FormatSection({required this.s});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(s.fmtSubtitle,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700, color: const Color(0xFF2D145C))),
      const SizedBox(height: 10),
      Text(s.fmtBody, style: TextStyle(fontSize: 14, color: Colors.grey.shade700, height: 1.55)),
      const SizedBox(height: 16),
      Text(s.fmtPhasesTitle,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700, color: const Color(0xFF2D145C))),
      const SizedBox(height: 10),
      _phaseRow(Icons.app_registration_outlined, const Color(0xFF1565C0), s.fmtP1L, s.fmtP1D),
      const SizedBox(height: 10),
      _phaseRow(Icons.play_circle_outline, const Color(0xFF2E7D32), s.fmtP2L, s.fmtP2D),
      const SizedBox(height: 10),
      _phaseRow(Icons.flag_outlined, const Color(0xFF6A1B9A), s.fmtP3L, s.fmtP3D),
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
            child: Text(s.fmtNote,
                style: TextStyle(fontSize: 13, color: Colors.brown.shade700, height: 1.5)),
          ),
        ]),
      ),
    ]);
  }

  Widget _phaseRow(IconData icon, Color color, String label, String desc) {
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
          Text(label,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF2D145C))),
          const SizedBox(height: 3),
          Text(desc, style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.5)),
        ]),
      ),
    ]);
  }
}

// ─── Section: Results ─────────────────────────────────────────────────────────

class _ResultsSection extends StatelessWidget {
  final _S s;
  const _ResultsSection({required this.s});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(s.resSubtitle,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700, color: const Color(0xFF2D145C))),
      const SizedBox(height: 12),
      _Step(number: 1, title: s.resStep1T, description: s.resStep1D),
      _Step(number: 2, title: s.resStep2T, description: s.resStep2D),
      _Step(number: 3, title: s.resStep3T, description: s.resStep3D),
      const SizedBox(height: 4),
      Text(s.resValidTitle,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700, color: const Color(0xFF2D145C))),
      const SizedBox(height: 10),
      Wrap(spacing: 8, runSpacing: 8, children: [
        _resultChip('2 – 0', s.resC1, const Color(0xFF2E7D32)),
        _resultChip('2 – 1', s.resC2, const Color(0xFF2E7D32)),
        _resultChip('1 – 0', s.resC3, const Color(0xFF2E7D32)),
        _resultChip('1 – 1', s.resC4, const Color(0xFF1565C0)),
        _resultChip('0 – 1', s.resC5, Colors.red),
        _resultChip('1 – 2', s.resC6, Colors.red),
        _resultChip('0 – 2', s.resC7, Colors.red),
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
            child: Text(s.resWarning,
                style: TextStyle(fontSize: 13, color: Colors.red.shade800, height: 1.5)),
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

// ─── Section: Availability ────────────────────────────────────────────────────

class _AvailSection extends StatelessWidget {
  final _S s;
  const _AvailSection({required this.s});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(s.availSubtitle,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700, color: const Color(0xFF2D145C))),
      const SizedBox(height: 10),
      Text(s.availBody, style: TextStyle(fontSize: 14, color: Colors.grey.shade700, height: 1.55)),
      const SizedBox(height: 16),
      _Step(number: 1, title: s.availStep1T, description: s.availStep1D),
      _Step(number: 2, title: s.availStep2T, description: s.availStep2D),
      _Step(number: 3, title: s.availStep3T, description: s.availStep3D),
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
            child: Text(s.availDiscord,
                style: const TextStyle(fontSize: 13, color: Color(0xFF283593), height: 1.5)),
          ),
        ]),
      ),
    ]);
  }
}

// ─── Section: Standings ───────────────────────────────────────────────────────

class _StandingsSection extends StatelessWidget {
  final _S s;
  const _StandingsSection({required this.s});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(s.stSubtitle,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700, color: const Color(0xFF2D145C))),
      const SizedBox(height: 12),
      LayoutBuilder(builder: (context, c) {
        final wide = c.maxWidth > 400;
        final rows = [
          _PointsRow(icon: Icons.emoji_events, color: const Color(0xFFF9A825), label: s.stWinL, pts: s.stWinPts),
          _PointsRow(icon: Icons.handshake_outlined, color: const Color(0xFF1565C0), label: s.stDrawL, pts: s.stDrawPts),
          _PointsRow(icon: Icons.close, color: Colors.red, label: s.stLossL, pts: s.stLossPts),
        ];
        return wide
            ? Row(children: rows.map((w) => Expanded(child: w)).toList())
            : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: rows);
      }),
      const SizedBox(height: 16),
      Text(s.stTbTitle,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700, color: const Color(0xFF2D145C))),
      const SizedBox(height: 10),
      _tbRow('1°', s.stTb1L, s.stTb1D),
      const SizedBox(height: 8),
      _tbRow('2°', s.stTb2L, s.stTb2D),
      const SizedBox(height: 8),
      _tbRow('3°', s.stTb3L, s.stTb3D),
      const SizedBox(height: 8),
      _tbRow('4°', s.stTb4L, s.stTb4D),
      const SizedBox(height: 16),
      Text(s.stLegTitle,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700, color: const Color(0xFF2D145C))),
      const SizedBox(height: 10),
      Wrap(spacing: 8, runSpacing: 8, children: [
        _LegChip('G', s.stLegG), _LegChip('V', s.stLegV), _LegChip('P', s.stLegP),
        _LegChip('S', s.stLegS), _LegChip('GV', s.stLegGV),
        _LegChip('GS', s.stLegGS), _LegChip('Pts', s.stLegPts),
      ]),
    ]);
  }

  Widget _tbRow(String pos, String label, String desc) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: 28, height: 28,
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
  final String pts;
  const _PointsRow({required this.icon, required this.color, required this.label, required this.pts});

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
        Text(pts, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color)),
      ]),
    );
  }
}

class _LegChip extends StatelessWidget {
  final String abbr;
  final String full;
  const _LegChip(this.abbr, this.full);

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

// ─── Section: Help ────────────────────────────────────────────────────────────

class _HelpSection extends StatelessWidget {
  final _S s;
  const _HelpSection({required this.s});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(s.helpBody, style: TextStyle(fontSize: 14, color: Colors.grey.shade700, height: 1.55)),
      const SizedBox(height: 12),
      _bullet(s.helpB1),
      _bullet(s.helpB2),
      _bullet(s.helpB3),
      _bullet(s.helpB4),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFE8EAF6),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF5865F2).withValues(alpha: .4)),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.discord, color: Color(0xFF5865F2), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(s.helpDiscord,
                style: const TextStyle(fontSize: 13, color: Color(0xFF283593), height: 1.5)),
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
          padding: const EdgeInsets.only(top: 7),
          child: Container(
            width: 6, height: 6,
            decoration: const BoxDecoration(color: Color(0xFF5D2EA6), shape: BoxShape.circle),
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
