/**
 * Client-side match status derivation.
 * Computes status from match_start_time / match_end_time (or start + duration)
 * purely in JavaScript — no server cron needed.
 *
 * Rules (mirrors the old server-side logic):
 * - manual_status_override = true → keep stored status
 * - abandoned / postponed → keep stored status
 * - Test format matches are never auto-completed by time
 * - past end time (or start + duration) → completed
 * - past start time → live
 * - otherwise → upcoming
 */

export type DerivedStatus = 'upcoming' | 'live' | 'completed' | 'abandoned' | 'postponed';

interface MatchLike {
  status: string;
  manual_status_override?: boolean | null;
  match_format?: string | null;
  match_start_time?: string | null;
  match_end_time?: string | null;
  match_duration_minutes?: number | null;
  match_date?: string | null;
  match_time?: string | null;
}

function defaultDuration(match: MatchLike & { sport?: { name?: string } | null }): number | null {
  const fmt = (match.match_format || '').toLowerCase();
  if (fmt === 'test') return null;
  if (fmt.includes('t20') || fmt.includes('t10')) return 240;
  if (fmt.includes('odi') || fmt.includes('list')) return 600;
  const sport = (match.sport?.name || '').toLowerCase();
  if (sport.includes('football') || sport.includes('soccer')) return 120;
  return null;
}

export function deriveMatchStatus<T extends MatchLike>(match: T, now: Date = new Date()): T {
  // Respect manual overrides and terminal statuses
  if (match.manual_status_override) return match;
  if (match.status === 'abandoned' || match.status === 'postponed') return match;

  const isTest = match.match_format?.toLowerCase() === 'test';

  // Determine start time: explicit match_start_time, else match_date + match_time
  let startTime: Date | null = null;
  if (match.match_start_time) {
    startTime = new Date(match.match_start_time);
  } else if (match.match_date && match.match_time) {
    startTime = new Date(`${match.match_date}T${match.match_time}`);
  }

  // Determine end time: explicit match_end_time, else start + duration (explicit or default)
  let endTime: Date | null = null;
  const duration = match.match_duration_minutes || defaultDuration(match);
  if (match.match_end_time) {
    endTime = new Date(match.match_end_time);
  } else if (startTime && duration) {
    endTime = new Date(startTime.getTime() + duration * 60 * 1000);
  }

  let derived: DerivedStatus = match.status as DerivedStatus;

  // Auto-complete (never for Test matches)
  if (!isTest && endTime && now >= endTime) {
    derived = 'completed';
  } else if (startTime && now >= startTime) {
    derived = 'live';
  } else {
    derived = 'upcoming';
  }

  if (derived === match.status) return match;
  return { ...match, status: derived };
}

export function deriveMatchesStatus<T extends MatchLike>(matches: T[] | null | undefined): T[] {
  if (!matches) return [];
  const now = new Date();
  return matches.map((m) => deriveMatchStatus(m, now));
}
