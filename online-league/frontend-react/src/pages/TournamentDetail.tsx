import { useEffect, useState, useCallback, useRef } from 'react';
import {
  Container, Row, Col, Card, Badge, Button, ProgressBar,
  Spinner, Alert, Tab, Tabs, Table, Modal, Form,
} from 'react-bootstrap';
import { useParams, useNavigate, Link } from 'react-router-dom';
import Layout from '../Layout';
import { api } from '../api';
import { useSession } from '../SessionContext';
import type {
  TournamentDetail as TDetail, FullRegistration,
  MatchResult, StandingEntry,
} from '../models';

// ── Helpers ──────────────────────────────────────────────────────────────────
function fmtDate(iso: string) {
  return new Date(iso).toLocaleDateString('it-IT', { day: '2-digit', month: 'short', year: 'numeric' });
}
function fmtDatetime(iso: string) {
  return new Date(iso).toLocaleDateString('it-IT', { day: '2-digit', month: 'short', year: 'numeric', hour: '2-digit', minute: '2-digit' });
}

const STATUS_MAP = {
  registration: { bg: 'badge-registration', label: '📋 Iscrizioni aperte' },
  ongoing:      { bg: 'badge-ongoing',      label: '⚡ In corso' },
  completed:    { bg: 'badge-completed',    label: '🏁 Concluso' },
};

const SCORE_OPTIONS = [
  { g1: 2, g2: 0 }, { g1: 2, g2: 1 }, { g1: 1, g2: 0 },
  { g1: 1, g2: 1 },
  { g1: 0, g2: 1 }, { g1: 1, g2: 2 }, { g1: 0, g2: 2 },
];

// ── Match card ────────────────────────────────────────────────────────────────
function MatchCard({
  match, myRegId, isAdmin, onAction,
}: {
  match: MatchResult;
  myRegId?: number;
  isAdmin: boolean;
  onAction: () => void;
}) {
  const [showPropose, setShowPropose] = useState(false);
  const [selScore, setSelScore] = useState<{ g1: number; g2: number } | null>(null);
  const [acting, setActing] = useState(false);
  const [err, setErr] = useState('');

  const isReg1 = match.reg1_id === myRegId;
  const isReg2 = match.reg2_id === myRegId;
  const isMyMatch = isReg1 || isReg2;
  const proposedByMe = match.proposed_by_reg_id === myRegId;
  const canConfirm = match.result_status === 'proposed' && !proposedByMe && (isMyMatch || isAdmin);
  const canPropose = match.result_status !== 'confirmed' && (isMyMatch || isAdmin);
  const canReset = isAdmin && match.result_status !== 'pending';

  const statusIcon = { pending: '⏳', proposed: '🕐', confirmed: '✅' }[match.result_status];

  let score = '–';
  if (match.games_reg1 !== null && match.games_reg1 !== undefined) {
    score = `${match.games_reg1} – ${match.games_reg2}`;
  }

  async function propose(forceConfirm = false) {
    if (!selScore) return;
    setActing(true); setErr('');
    try {
      const [g1, g2] = isReg1
        ? [selScore.g1, selScore.g2]
        : [selScore.g2, selScore.g1];
      await api.proposeResult(match.id, g1, g2, forceConfirm);
      setShowPropose(false);
      onAction();
    } catch (e: unknown) {
      setErr(e instanceof Error ? e.message : 'Errore');
    } finally {
      setActing(false);
    }
  }

  async function confirm() {
    setActing(true);
    try { await api.confirmResult(match.id); onAction(); }
    catch (e: unknown) { setErr(e instanceof Error ? e.message : 'Errore'); }
    finally { setActing(false); }
  }

  async function reset() {
    setActing(true);
    try { await api.resetResult(match.id); onAction(); }
    catch (e: unknown) { setErr(e instanceof Error ? e.message : 'Errore'); }
    finally { setActing(false); }
  }

  return (
    <>
      <Card className={`match-card mb-2 ${isMyMatch ? 'my-match' : ''}`}>
        <Card.Body className="py-2 px-3">
          <div className="d-flex align-items-center justify-content-between flex-wrap gap-2">
            <div className="d-flex align-items-center gap-3 flex-wrap">
              <span className="match-player">{match.reg1.first_name} {match.reg1.last_name}</span>
              <span className="match-score">{score}</span>
              <span className="match-player">{match.reg2.first_name} {match.reg2.last_name}</span>
            </div>
            <div className="d-flex align-items-center gap-2 flex-wrap">
              <span className={`small result-${match.result_status}`}>{statusIcon}</span>
              {err && <span className="text-danger small">{err}</span>}
              {canConfirm && (
                <Button size="sm" variant="success" onClick={confirm} disabled={acting}>
                  {acting ? <Spinner size="sm" /> : '✅ Conferma'}
                </Button>
              )}
              {canPropose && (
                <Button size="sm" variant="outline-primary" onClick={() => { setSelScore(null); setShowPropose(true); }}>
                  {match.result_status === 'pending' ? '📝 Inserisci' : '✏️ Modifica'}
                </Button>
              )}
              {canReset && (
                <Button size="sm" variant="outline-danger" onClick={reset} disabled={acting}>
                  🔄
                </Button>
              )}
            </div>
          </div>
        </Card.Body>
      </Card>

      <Modal show={showPropose} onHide={() => setShowPropose(false)} centered>
        <Modal.Header closeButton>
          <Modal.Title>📝 Inserisci risultato</Modal.Title>
        </Modal.Header>
        <Modal.Body>
          <p className="text-muted small mb-3">
            {isReg1 ? match.reg1.first_name : match.reg2.first_name} (tu) vs {isReg1 ? match.reg2.first_name : match.reg1.first_name}
          </p>
          <div className="d-flex flex-wrap gap-2 mb-3">
            {SCORE_OPTIONS.map(opt => {
              const label = isReg1 ? `${opt.g1}–${opt.g2}` : `${opt.g2}–${opt.g1}`;
              const active = selScore?.g1 === opt.g1 && selScore?.g2 === opt.g2;
              const yourGames = isReg1 ? opt.g1 : opt.g2;
              const oppGames  = isReg1 ? opt.g2 : opt.g1;
              const variant = yourGames > oppGames ? 'success' : yourGames === oppGames ? 'warning' : 'danger';
              return (
                <Button
                  key={`${opt.g1}-${opt.g2}`}
                  variant={active ? variant : `outline-${variant}`}
                  size="sm"
                  className="fw-bold"
                  onClick={() => setSelScore(opt)}
                >
                  {label}
                </Button>
              );
            })}
          </div>
          {err && <Alert variant="danger" className="py-2">{err}</Alert>}
        </Modal.Body>
        <Modal.Footer>
          <Button variant="secondary" onClick={() => setShowPropose(false)}>Annulla</Button>
          {isAdmin && selScore && (
            <Button variant="warning" onClick={() => propose(true)} disabled={acting || !selScore}>
              ⚡ Forza conferma
            </Button>
          )}
          <Button variant="primary" onClick={() => propose(false)} disabled={acting || !selScore}>
            {acting ? <Spinner size="sm" /> : '📤 Proponi'}
          </Button>
        </Modal.Footer>
      </Modal>
    </>
  );
}

// ── Standings ─────────────────────────────────────────────────────────────────
function Standings({ standings }: { standings: StandingEntry[] }) {
  const medals = ['🥇', '🥈', '🥉'];
  return (
    <div className="table-responsive">
      <Table className="standings-table" bordered size="sm">
        <thead>
          <tr>
            <th>#</th><th>Giocatore</th><th>Pt</th>
            <th>V</th><th>P</th><th>S</th>
            <th>GV</th><th>GS</th>
          </tr>
        </thead>
        <tbody>
          {standings.map((s, i) => (
            <tr key={s.reg_id} className={i < 3 ? `rank-${i+1}` : ''}>
              <td className="fw-bold">{medals[i] ?? i + 1}</td>
              <td>{s.first_name} {s.last_name}</td>
              <td className="fw-bold">{s.points}</td>
              <td>{s.wins}</td><td>{s.draws}</td><td>{s.losses}</td>
              <td>{s.games_won}</td><td>{s.games_lost}</td>
            </tr>
          ))}
        </tbody>
      </Table>
    </div>
  );
}

// ── Calendar tab ──────────────────────────────────────────────────────────────
function Calendar({
  matches, myRegId, isAdmin, onAction,
}: {
  matches: MatchResult[];
  myRegId?: number;
  isAdmin: boolean;
  onAction: () => void;
}) {
  const players = Array.from(
    new Map([
      ...matches.map(m => [m.reg1_id, `${m.reg1.first_name} ${m.reg1.last_name}`] as const),
      ...matches.map(m => [m.reg2_id, `${m.reg2.first_name} ${m.reg2.last_name}`] as const),
    ]).entries()
  );

  const [selPlayer, setSelPlayer] = useState<number | null>(myRegId ?? players[0]?.[0] ?? null);

  const playerMatches = selPlayer
    ? matches.filter(m => m.reg1_id === selPlayer || m.reg2_id === selPlayer)
    : [];

  return (
    <div>
      <div className="d-flex flex-wrap gap-2 mb-4">
        {players.map(([regId, name]) => (
          <span
            key={regId}
            className={`player-chip ${selPlayer === regId ? 'selected' : ''}`}
            onClick={() => setSelPlayer(regId)}
          >
            {name}
          </span>
        ))}
      </div>
      {selPlayer && (
        <div>
          <div className="section-heading mb-3">
            Partite — {players.find(([id]) => id === selPlayer)?.[1]}
          </div>
          {playerMatches.length === 0
            ? <p className="text-muted">Nessuna partita trovata.</p>
            : playerMatches.map(m => (
              <MatchCard key={m.id} match={m} myRegId={myRegId} isAdmin={isAdmin} onAction={onAction} />
            ))
          }
        </div>
      )}
    </div>
  );
}

// ── Admin panel (registration phase) ─────────────────────────────────────────
function AdminPanel({
  tournament, onAction,
}: {
  tournament: TDetail;
  onAction: () => void;
}) {
  const [discord, setDiscord] = useState('');
  const [firstName, setFirstName] = useState('');
  const [lastName, setLastName] = useState('');
  const [adding, setAdding] = useState(false);
  const [err, setErr] = useState('');

  async function addPlayer() {
    setAdding(true); setErr('');
    try {
      await api.adminRegister(tournament.id, { discord_account: discord, first_name: firstName, last_name: lastName });
      setDiscord(''); setFirstName(''); setLastName('');
      onAction();
    } catch (e: unknown) {
      setErr(e instanceof Error ? e.message : 'Errore');
    } finally {
      setAdding(false);
    }
  }

  async function togglePaid(reg: FullRegistration) {
    try {
      reg.paid ? await api.unmarkPaid(reg.id) : await api.markPaid(reg.id);
      onAction();
    } catch { /* */ }
  }

  async function deleteReg(regId: number) {
    if (!confirm('Eliminare questa iscrizione?')) return;
    try { await api.deleteRegistration(regId); onAction(); } catch { /* */ }
  }

  const regs = tournament.admin_registrations ?? [];

  return (
    <div className="mt-4">
      <div className="section-heading">👑 Pannello admin</div>

      <div className="form-section-card mb-3">
        <div className="form-section-title">➕ Aggiungi iscritto</div>
        {err && <Alert variant="danger" className="py-2">{err}</Alert>}
        <Row className="g-2 mb-2">
          <Col xs={12} md={4}>
            <Form.Control size="sm" placeholder="Nome" value={firstName} onChange={e => setFirstName(e.target.value)} />
          </Col>
          <Col xs={12} md={4}>
            <Form.Control size="sm" placeholder="Cognome" value={lastName} onChange={e => setLastName(e.target.value)} />
          </Col>
          <Col xs={12} md={4}>
            <Form.Control size="sm" placeholder="Discord @handle" value={discord} onChange={e => setDiscord(e.target.value)} />
          </Col>
        </Row>
        <Button size="sm" variant="primary" onClick={addPlayer} disabled={adding || !firstName || !lastName || !discord}>
          {adding ? <Spinner size="sm" /> : '➕ Aggiungi'}
        </Button>
      </div>

      <div className="table-responsive">
        <Table size="sm" bordered>
          <thead>
            <tr><th>Giocatore</th><th>Discord</th><th>Iscritto</th><th>Pagato</th><th></th></tr>
          </thead>
          <tbody>
            {regs.map(r => (
              <tr key={r.id}>
                <td className="fw-bold">{r.first_name} {r.last_name}</td>
                <td className="text-muted small">{r.discord_account}</td>
                <td className="small text-muted">{fmtDate(r.created_at)}</td>
                <td>
                  <Button
                    size="sm"
                    variant={r.paid ? 'success' : 'outline-secondary'}
                    onClick={() => togglePaid(r)}
                    style={{ minWidth: 60 }}
                  >
                    {r.paid ? '✅ Sì' : '⬜ No'}
                  </Button>
                </td>
                <td>
                  <Button size="sm" variant="outline-danger" onClick={() => deleteReg(r.id)}>🗑</Button>
                </td>
              </tr>
            ))}
          </tbody>
        </Table>
      </div>
    </div>
  );
}

// ── Main page ─────────────────────────────────────────────────────────────────
export default function TournamentDetail() {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const tournamentId = parseInt(id!);
  const { effectiveIsAdmin, user } = useSession();

  const [tournament, setTournament] = useState<TDetail | null>(null);
  const [matches, setMatches] = useState<MatchResult[]>([]);
  const [standings, setStandings] = useState<StandingEntry[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [regForm, setRegForm] = useState({ discord: '', firstName: '', lastName: '' });
  const [registering, setRegistering] = useState(false);
  const [regErr, setRegErr] = useState('');
  const [starting, setStarting] = useState(false);
  const refreshRef = useRef<ReturnType<typeof setInterval> | undefined>(undefined);

  const load = useCallback(async () => {
    try {
      const t = await api.tournament(tournamentId);
      setTournament(t);
      if (t.status !== 'registration') {
        const [m, s] = await Promise.all([
          api.matches(tournamentId),
          api.standings(tournamentId),
        ]);
        setMatches(m);
        setStandings(s);
      }
    } catch {
      setError('Impossibile caricare il torneo.');
    } finally {
      setLoading(false);
    }
  }, [tournamentId]);

  useEffect(() => {
    load();
    refreshRef.current = setInterval(load, 60_000);
    return () => clearInterval(refreshRef.current);
  }, [load]);

  async function register() {
    setRegistering(true); setRegErr('');
    try {
      await api.register(tournamentId, {
        discord_account: regForm.discord,
        first_name: regForm.firstName,
        last_name: regForm.lastName,
      });
      setRegForm({ discord: '', firstName: '', lastName: '' });
      await load();
    } catch (e: unknown) {
      setRegErr(e instanceof Error ? e.message : 'Errore iscrizione');
    } finally {
      setRegistering(false);
    }
  }

  async function cancelReg() {
    if (!confirm('Annullare la tua iscrizione?')) return;
    try { await api.cancelMyRegistration(tournamentId); await load(); } catch { /* */ }
  }

  async function startTournament() {
    if (!confirm('Avviare il torneo? Questa azione è irreversibile.')) return;
    setStarting(true);
    try { await api.startTournament(tournamentId); await load(); }
    catch (e: unknown) { setError(e instanceof Error ? e.message : 'Errore avvio'); }
    finally { setStarting(false); }
  }

  async function deleteTournament() {
    if (!confirm('Eliminare definitivamente questo torneo?')) return;
    try { await api.deleteTournament(tournamentId); navigate('/'); }
    catch (e: unknown) { setError(e instanceof Error ? e.message : 'Errore eliminazione'); }
  }

  if (loading) return (
    <Layout>
      <div className="text-center mt-5">
        <Spinner animation="border" variant="primary" style={{ width: '3rem', height: '3rem' }} />
      </div>
    </Layout>
  );

  if (!tournament || error) return (
    <Layout>
      <Container className="mt-4">
        <Alert variant="danger">{error || 'Torneo non trovato.'}</Alert>
        <Button variant="outline-primary" onClick={() => navigate('/')}>← Home</Button>
      </Container>
    </Layout>
  );

  const t = tournament;
  const { bg: statusBg, label: statusLabel } = STATUS_MAP[t.status];
  const myReg = t.my_registration;
  const myRegId = myReg?.id;
  const pct = t.cap > 0 ? Math.min(100, Math.round((t.registered_count / t.cap) * 100)) : 0;
  const full = t.registered_count >= t.cap;

  return (
    <Layout>
      {/* Hero */}
      <div className="hero-banner-sm mb-0" style={{ borderRadius: 0 }}>
        <Container fluid="xl">
          <div className="small text-white-50 mb-1">
            <Link to="/" className="text-warning text-decoration-none">← Home</Link>
          </div>
          <div className="d-flex flex-wrap justify-content-between align-items-start gap-3">
            <div>
              <h2>{t.title}</h2>
              <p className="mb-0">
                📅 {fmtDatetime(t.start_date)} → {fmtDatetime(t.end_date)}
                {t.entry_fee_eur > 0 && <span className="ms-3">💰 €{t.entry_fee_eur.toFixed(2)}</span>}
              </p>
            </div>
            <div className="d-flex flex-wrap gap-2 align-items-center">
              <span className={`badge ${statusBg}`} style={{ fontSize: '0.9rem' }}>{statusLabel}</span>
              {effectiveIsAdmin && t.status === 'registration' && (
                <>
                  <Button variant="warning" size="sm" className="fw-bold" onClick={startTournament} disabled={starting}>
                    {starting ? <Spinner size="sm" /> : '🚀 Avvia'}
                  </Button>
                  <Button variant="outline-light" size="sm"
                    onClick={() => navigate(`/admin/tournaments/${t.id}/edit`, { state: t })}>
                    ✏️
                  </Button>
                  <Button variant="outline-danger" size="sm" onClick={deleteTournament}>🗑</Button>
                </>
              )}
              {effectiveIsAdmin && t.status !== 'registration' && (
                <Button variant="outline-light" size="sm"
                  onClick={() => navigate(`/admin/tournaments/${t.id}/edit`, { state: t })}>
                  ✏️ Modifica
                </Button>
              )}
            </div>
          </div>
        </Container>
      </div>

      <Container fluid="xl" className="page-wrapper" style={{ paddingTop: '1.5rem' }}>
        {error && <Alert variant="danger">{error}</Alert>}

        {/* Registration phase */}
        {t.status === 'registration' && (
          <Row className="g-4">
            {/* Left: register / my registration */}
            <Col xs={12} md={5} lg={4}>
              {myReg ? (
                <Card className="shadow-sm mb-3">
                  <Card.Body>
                    <div className="d-flex align-items-center gap-2 mb-2">
                      <span className="fs-5">✅</span>
                      <span className="fw-bold">Sei iscritto!</span>
                    </div>
                    <p className="text-muted small mb-2">
                      {myReg.first_name} {myReg.last_name}<br />
                      {myReg.discord_account}
                    </p>
                    <div className="d-flex align-items-center gap-2 flex-wrap">
                      {myReg.paid
                        ? <Badge bg="success">💳 Pagato</Badge>
                        : t.entry_fee_eur > 0
                          ? <Badge bg="warning" text="dark">⏳ In attesa pagamento</Badge>
                          : null
                      }
                      {t.entry_fee_eur > 0 && !myReg.paid && t.paypal_link && (
                        <Button variant="warning" size="sm" href={t.paypal_link} target="_blank">
                          💳 Paga €{t.entry_fee_eur.toFixed(2)}
                        </Button>
                      )}
                    </div>
                    <div className="d-flex gap-2 mt-3 flex-wrap">
                      <Button variant="outline-primary" size="sm"
                        onClick={() => navigate(`/tournaments/${t.id}/availability`)}>
                        📅 Disponibilità
                      </Button>
                      <Button variant="outline-danger" size="sm" onClick={cancelReg}>
                        🚫 Annulla iscrizione
                      </Button>
                    </div>
                  </Card.Body>
                </Card>
              ) : (
                <Card className="shadow-sm mb-3">
                  <Card.Body>
                    <div className="fw-bold mb-3">📝 Iscriviti al torneo</div>
                    {regErr && <Alert variant="danger" className="py-2">{regErr}</Alert>}
                    {full ? (
                      <Alert variant="warning">🔒 Torneo al completo</Alert>
                    ) : !user ? (
                      <Alert variant="info">Effettua il login per iscriverti.</Alert>
                    ) : (
                      <>
                        <Form.Group className="mb-2">
                          <Form.Control size="sm" placeholder="Nome" value={regForm.firstName}
                            onChange={e => setRegForm(f => ({ ...f, firstName: e.target.value }))} />
                        </Form.Group>
                        <Form.Group className="mb-2">
                          <Form.Control size="sm" placeholder="Cognome" value={regForm.lastName}
                            onChange={e => setRegForm(f => ({ ...f, lastName: e.target.value }))} />
                        </Form.Group>
                        <Form.Group className="mb-3">
                          <Form.Control size="sm" placeholder="Account Discord (@handle)" value={regForm.discord}
                            onChange={e => setRegForm(f => ({ ...f, discord: e.target.value }))} />
                        </Form.Group>
                        <Button variant="primary" className="w-100" onClick={register}
                          disabled={registering || !regForm.firstName || !regForm.lastName || !regForm.discord}>
                          {registering ? <Spinner size="sm" /> : '✅ Iscriviti'}
                        </Button>
                      </>
                    )}
                  </Card.Body>
                </Card>
              )}

              {/* Progress */}
              <Card className="shadow-sm">
                <Card.Body>
                  <div className="d-flex justify-content-between small fw-bold mb-1">
                    <span>Iscritti</span>
                    <span className={full ? 'text-danger' : 'purple-text'}>{t.registered_count}/{t.cap}</span>
                  </div>
                  <ProgressBar now={pct} variant={full ? 'danger' : 'primary'} style={{ height: 8 }} />
                </Card.Body>
              </Card>
            </Col>

            {/* Right: players list + admin panel */}
            <Col xs={12} md={7} lg={8}>
              <div className="section-heading">👥 Iscritti ({t.registered_count})</div>
              {t.registrations.length === 0
                ? <p className="text-muted">Nessun iscritto ancora.</p>
                : <div className="d-flex flex-wrap gap-2 mb-4">
                  {t.registrations.map(r => (
                    <span key={r.id} className="player-chip" style={{ cursor: 'default' }}>
                      {r.first_name} {r.last_name}
                    </span>
                  ))}
                </div>
              }
              {t.rules_description && (
                <>
                  <div className="section-heading">📜 Regolamento</div>
                  <p className="text-muted" style={{ whiteSpace: 'pre-line' }}>{t.rules_description}</p>
                </>
              )}
              {effectiveIsAdmin && (
                <AdminPanel tournament={tournament} onAction={load} />
              )}
            </Col>
          </Row>
        )}

        {/* Ongoing / Completed: tabs */}
        {t.status !== 'registration' && (
          <Tabs defaultActiveKey="info" className="mb-4">
            <Tab eventKey="info" title="ℹ️ Info">
              <Row className="g-4">
                <Col xs={12} md={5}>
                  {t.rules_description && (
                    <>
                      <div className="section-heading">📜 Regolamento</div>
                      <p className="text-muted" style={{ whiteSpace: 'pre-line' }}>{t.rules_description}</p>
                    </>
                  )}
                  {t.prizes.length > 0 && (
                    <>
                      <div className="section-heading">🏆 Premi</div>
                      {t.prizes.map(p => (
                        <div key={p.position} className="prize-row">
                          <span>{['🥇','🥈','🥉'][p.position-1] ?? `#${p.position}`}</span>
                          <span className="fw-bold">€{p.prize_eur.toFixed(2)}</span>
                        </div>
                      ))}
                    </>
                  )}
                  <div className="mt-3">
                    <Button variant="outline-primary" size="sm"
                      as={Link as any} to={`/tournaments/${t.id}/availability`}>
                      📅 Disponibilità
                    </Button>
                  </div>
                </Col>
                <Col xs={12} md={7}>
                  <div className="section-heading">👥 Iscritti ({t.registered_count})</div>
                  <div className="d-flex flex-wrap gap-2">
                    {t.registrations.map(r => (
                      <span key={r.id} className="player-chip" style={{ cursor: 'default' }}>
                        {r.first_name} {r.last_name}
                      </span>
                    ))}
                  </div>
                  {effectiveIsAdmin && (
                    <AdminPanel tournament={tournament} onAction={load} />
                  )}
                </Col>
              </Row>
            </Tab>

            <Tab eventKey="calendar" title="📅 Calendario">
              <Calendar
                matches={matches}
                myRegId={myRegId}
                isAdmin={effectiveIsAdmin}
                onAction={load}
              />
            </Tab>

            <Tab eventKey="standings" title="🏆 Classifica">
              {standings.length === 0
                ? <p className="text-muted">Nessun dato disponibile.</p>
                : <Standings standings={standings} />
              }
            </Tab>
          </Tabs>
        )}
      </Container>
    </Layout>
  );
}
