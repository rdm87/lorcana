import { useEffect, useState } from 'react';
import {
  Container, Row, Col, Card, Badge, Button, ProgressBar,
  Spinner, Modal, Form, Alert,
} from 'react-bootstrap';
import { useNavigate } from 'react-router-dom';
import Layout from '../Layout';
import { api } from '../api';
import { useSession } from '../SessionContext';
import type { Tournament } from '../models';

function fmtDate(iso: string) {
  return new Date(iso).toLocaleDateString('it-IT', { day: '2-digit', month: 'short', year: 'numeric' });
}

function StatusBadge({ status }: { status: Tournament['status'] }) {
  const map = {
    registration: { cls: 'badge-registration', label: '📋 Iscrizioni aperte' },
    ongoing:      { cls: 'badge-ongoing',      label: '⚡ In corso' },
    completed:    { cls: 'badge-completed',    label: '🏁 Concluso' },
  };
  const { cls, label } = map[status];
  return <span className={`badge ${cls} rounded-pill`}>{label}</span>;
}

function TournamentCard({ t }: { t: Tournament }) {
  const navigate = useNavigate();
  const pct = t.cap > 0 ? Math.min(100, Math.round((t.registered_count / t.cap) * 100)) : 0;
  const full = t.registered_count >= t.cap;

  return (
    <Card
      className="tournament-card h-100 shadow-sm"
      onClick={() => navigate(`/tournaments/${t.id}`)}
    >
      <Card.Body className="d-flex flex-column">
        <div className="d-flex justify-content-between align-items-start mb-2 flex-wrap gap-1">
          <StatusBadge status={t.status} />
          {t.entry_fee_eur > 0
            ? <Badge bg="warning" text="dark" className="rounded-pill">💰 €{t.entry_fee_eur.toFixed(2)}</Badge>
            : <Badge bg="success" className="rounded-pill">🎁 Gratuito</Badge>
          }
        </div>
        <Card.Title className="flex-grow-1">{t.title}</Card.Title>
        <div className="tournament-meta">
          📅 {fmtDate(t.start_date)} → {fmtDate(t.end_date)}
        </div>
        <div className="mb-1 d-flex justify-content-between small fw-bold">
          <span>Iscritti</span>
          <span className={full ? 'text-danger' : 'purple-text'}>
            {t.registered_count}/{t.cap} {full ? '🔒' : ''}
          </span>
        </div>
        <ProgressBar
          now={pct}
          variant={full ? 'danger' : 'primary'}
          className="mb-3"
          style={{ height: 8 }}
        />
        <Button variant="primary" size="sm" className="w-100">
          Dettaglio →
        </Button>
      </Card.Body>
    </Card>
  );
}

function Section({ title, items }: { title: string; items: Tournament[] }) {
  if (!items.length) return null;
  return (
    <div className="mb-5">
      <div className="section-heading">{title}</div>
      <Row className="g-3">
        {items.map(t => (
          <Col key={t.id} xs={12} md={6} lg={4}>
            <TournamentCard t={t} />
          </Col>
        ))}
      </Row>
    </div>
  );
}

export default function Home() {
  const { effectiveIsAdmin } = useSession();
  const [tournaments, setTournaments] = useState<Tournament[]>([]);
  const [loading, setLoading] = useState(true);
  const [discordUrl, setDiscordUrl] = useState<string | null>(null);
  const [error, setError] = useState('');

  const [showTest, setShowTest] = useState(false);
  const [testPlayers, setTestPlayers] = useState('4');
  const [testFee, setTestFee] = useState('0');
  const [testLoading, setTestLoading] = useState(false);
  const [testError, setTestError] = useState('');

  const navigate = useNavigate();

  async function load() {
    setLoading(true);
    try {
      const [ts, inv] = await Promise.all([
        api.tournaments(),
        api.getPublicDiscordInvite(),
      ]);
      setTournaments(ts);
      setDiscordUrl(inv);
    } catch {
      setError('Impossibile caricare i tornei. Riprova più tardi.');
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => { load(); }, []);

  async function createTest() {
    setTestLoading(true); setTestError('');
    try {
      const t = await api.generateTestTournament(parseInt(testPlayers), parseFloat(testFee));
      setShowTest(false);
      navigate(`/tournaments/${t.id}`);
    } catch (e: unknown) {
      setTestError(e instanceof Error ? e.message : 'Errore creazione');
    } finally {
      setTestLoading(false);
    }
  }

  const ongoing  = tournaments.filter(t => t.status === 'ongoing');
  const reg      = tournaments.filter(t => t.status === 'registration');
  const done     = tournaments.filter(t => t.status === 'completed');

  return (
    <Layout>
      {/* Hero */}
      <div className="hero-banner mb-4">
        <Container fluid="xl" className="d-flex flex-column flex-md-row align-items-md-center justify-content-between gap-3">
          <div>
            <h1>🎴 Lorcana Online League</h1>
            <p>La lega italiana di Disney Lorcana — torna presto per iscriverti ai tornei!</p>
          </div>
          <div className="d-flex flex-wrap gap-2">
            {discordUrl && (
              <Button variant="warning" href={discordUrl} target="_blank" rel="noreferrer" className="fw-bold">
                💬 Unisciti al Discord
              </Button>
            )}
            {effectiveIsAdmin && (
              <>
                <Button variant="light" onClick={() => navigate('/admin/tournaments/new')} className="fw-bold">
                  ➕ Nuovo torneo
                </Button>
                <Button variant="outline-light" onClick={() => setShowTest(true)} size="sm">
                  🧪 Test torneo
                </Button>
              </>
            )}
          </div>
        </Container>
      </div>

      <Container fluid="xl" className="page-wrapper" style={{ paddingTop: 0 }}>
        {error && <Alert variant="danger">{error}</Alert>}

        {loading ? (
          <div className="text-center py-5">
            <Spinner animation="border" variant="primary" style={{ width: '3rem', height: '3rem' }} />
            <p className="mt-3 fw-bold purple-text">Caricamento tornei…</p>
          </div>
        ) : (
          <>
            <Section title="⚡ In corso" items={ongoing} />
            <Section title="📋 Iscrizioni aperte" items={reg} />
            <Section title="🏁 Conclusi" items={done} />
            {!ongoing.length && !reg.length && !done.length && (
              <div className="text-center py-5">
                <div style={{ fontSize: '4rem' }}>🎴</div>
                <h4 className="dark-text mt-3">Nessun torneo disponibile</h4>
                <p className="text-muted">I tornei appariranno qui quando saranno creati.</p>
                {effectiveIsAdmin && (
                  <Button variant="primary" onClick={() => navigate('/admin/tournaments/new')}>
                    ➕ Crea il primo torneo
                  </Button>
                )}
              </div>
            )}
          </>
        )}
      </Container>

      {/* Test tournament modal */}
      <Modal show={showTest} onHide={() => setShowTest(false)} centered>
        <Modal.Header closeButton>
          <Modal.Title>🧪 Torneo di test</Modal.Title>
        </Modal.Header>
        <Modal.Body>
          {testError && <Alert variant="danger">{testError}</Alert>}
          <Form.Group className="mb-3">
            <Form.Label className="fw-bold small">Numero giocatori</Form.Label>
            <Form.Control type="number" min="2" max="16" value={testPlayers}
              onChange={e => setTestPlayers(e.target.value)} />
          </Form.Group>
          <Form.Group>
            <Form.Label className="fw-bold small">Quota iscrizione (€)</Form.Label>
            <Form.Control type="number" min="0" step="0.01" value={testFee}
              onChange={e => setTestFee(e.target.value)} />
          </Form.Group>
        </Modal.Body>
        <Modal.Footer>
          <Button variant="secondary" onClick={() => setShowTest(false)}>Annulla</Button>
          <Button variant="primary" onClick={createTest} disabled={testLoading}>
            {testLoading ? <Spinner size="sm" /> : '🚀 Crea e vai al torneo'}
          </Button>
        </Modal.Footer>
      </Modal>
    </Layout>
  );
}
