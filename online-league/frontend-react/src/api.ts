import type {
  AppUser, Tournament, TournamentDetail, FullRegistration,
  MatchResult, StandingEntry, PlayerAvailability, BotConfig,
} from './models';

// In prod (build senza VITE_API_BASE_URL) usa URL relative → nginx proxy su stessa porta.
// In locale crea frontend-react/.env.local con VITE_API_BASE_URL=http://localhost:9000
const API_BASE: string = (import.meta.env.VITE_API_BASE_URL as string) || '';
export const TOKEN_KEY = 'lorcana_token';

export function getToken(): string | null { return localStorage.getItem(TOKEN_KEY); }
export function setToken(t: string): void  { localStorage.setItem(TOKEN_KEY, t); }
export function clearToken(): void          { localStorage.removeItem(TOKEN_KEY); }

async function req<T>(
  method: string,
  path: string,
  body?: unknown,
  auth = true,
): Promise<T> {
  const headers: Record<string, string> = { 'Content-Type': 'application/json' };
  if (auth) {
    const tok = getToken();
    if (tok) headers['Authorization'] = `Bearer ${tok}`;
  }
  const res = await fetch(`${API_BASE}${path}`, {
    method,
    headers,
    body: body !== undefined ? JSON.stringify(body) : undefined,
  });
  if (!res.ok) {
    let detail = `Errore ${res.status}`;
    try { const e = await res.json(); detail = e.detail ?? detail; } catch { /* */ }
    throw new Error(detail);
  }
  if (res.status === 204) return undefined as T;
  return res.json() as Promise<T>;
}

// ── Auth ──────────────────────────────────────────────────────────────────────
export const api = {
  loginUrl: `${API_BASE}/api/auth/discord/login`,

  me: () => req<AppUser>('GET', '/api/me'),

  // ── Tournaments ────────────────────────────────────────────────────────────
  tournaments: () => req<Tournament[]>('GET', '/api/tournaments', undefined, false),

  tournament: (id: number) => req<TournamentDetail>('GET', `/api/tournaments/${id}`),

  createTournament: (payload: Record<string, unknown>) =>
    req<Tournament>('POST', '/api/tournaments', payload),

  updateTournament: (id: number, payload: Record<string, unknown>) =>
    req<Tournament>('PUT', `/api/tournaments/${id}`, payload),

  startTournament: (id: number) =>
    req<Tournament>('POST', `/api/tournaments/${id}/start`),

  deleteTournament: (id: number) =>
    req<void>('DELETE', `/api/tournaments/${id}`),

  generateTestTournament: (playerCount: number, entryFeeEur: number) =>
    req<Tournament>('POST', '/api/admin/test-tournament', { player_count: playerCount, entry_fee_eur: entryFeeEur }),

  // ── Registrations (user) ───────────────────────────────────────────────────
  register: (tournamentId: number, payload: { discord_account: string; first_name: string; last_name: string }) =>
    req<FullRegistration>('POST', `/api/tournaments/${tournamentId}/register`, payload),

  cancelMyRegistration: (tournamentId: number) =>
    req<void>('DELETE', `/api/tournaments/${tournamentId}/registration/me`),

  // ── Registrations (admin) ─────────────────────────────────────────────────
  adminRegister: (tournamentId: number, payload: { discord_account: string; first_name: string; last_name: string }) =>
    req<FullRegistration>('POST', `/api/tournaments/${tournamentId}/admin/register`, payload),

  deleteRegistration: (regId: number) =>
    req<void>('DELETE', `/api/registrations/${regId}`),

  markPaid: (regId: number) =>
    req<FullRegistration>('POST', `/api/registrations/${regId}/paid`),

  unmarkPaid: (regId: number) =>
    req<FullRegistration>('DELETE', `/api/registrations/${regId}/paid`),

  // ── Matches ───────────────────────────────────────────────────────────────
  matches: (tournamentId: number) =>
    req<MatchResult[]>('GET', `/api/tournaments/${tournamentId}/matches`),

  standings: (tournamentId: number) =>
    req<StandingEntry[]>('GET', `/api/tournaments/${tournamentId}/standings`),

  proposeResult: (matchId: number, gamesReg1: number, gamesReg2: number, forceConfirm = false) =>
    req<MatchResult>('POST', `/api/matches/${matchId}/result`, {
      games_reg1: gamesReg1, games_reg2: gamesReg2, force_confirm: forceConfirm,
    }),

  confirmResult: (matchId: number) =>
    req<MatchResult>('POST', `/api/matches/${matchId}/confirm`),

  resetResult: (matchId: number) =>
    req<MatchResult>('DELETE', `/api/matches/${matchId}/result`),

  // ── Availability ──────────────────────────────────────────────────────────
  getAvailability: (tournamentId: number) =>
    req<PlayerAvailability[]>('GET', `/api/tournaments/${tournamentId}/availability`),

  updateMyAvailability: (tournamentId: number, slots: { slot_date: string; time_start: string; time_end: string }[]) =>
    req<unknown>('PUT', `/api/tournaments/${tournamentId}/availability/me`, { slots }),

  updatePlayerAvailability: (tournamentId: number, regId: number, slots: { slot_date: string; time_start: string; time_end: string }[]) =>
    req<unknown>('PUT', `/api/tournaments/${tournamentId}/availability/${regId}`, { slots }),

  // ── Bot / Discord ─────────────────────────────────────────────────────────
  getPublicDiscordInvite: async (): Promise<string | null> => {
    try {
      const r = await req<{ invite_url: string | null }>('GET', '/api/discord/public-invite', undefined, false);
      return r.invite_url ?? null;
    } catch { return null; }
  },

  getBotConfig: () => req<BotConfig>('GET', '/api/admin/bot-config'),

  saveBotConfig: (payload: Record<string, unknown>) =>
    req<BotConfig>('PUT', '/api/admin/bot-config', payload),

  getBotOAuthUrl: () => req<{ url: string }>('GET', '/api/admin/bot-config/bot-oauth-url'),

  generateDiscordInvite: () => req<{ invite_url: string }>('POST', '/api/admin/bot-config/generate-invite'),
};
