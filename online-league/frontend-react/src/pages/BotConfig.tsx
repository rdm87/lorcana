import { useEffect, useState } from 'react';
import { Container, Form, Button, Spinner, Alert, InputGroup } from 'react-bootstrap';
import Layout from '../Layout';
import { api } from '../api';
import type { BotConfig } from '../models';

export default function BotConfig() {
  const [cfg, setCfg] = useState<BotConfig | null>(null);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState('');
  const [ok, setOk] = useState('');

  const [guildId, setGuildId] = useState('');
  const [botToken, setBotToken] = useState('');
  const [channelId, setChannelId] = useState('');
  const [inviteUrl, setInviteUrl] = useState('');
  const [showToken, setShowToken] = useState(false);
  const [generatingInvite, setGeneratingInvite] = useState(false);

  useEffect(() => {
    api.getBotConfig()
      .then(c => {
        setCfg(c);
        setGuildId(c.guild_id ?? '');
        setChannelId(c.invite_channel_id ?? '');
        setInviteUrl(c.invite_url ?? '');
      })
      .catch(() => setError('Errore caricamento configurazione'))
      .finally(() => setLoading(false));
  }, []);

  async function save() {
    setSaving(true); setError(''); setOk('');
    try {
      const payload: Record<string, unknown> = {
        guild_id: guildId || null,
        invite_channel_id: channelId || null,
        invite_url: inviteUrl || null,
      };
      if (botToken) payload.bot_token = botToken;
      const updated = await api.saveBotConfig(payload);
      setCfg(updated);
      setBotToken('');
      setOk('Configurazione salvata ✓');
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : 'Errore salvataggio');
    } finally {
      setSaving(false);
    }
  }

  async function addBotToServer() {
    try {
      const { url } = await api.getBotOAuthUrl();
      window.open(url, '_blank');
    } catch { setError('Impossibile ottenere URL bot'); }
  }

  async function generateInvite() {
    setGeneratingInvite(true);
    try {
      const { invite_url } = await api.generateDiscordInvite();
      setInviteUrl(invite_url);
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : 'Errore generazione invite');
    } finally {
      setGeneratingInvite(false);
    }
  }

  if (loading) return (
    <Layout>
      <div className="text-center mt-5"><Spinner animation="border" variant="primary" /></div>
    </Layout>
  );

  return (
    <Layout>
      <div className="hero-banner-sm mb-4">
        <Container fluid="xl">
          <h2>🤖 Configurazione Bot Discord</h2>
        </Container>
      </div>

      <Container fluid="xl" style={{ maxWidth: 640 }}>
        {error && <Alert variant="danger" dismissible onClose={() => setError('')}>{error}</Alert>}
        {ok && <Alert variant="success" dismissible onClose={() => setOk('')}>{ok}</Alert>}

        <div className="form-section-card">
          <div className="form-section-title">🏰 Server Discord</div>
          <Form.Group className="mb-0">
            <Form.Label className="fw-bold small">Guild ID</Form.Label>
            <Form.Control placeholder="ID numerico del server Discord" value={guildId}
              onChange={e => setGuildId(e.target.value)} />
          </Form.Group>
        </div>

        <div className="form-section-card">
          <div className="form-section-title d-flex justify-content-between align-items-center">
            <span>🤖 Bot</span>
            {cfg?.has_token && <span className="badge bg-success">✓ Token configurato</span>}
          </div>
          <Form.Group className="mb-3">
            <Form.Label className="fw-bold small">Bot Token</Form.Label>
            <InputGroup>
              <Form.Control
                type={showToken ? 'text' : 'password'}
                placeholder={cfg?.has_token ? '(token esistente — lascia vuoto per non cambiarlo)' : 'Incolla il token del bot'}
                value={botToken}
                onChange={e => setBotToken(e.target.value)}
              />
              <Button variant="outline-secondary" onClick={() => setShowToken(v => !v)}>
                {showToken ? '🙈' : '👁'}
              </Button>
            </InputGroup>
          </Form.Group>
          <Form.Group className="mb-3">
            <Form.Label className="fw-bold small">Channel ID (notifiche)</Form.Label>
            <Form.Control placeholder="ID canale per i messaggi del bot" value={channelId}
              onChange={e => setChannelId(e.target.value)} />
          </Form.Group>
          {cfg?.has_token && (
            <Button variant="outline-primary" size="sm" onClick={addBotToServer}>
              ➕ Aggiungi bot al server
            </Button>
          )}
        </div>

        <div className="form-section-card">
          <div className="form-section-title">🔗 Link di invito</div>
          <Form.Group className="mb-3">
            <Form.Label className="fw-bold small">URL Invito</Form.Label>
            <InputGroup>
              <Form.Control placeholder="https://discord.gg/..." value={inviteUrl}
                onChange={e => setInviteUrl(e.target.value)} />
              <Button variant="outline-primary" onClick={generateInvite} disabled={generatingInvite}>
                {generatingInvite ? <Spinner size="sm" /> : '✨ Genera'}
              </Button>
            </InputGroup>
          </Form.Group>
        </div>

        <div className="d-flex justify-content-end">
          <Button variant="primary" onClick={save} disabled={saving} className="px-4">
            {saving ? <Spinner size="sm" className="me-2" /> : null}
            💾 Salva configurazione
          </Button>
        </div>
      </Container>
    </Layout>
  );
}
