import { DateTime } from 'luxon'
import { useAccountStore } from '@/stores/account'

// Every timestamp from the API is UTC ISO 8601 (see backend
// lib/backend/time_json_format.rb) - this renders it in the account's
// configured display timezone rather than the browser's local one, so
// everyone on an account sees the same wall-clock time.
function toAccountZone(isoUtc: string): DateTime {
  const { timezone } = useAccountStore()
  return DateTime.fromISO(isoUtc, { zone: 'utc' }).setZone(timezone)
}

export function formatDateTime(isoUtc: string | null | undefined): string {
  if (!isoUtc) return '—'
  const dt = toAccountZone(isoUtc)
  return dt.isValid ? dt.toLocaleString(DateTime.DATETIME_MED) : isoUtc
}

export function formatDate(isoUtc: string | null | undefined): string {
  if (!isoUtc) return '—'
  const dt = toAccountZone(isoUtc)
  return dt.isValid ? dt.toLocaleString(DateTime.DATE_MED) : isoUtc
}

export function formatRelative(isoUtc: string | null | undefined): string {
  if (!isoUtc) return '—'
  const dt = toAccountZone(isoUtc)
  return dt.isValid ? (dt.toRelative() ?? formatDateTime(isoUtc)) : isoUtc
}
