-- 002_schema_evolution.sql
-- Schema evolution: Multi-platform support with no loss of existing Spotify history

-- ========== 1. ALTER artists to preserve existing metrics ==========

ALTER TABLE public.artists
RENAME COLUMN spotify_followers TO spotify_followers_legacy;

ALTER TABLE public.artists
RENAME COLUMN spotify_popularity TO spotify_popularity_legacy;

ALTER TABLE public.artists
RENAME COLUMN spotify_url TO spotify_url_legacy;

ALTER TABLE public.artists
RENAME COLUMN spotify_image_url TO spotify_image_url_legacy;

ALTER TABLE public.artists
ADD COLUMN updated_at TIMESTAMPTZ DEFAULT now();

-- ========== 2. CREATE artist_platform_profiles ==========

CREATE TABLE IF NOT EXISTS public.artist_platform_profiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  artist_id UUID REFERENCES public.artists(id) ON DELETE CASCADE,
  platform TEXT NOT NULL CHECK (platform IN ('spotify', 'mixcloud', 'soundcloud', 'apple_music')),
  platform_id TEXT NOT NULL,
  followers INTEGER,
  popularity INTEGER,
  listens INTEGER,
  url TEXT,
  image_url TEXT,
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE (artist_id, platform)
);

-- ========== 3. CREATE artist_metrics_history ==========

CREATE TABLE IF NOT EXISTS public.artist_metrics_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  artist_id UUID REFERENCES public.artists(id) ON DELETE CASCADE,
  platform TEXT NOT NULL CHECK (platform IN ('spotify', 'mixcloud', 'soundcloud', 'apple_music')),
  metric_type TEXT NOT NULL, -- 'followers', 'popularity', 'listens', etc.
  metric_value NUMERIC NOT NULL,
  recorded_at TIMESTAMPTZ DEFAULT now()
);

-- ========== 4. INDEXES FOR PERFORMANCE ==========

CREATE INDEX IF NOT EXISTS idx_artist_platform_profiles_artist
  ON public.artist_platform_profiles(artist_id);

CREATE INDEX IF NOT EXISTS idx_artist_metrics_history_artist
  ON public.artist_metrics_history(artist_id);

CREATE INDEX IF NOT EXISTS idx_artist_metrics_history_platform
  ON public.artist_metrics_history(platform);

CREATE INDEX IF NOT EXISTS idx_artist_metrics_history_recorded
  ON public.artist_metrics_history(recorded_at);

-- ✅ DONE
