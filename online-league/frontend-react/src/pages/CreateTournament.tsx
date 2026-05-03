import { useEffect, useState } from 'react';
import { Container, Form, Button, Spinner, Alert, Row, Col } from 'react-bootstrap';
import { useNavigate, useParams, useLocation } from 'react-router-dom';
import Layout from '../Layout';
import { api } from '../api';
import type { Tournament } from '../models';

function toLocalDatetime(iso: string): string {
  const d = new Date(iso);
  const pad = (n: number) => String(n).padStart(2, '0');
  return `${d.getFullYear()}-${pad(d.getMonth()+1)}-${pad(d.getDate())}T${pad(d.getHours())}:${pad(d.getMinutes())}`;
}

export default function CreateTournament() {
  const navigate = useNavigate();
  const { id } = useParams<{ id: string }>();
  const location = useLocation();
  const editTournament = location.state as Tournament | null;
  const isEdit = !!id;

  const [title, setTitle] = useState('');
  const [cap, setCap] = useState('8');
  const [fee, setFee] = useState('0');
  const [paypalLink, setPaypalLink] = useState('');
  const [startDate, setStartDate] = useState('');
  const [endDate, setEndDate] = useState('');
  const [rules, setRules] = useState('');
  const [prizeRule, setPrizeRule] = useState('');

  const [saving, setSaving] = useState(false);
  const [error, setError] = useState('');

  const feeNum = parseFloat(fee) || 0;

  useEffect(() => {
    if (editTournament) {
      setTitle(editTournament.title);
      setCap(String(editTournament.cap));
      setFee(String(editTournament.entry_fee_eur));
      setPaypalLink(editTournament.paypal_link ?? '');
      setStartDate(toLocalDatetime(editTournament.start_date));
      setEndDate(toLocalDatetime(editTournament.end_date));
      setRules(editTournament.rules_description ?? '');
      setPrizeRule(editTournament.prize_rule ?? '');
    }
  }, []);

  function validate(): string | null {
    if (title.trim().length < 3) return 'Il titolo deve avere almeno 3 caratteri';
    if (parseInt(cap) < 2) return 'Il cap deve essere almeno 2';
    if (!startDate) return 'Inserisci la data di inizio';
    if (!endDate) return 'Inserisci la data di fine';
    if (new Date(endDate) <= new Date(startDate)) return 'La data di fine deve essere dopo la data di inizio';
    if (feeNum > 0 && !paypalLink) return 'Inserisci il link PayPal per il pagamento';
    return null;
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    const err = validate();
    if (err) { setError(err); return; }

    setSaving(true); setError('');
    const payload = {
      title: title.trim(),
      cap: parseInt(cap),
      entry_fee_eur: feeNum,
      paypal_link: paypalLink || null,
      start_date: new Date(startDate).toISOString(),
      end_date: new Date(endDate).toISOString(),
      rules_description: rules,
      prize_rule: prizeRule || null,
    };

    try {
      if (isEdit && id) {
        await api.updateTournament(parseInt(id), payload);
        navigate(`/tournaments/${id}`);
      } else {
        const t = await api.createTournament(payload);
        navigate(`/tournaments/${t.id}`);
      }
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : 'Errore salvataggio');
      setSaving(false);
    }
  }

  return (
    <Layout>
      <div className="hero-banner-sm mb-4">
        <Container fluid="xl">
          <h2>{isEdit ? '✏️ Modifica torneo' : '➕ Nuovo torneo'}</h2>
        </Container>
      </div>

      <Container fluid="xl" style={{ maxWidth: 860 }}>
        {error && <Alert variant="danger" dismissible onClose={() => setError('')}>{error}</Alert>}

        <Form onSubmit={handleSubmit}>
          <div className="form-section-card">
            <div className="form-section-title">📋 Informazioni generali</div>
            <Form.Group className="mb-3">
              <Form.Label className="fw-bold small">Titolo del torneo</Form.Label>
              <Form.Control
                placeholder="es. Campionato Primavera 2025"
                value={title} onChange={e => setTitle(e.target.value)} required
              />
            </Form.Group>
            <Row className="g-3">
              <Col xs={12} sm={6}>
                <Form.Group>
                  <Form.Label className="fw-bold small">Cap (max iscritti)</Form.Label>
                  <Form.Control type="number" min="2" max="64" value={cap}
                    onChange={e => setCap(e.target.value)} required />
                </Form.Group>
              </Col>
              <Col xs={12} sm={6}>
                <Form.Group>
                  <Form.Label className="fw-bold small">Quota iscrizione (€)</Form.Label>
                  <Form.Control type="number" min="0" step="0.01" value={fee}
                    onChange={e => setFee(e.target.value)} />
                </Form.Group>
              </Col>
            </Row>
            {feeNum > 0 && (
              <Form.Group className="mt-3">
                <Form.Label className="fw-bold small">Link PayPal</Form.Label>
                <Form.Control type="url" placeholder="https://paypal.me/..." value={paypalLink}
                  onChange={e => setPaypalLink(e.target.value)} />
              </Form.Group>
            )}
          </div>

          <div className="form-section-card">
            <div className="form-section-title">📅 Date e orari</div>
            <Row className="g-3">
              <Col xs={12} sm={6}>
                <Form.Group>
                  <Form.Label className="fw-bold small">Data inizio</Form.Label>
                  <Form.Control type="datetime-local" value={startDate}
                    onChange={e => setStartDate(e.target.value)} required />
                </Form.Group>
              </Col>
              <Col xs={12} sm={6}>
                <Form.Group>
                  <Form.Label className="fw-bold small">Data fine</Form.Label>
                  <Form.Control type="datetime-local" value={endDate}
                    onChange={e => setEndDate(e.target.value)} required />
                </Form.Group>
              </Col>
            </Row>
          </div>

          <div className="form-section-card">
            <div className="form-section-title">📜 Regolamento</div>
            <Form.Group>
              <Form.Label className="fw-bold small">Descrizione regole</Form.Label>
              <Form.Control as="textarea" rows={5} placeholder="Descrivi le regole del torneo…"
                value={rules} onChange={e => setRules(e.target.value)} />
            </Form.Group>
          </div>

          {feeNum > 0 && (
            <div className="form-section-card">
              <div className="form-section-title">🏆 Montepremi</div>
              <Form.Group>
                <Form.Label className="fw-bold small">Regola premi (opzionale)</Form.Label>
                <Form.Control
                  placeholder="es. 60/30/10 oppure lascia vuoto per automatico"
                  value={prizeRule} onChange={e => setPrizeRule(e.target.value)}
                />
                <Form.Text className="text-muted">
                  Inserisci le percentuali separate da / (es. 60/30/10). La somma deve fare 100.
                </Form.Text>
              </Form.Group>
            </div>
          )}

          <div className="d-flex justify-content-between">
            <Button variant="outline-secondary" type="button" onClick={() => navigate(-1)}>
              ← Indietro
            </Button>
            <Button variant="primary" type="submit" disabled={saving} className="px-4">
              {saving ? <Spinner size="sm" className="me-2" /> : null}
              {isEdit ? '💾 Salva modifiche' : '🚀 Crea torneo'}
            </Button>
          </div>
        </Form>
      </Container>
    </Layout>
  );
}
