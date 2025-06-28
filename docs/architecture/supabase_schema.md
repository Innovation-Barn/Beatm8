# Supabase Schema — Beatm8

## 🔥 Purpose

This document describes the current database schema powering Beatm8, optimized for multi-platform artist tracking across Spotify, Mixcloud, SoundCloud, and Apple Music.

---

## 📦 Current Tables

| Table                      | Purpose                                          |
|----------------------------|---------------------------------------------------|
| `artists`                  | Master table for all tracked artists.            |
| `artist_platform_profiles` | Latest snapshot of metrics per platform.         |
| `artist_metrics_history`   | Time-series tracking of artist metrics.          |
| `edm_genres`               | Genre taxonomy with `no_go` flag control.        |
| `artist_edm_genres`        | Many-to-many link table between artists & genres.|
| `no_go_holding`            | Manual review inbox for artists flagged by genre.|

---

## 🔗 Relationships

- Each artist can have multiple platform profiles (`artist_platform_profiles`).
- Metrics snapshots feed into `artist_metrics_history` over time.
- Genres are managed via `artist_edm_genres` linking to `edm_genres`.
- `no_go_holding` is used for edge case artists for manual review.

---

## 🚀 Key Changes in `003_schema_evolution.sql`

- Dropped deprecated tables:
  - `artist_service_profiles`
  - `service_metrics_history`
- Removed legacy metrics columns from `artists`.
- Dropped obsolete trigger `trg_log_artist_metrics` and function `log_artist_metrics`.
- Added indexes for improved query performance.
- Cleaned schema for production-readiness.

---

## 🎯 How Supabase Fits Into Beatm8

- ✅ **Data Store:** Primary backend database.
- ✅ **APIs:** Supabase auto-generates APIs from this schema.
- ✅ **Backend Workflows:** Node.js scrapers (GitHub Actions) read/write to Supabase.
- ✅ **Frontend Usage:** Dashboards query `artist_platform_profiles` and `artist_metrics_history` for artist insights.

---

## 🔥 Next Steps

- Keep schema updated with future migrations (`004_schema_evolution.sql` etc.).
- Consider refactoring `spotify_genre` (currently a string field) to be managed purely via the `artist_edm_genres` table.

---

## 👷 Maintained by:
- Nuno Soares Carneiro
- Beatm8 Project
