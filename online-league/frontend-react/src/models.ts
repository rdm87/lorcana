export interface AppUser {
  id: number;
  discord_id: string;
  username: string;
  avatar_url?: string;
  is_admin: boolean;
  in_server: boolean;
}

export interface PrizeEntry {
  position: number;
  prize_eur: number;
}

export type TournamentStatus = 'registration' | 'ongoing' | 'completed';

export interface Tournament {
  id: number;
  title: string;
  cap: number;
  entry_fee_eur: number;
  paypal_link: string;
  start_date: string;
  end_date: string;
  rules_description: string;
  prize_rule?: string;
  prizes: PrizeEntry[];
  registered_count: number;
  status: TournamentStatus;
}

export interface PublicRegistration {
  id: number;
  first_name: string;
  last_name: string;
  created_at: string;
}

export interface FullRegistration extends PublicRegistration {
  tournament_id: number;
  user_id?: number;
  discord_account: string;
  paid: boolean;
}

export interface TournamentDetail extends Tournament {
  registrations: PublicRegistration[];
  admin_registrations?: FullRegistration[];
  my_registration?: FullRegistration;
}

export interface MatchPlayer {
  id: number;
  first_name: string;
  last_name: string;
}

export type MatchStatus = 'pending' | 'proposed' | 'confirmed';

export interface MatchResult {
  id: number;
  tournament_id: number;
  reg1_id: number;
  reg2_id: number;
  reg1: MatchPlayer;
  reg2: MatchPlayer;
  games_reg1?: number;
  games_reg2?: number;
  proposed_by_reg_id?: number;
  result_status: MatchStatus;
}

export interface StandingEntry {
  reg_id: number;
  first_name: string;
  last_name: string;
  played: number;
  wins: number;
  draws: number;
  losses: number;
  points: number;
  games_won: number;
  games_lost: number;
}

export interface AvailabilitySlot {
  id: number;
  slot_date: string;
  time_start: string;
  time_end: string;
}

export interface PlayerAvailability {
  reg_id: number;
  first_name: string;
  last_name: string;
  slots: AvailabilitySlot[];
}

export interface BotConfig {
  guild_id?: string;
  invite_channel_id?: string;
  invite_url?: string;
  has_token: boolean;
}
