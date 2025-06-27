-- 001_initial.sql — Supabase Database Schema

-- 1. edm_genres
CREATE TABLE public.edm_genres (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  name text NOT NULL UNIQUE,
  no_go boolean NOT NULL DEFAULT false,
  artist_count bigint DEFAULT 0,
  CONSTRAINT edm_genres_pkey PRIMARY KEY (id)
);

-- 2. artists
CREATE TABLE public.artists (
  beatm8_uuid uuid NOT NULL DEFAULT gen_random_uuid(),
  artist_name text DEFAULT 'NOT NULL'::text,
  spotify_id text UNIQUE,
  spotify_url text,
  spotify_image_url text,
  spotify_bio text,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  spotify_followers numeric,
  spotify_popularity numeric,
  spotify_genre text,
  spotify_href text,
  spotify_streaming numeric,
  CONSTRAINT artists_pkey PRIMARY KEY (beatm8_uuid)
);

-- 3. artist_service_profiles
CREATE TABLE public.artist_service_profiles (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  artist_id uuid NOT NULL,
  service text NOT NULL,
  service_artist_id text NOT NULL,
  url text,
  image_url text,
  bio text,
  followers numeric,
  popularity numeric,
  last_synced timestamp with time zone DEFAULT now(),
  CONSTRAINT artist_service_profiles_pkey PRIMARY KEY (id)
);

-- 4. artist_edm_genres (join table)
CREATE TABLE public.artist_edm_genres (
  artist_id uuid NOT NULL,
  genre_id uuid NOT NULL,
  CONSTRAINT artist_edm_genres_pkey PRIMARY KEY (artist_id, genre_id)
);

-- 5. artist_metrics_history
CREATE TABLE public.artist_metrics_history (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  artist_id uuid NOT NULL,
  recorded_at timestamp with time zone NOT NULL DEFAULT now(),
  spotify_followers numeric,
  spotify_popularity numeric,
  CONSTRAINT artist_metrics_history_pkey PRIMARY KEY (id)
);

-- 6. service_metrics_history
CREATE TABLE public.service_metrics_history (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  profile_id uuid NOT NULL,
  recorded_at timestamp with time zone NOT NULL DEFAULT now(),
  followers numeric,
  popularity numeric,
  streaming_count numeric,
  CONSTRAINT service_metrics_history_pkey PRIMARY KEY (id)
);

-- 7. no_go_holding
CREATE TABLE public.no_go_holding (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  spotify_id text NOT NULL,
  artist_name text NOT NULL,
  genres text[] NOT NULL,
  noted_at timestamp with time zone DEFAULT now(),
  CONSTRAINT no_go_holding_pkey PRIMARY KEY (id)
);

-- 🔗 Foreign Keys
ALTER TABLE public.artist_edm_genres
ADD CONSTRAINT artist_edm_genres_artist_id_fkey
FOREIGN KEY (artist_id) REFERENCES public.artists(beatm8_uuid);

ALTER TABLE public.artist_edm_genres
ADD CONSTRAINT artist_edm_genres_genre_id_fkey
FOREIGN KEY (genre_id) REFERENCES public.edm_genres(id);

ALTER TABLE public.artist_metrics_history
ADD CONSTRAINT artist_metrics_history_artist_id_fkey
FOREIGN KEY (artist_id) REFERENCES public.artists(beatm8_uuid);

ALTER TABLE public.artist_service_profiles
ADD CONSTRAINT artist_service_profiles_artist_id_fkey
FOREIGN KEY (artist_id) REFERENCES public.artists(beatm8_uuid);

ALTER TABLE public.service_metrics_history
ADD CONSTRAINT service_metrics_history_profile_id_fkey
FOREIGN KEY (profile_id) REFERENCES public.artist_service_profiles(id);