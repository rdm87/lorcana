import { useEffect, useState, useCallback } from 'react';
import {
  Container, Tab, Tabs, Spinner, Alert, Button, Badge,
  Accordion, Modal,
} from 'react-bootstrap';
import { useParams } from 'react-router-dom';
import Layout from '../Layout';
import { api } from '../api';
import { useSession } from '../SessionContext';
import type { TournamentDetail, PlayerAvailability, AvailabilitySlot } from '../models';

const TIME_SLOTS = [
  { start: '00:00', end: '02:00', label: '00–02' },
  { start: '02:00', end: '04:00', label: '02–04' },
  { start: '04:00', end: '06:00', label: '04–06' },
  { start: '06:00', end: '08:00', label: '06–08' },
  { start: '08:00', end: '10:00', label: '08–10' },
  { start: '10:00', end: '12:00', label: '10–12' },
  { start: '12:00', end: '14:00', label: '12–14' },
  { start: '14:00', end: '16:00', label: '14–16' },
  { start: '16:00', end: '18:00', label: '16–18' },
  { start: '18:00', end: '20:00', label: '18–20' },
  { start: '20:00', end: '22:00', label: '20–22' },
  { start: '22:00', end: '00:00', label: '22–00' },
];

type SlotKey = string; // "YYYY-MM-DD|HH:MM"
function slotKey(date: string, start: string): SlotKey { return `${date}|${start}`; }

function getDatesInRange(startIso: string, endIso: string): string[] {
  const dates: string[] = [];
  const cur = new Date(startIso);
  cur.setHours(0, 0, 0, 0);
  const end = new Date(endIso);
  end.setHours(0, 0, 0, 0);
  while (cur <= end) {
    dates.push(cur.toISOString().slice(0, 10));
    cur.setDate(cur.getDate() + 1);
  }
  return dates;
}

function fmtDay(iso: string): string {
  return new Date(iso + 'T12:00:00').toLocaleDateString('it-IT', { weekday: 'short', day: '2-digit', month: 'short' });
}

function slotsToSet(slots: AvailabilitySlot[]): Set<SlotKey> {
  return new Set(slots.map(s => slotKey(s.slot_date, s.time_start)));
}

function setToPayload(selected: Set<SlotKey>) {
  return Array.from(selected).map(k => {
    const [date, start] = k.split('|');
    const idx = TIME_SLOTS.findIndex(s => s.start === start);
    const end = idx >= 0 ? TIME_SLOTS[idx].end : '00:00';
    return { slot_date: date, time_start: start, time_end: end };
  });
}

function SlotGrid({
  dates, selected, onToggle, onToggleDay,
}: {
  dates: string[];
  selected: Set<SlotKey>;
  onToggle: (k: SlotKey) => void;
  onToggleDay: (date: string) => void;
}) {
  return (
    <div>
      {dates.map(date => {
        const daySlots = TIME_SLOTS.map(s => slotKey(date, s.start));
        const allSelected = daySlots.every(k => selected.has(k));
        const activeCount = daySlots.filter(k => selected.has(k)).length;
        return (
          <div key={date} className="mb-3">
            <div className="d-flex align-items-center gap-2 mb-2">
              <span className="day-toggle fw-bold" onClick={() => onToggleDay(date)}>
                {fmtDay(date)}
              </span>
              {activeCount > 0 && (
                <Badge bg="primary" pill>{activeCount} fasc{activeCount === 1 ? 'ia' : 'e'}</Badge>
              )}
              {allSelected && <span className="text-success small fw-bold">✓ tutta la giornata</span>}
            </div>
            <div className="d-flex flex-wrap gap-2">
              {TIME_SLOTS.map(s => {
                const k = slotKey(date, s.start);
                return (
                  <button
                    key={k}
                    className={`slot-btn ${selected.has(k) ? 'active' : ''}`}
                    onClick={() => onToggle(k)}
                    type="button"
                  >
                    {s.label}
                  </button>
                );
              })}
            </div>
          </div>
        );
      })}
    </div>
  );
}

function AdminEditModal({
  player, dates, show, onHide, onSave,
}: {
  player: PlayerAvailability;
  dates: string[];
  show: boolean;
  onHide: () => void;
  onSave: (regId: number, selected: Set<SlotKey>) => Promise<void>;
}) {
  const [selected, setSelected] = useState<Set<SlotKey>>(new Set());
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    setSelected(slotsToSet(player.slots));
  }, [player]);

  function toggle(k: SlotKey) {
    setSelected(prev => {
      const next = new Set(prev);
      next.has(k) ? next.delete(k) : next.add(k);
      return next;
    });
  }

  function toggleDay(date: string) {
    const dayKeys = TIME_SLOTS.map(s => slotKey(date, s.start));
    const allSel = dayKeys.every(k => selected.has(k));
    setSelected(prev => {
      const next = new Set(prev);
      allSel ? dayKeys.forEach(k => next.delete(k)) : dayKeys.forEach(k => next.add(k));
      return next;
    });
  }

  async function handleSave() {
    setSaving(true);
    try { await onSave(player.reg_id, selected); onHide(); }
    finally { setSaving(false); }
  }

  return (
    <Modal show={show} onHide={onHide} size="lg">
      <Modal.Header closeButton>
        <Modal.Title>✏️ Disponibilità — {player.first_name} {player.last_name}</Modal.Title>
      </Modal.Header>
      <Modal.Body style={{ maxHeight: '65vh', overflowY: 'auto' }}>
        <SlotGrid dates={dates} selected={selected} onToggle={toggle} onToggleDay={toggleDay} />
      </Modal.Body>
      <Modal.Footer>
        <Button variant="secondary" onClick={onHide}>Annulla</Button>
        <Button variant="primary" onClick={handleSave} disabled={saving}>
          {saving ? <Spinner size="sm" /> : '💾 Salva'}
        </Button>
      </Modal.Footer>
    </Modal>
  );
}

export default function Availability() {
  const { id } = useParams<{ id: string }>();
  const tournamentId = parseInt(id!);
  const { effectiveIsAdmin } = useSession();

  const [tournament, setTournament] = useState<TournamentDetail | null>(null);
  const [allAvail, setAllAvail] = useState<PlayerAvailability[]>([]);
  const [mySelected, setMySelected] = useState<Set<SlotKey>>(new Set());
  const [dates, setDates] = useState<string[]>([]);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState('');
  const [ok, setOk] = useState('');
  const [editPlayer, setEditPlayer] = useState<PlayerAvailability | null>(null);

  const load = useCallback(async () => {
    try {
      const [t, avail] = await Promise.all([
        api.tournament(tournamentId),
        api.getAvailability(tournamentId),
      ]);
      setTournament(t);
      setAllAvail(avail);
      setDates(getDatesInRange(t.start_date, t.end_date));
      const myReg = t.my_registration;
      if (myReg) {
        const mine = avail.find(a => a.reg_id === myReg.id);
        setMySelected(slotsToSet(mine?.slots ?? []));
      }
    } catch {
      setError('Impossibile caricare le disponibilità.');
    } finally {
      setLoading(false);
    }
  }, [tournamentId]);

  useEffect(() => { load(); }, [load]);

  function toggleMine(k: SlotKey) {
    setMySelected(prev => {
      const next = new Set(prev);
      next.has(k) ? next.delete(k) : next.add(k);
      return next;
    });
  }

  function toggleDayMine(date: string) {
    const dayKeys = TIME_SLOTS.map(s => slotKey(date, s.start));
    const allSel = dayKeys.every(k => mySelected.has(k));
    setMySelected(prev => {
      const next = new Set(prev);
      allSel ? dayKeys.forEach(k => next.delete(k)) : dayKeys.forEach(k => next.add(k));
      return next;
    });
  }

  async function saveMine() {
    setSaving(true); setError(''); setOk('');
    try {
      await api.updateMyAvailability(tournamentId, setToPayload(mySelected));
      setOk('Disponibilità salvata ✓');
      await load();
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : 'Errore salvataggio');
    } finally {
      setSaving(false);
    }
  }

  async function saveAdmin(regId: number, selected: Set<SlotKey>) {
    await api.updatePlayerAvailability(tournamentId, regId, setToPayload(selected));
    await load();
  }

  const myRegId = tournament?.my_registration?.id;

  if (loading) return (
    <Layout>
      <div className="text-center mt-5"><Spinner animation="border" variant="primary" /></div>
    </Layout>
  );

  return (
    <Layout>
      <div className="hero-banner-sm mb-4">
        <Container fluid="xl">
          <h2>📅 Disponibilità — {tournament?.title}</h2>
          <p>Seleziona le fasce orarie in cui sei disponibile a giocare</p>
        </Container>
      </div>

      <Container fluid="xl" className="page-wrapper" style={{ paddingTop: 0 }}>
        {error && <Alert variant="danger" dismissible onClose={() => setError('')}>{error}</Alert>}

        <Tabs defaultActiveKey="mine" className="mb-4">
          <Tab eventKey="mine" title={`📋 Le mie disponibilità (${mySelected.size})`}>
            {!myRegId && !effectiveIsAdmin && (
              <Alert variant="warning">Non sei iscritto a questo torneo.</Alert>
            )}
            {(myRegId || effectiveIsAdmin) && (
              <>
                <SlotGrid dates={dates} selected={mySelected} onToggle={toggleMine} onToggleDay={toggleDayMine} />
                <div className="sticky-footer-bar d-flex justify-content-between align-items-center">
                  <span className="text-muted small fw-bold">{mySelected.size} fasce selezionate</span>
                  <Button variant="primary" onClick={saveMine} disabled={saving}>
                    {saving ? <Spinner size="sm" className="me-2" /> : null}
                    💾 Salva disponibilità
                  </Button>
                </div>
                {ok && <Alert variant="success" className="mt-3">{ok}</Alert>}
              </>
            )}
          </Tab>

          <Tab eventKey="all" title={`👥 Tutti i giocatori (${allAvail.length})`}>
            <Accordion flush>
              {allAvail.map(player => {
                const isMe = player.reg_id === myRegId;
                const slotCount = player.slots.length;
                return (
                  <Accordion.Item key={player.reg_id} eventKey={String(player.reg_id)}>
                    <Accordion.Header>
                      <div className="d-flex align-items-center gap-2 w-100 me-3">
                        <span className="fw-bold">
                          {player.first_name} {player.last_name}
                          {isMe && <span className="text-primary ms-1">(tu)</span>}
                        </span>
                        <Badge bg={slotCount > 0 ? 'primary' : 'secondary'} pill>
                          {slotCount} fasc{slotCount === 1 ? 'ia' : 'e'}
                        </Badge>
                        {effectiveIsAdmin && (
                          <Button
                            variant="outline-primary" size="sm" className="ms-auto"
                            onClick={e => { e.stopPropagation(); setEditPlayer(player); }}
                          >
                            ✏️
                          </Button>
                        )}
                      </div>
                    </Accordion.Header>
                    <Accordion.Body>
                      {slotCount === 0 ? (
                        <p className="text-muted small mb-0">Nessuna disponibilità inserita.</p>
                      ) : (
                        <div className="d-flex flex-wrap gap-2">
                          {player.slots.map(s => (
                            <span key={s.id} className="slot-btn active" style={{ cursor: 'default' }}>
                              {s.slot_date.slice(5)} {s.time_start.slice(0,2)}–{s.time_end.slice(0,2)}
                            </span>
                          ))}
                        </div>
                      )}
                    </Accordion.Body>
                  </Accordion.Item>
                );
              })}
            </Accordion>
          </Tab>
        </Tabs>
      </Container>

      {editPlayer && (
        <AdminEditModal
          player={editPlayer}
          dates={dates}
          show={true}
          onHide={() => setEditPlayer(null)}
          onSave={saveAdmin}
        />
      )}
    </Layout>
  );
}
