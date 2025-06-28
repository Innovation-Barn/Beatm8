-- 003_schema_evolution.sql
-- Beatm8 Supabase Schema Evolution — June 2025
--
-- Author: Nuno Soares Carneiro
-- Description:
-- This migration file implements the schema cleanup and finalization of the Beatm8 database.
--
-- ✔️ Drops obsolete tables, columns, triggers, and functions.
-- ✔️ Finalizes the multi-platform data model.
-- ✔️ Adds key indexes for performance.
--
-- 🔥 This file is safe to rerun. All destructive operations are guarded with IF EXISTS.

-- =====================
-- DROP OBSOLETE OBJECTS
-- =====================

-- Drop legacy tables
DROP TABLE IF EXISTS public.artist_service_profiles CASCADE;
DROP TABLE IF EXISTS public.service_metrics_history CASCADE;

-- Drop legacy columns from artists
ALTER TABLE public.artists
DROP COLUMN IF EXISTS spotify_followers_legacy,
DROP COLUMN IF EXISTS spotify_popularity_legacy,
DROP COLUMN IF EXISTS spotify_url_legacy,
DROP COLUMN IF EXISTS spotify_image_url_legacy;

-- Drop obsolete function and trigger
DROP FUNCTION IF EXISTS public.log_artist_metrics CASCADE;
DROP TRIGGER IF EXISTS trg_log_artist_metrics ON public.artists;

-- =====================
-- INDEXES FOR PERFORMANCE
-- =====================

CREATE INDEX IF NOT EXISTS idx_artist_platform_profiles_artist
ON public.artist_platform_profiles(artist_id);

CREATE INDEX IF NOT EXISTS idx_artist_platform_profiles_platform
ON public.artist_platform_profiles(platform);

CREATE INDEX IF NOT EXISTS idx_artist_metrics_history_artist
ON public.artist_metrics_history(artist_id);

CREATE INDEX IF NOT EXISTS idx_artist_metrics_history_platform
ON public.artist_metrics_history(platform);

CREATE INDEX IF NOT EXISTS idx_artist_metrics_history_recorded
ON public.artist_metrics_history(recorded_at);

-- =====================
-- CURRENT TABLE DEFINITIONS
-- =====================

-- EDM Genres Table
CREATE TABLE IF NOT EXISTS public.edm_genres (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  name text NOT NULL UNIQUE,
  no_go boolean NOT NULL DEFAULT false,
  artist_count bigint DEFAULT 0,
  CONSTRAINT edm_genres_pkey PRIMARY KEY (id)
);

-- Artists Table
CREATE TABLE IF NOT EXISTS public.artists (
  beatm8_uuid uuid NOT NULL DEFAULT gen_random_uuid(),
  artist_name text DEFAULT 'NOT NULL'::text,
  spotify_id text UNIQUE,
  spotify_href text,
  spotify_bio text,
  spotify_genre text,
  spotify_streaming numeric,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT artists_pkey PRIMARY KEY (beatm8_uuid)
);

-- Artist-Genre Link Table
CREATE TABLE IF NOT EXISTS public.artist_edm_genres (
  artist_id uuid NOT NULL,
  genre_id uuid NOT NULL,
  CONSTRAINT artist_edm_genres_pkey PRIMARY KEY (artist_id, genre_id),
  CONSTRAINT artist_edm_genres_artist_id_fkey FOREIGN KEY (artist_id) REFERENCES public.artists(beatm8_uuid),
  CONSTRAINT artist_edm_genres_genre_id_fkey FOREIGN KEY (genre_id) REFERENCES public.edm_genres(id)
);

-- Platform Profiles Table
CREATE TABLE IF NOT EXISTS public.artist_platform_profiles (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  artist_id uuid,
  platform text NOT NULL CHECK (platform = ANY (ARRAY['spotify'::text, 'mixcloud'::text, 'soundcloud'::text, 'apple_music'::text])),
  platform_id text NOT NULL,
  followers integer,
  popularity integer,
  listens integer,
  url text,
  image_url text,
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT artist_platform_profiles_pkey PRIMARY KEY (id),
  CONSTRAINT artist_platform_profiles_artist_id_fkey FOREIGN KEY (artist_id) REFERENCES public.artists(beatm8_uuid)
);

-- Metrics History Table
CREATE TABLE IF NOT EXISTS public.artist_metrics_history (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  artist_id uuid NOT NULL,
  recorded_at timestamp with time zone NOT NULL DEFAULT now(),
  platform text,
  metric_type text NOT NULL CHECK (metric_type = ANY (ARRAY['followers'::text, 'popularity'::text, 'listens'::text])),
  metric_value numeric,
  spotify_followers numeric,
  spotify_popularity numeric,
  CONSTRAINT artist_metrics_history_pkey PRIMARY KEY (id),
  CONSTRAINT artist_metrics_history_artist_id_fkey FOREIGN KEY (artist_id) REFERENCES public.artists(beatm8_uuid)
);

-- No-Go Holding Table (for manual QA)
CREATE TABLE IF NOT EXISTS public.no_go_holding (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  spotify_id text NOT NULL,
  artist_name text NOT NULL,
  genres text[] NOT NULL,
  noted_at timestamp with time zone DEFAULT now(),
  CONSTRAINT no_go_holding_pkey PRIMARY KEY (id)
);
