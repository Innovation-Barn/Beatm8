/**
 * refreshSpotifyMetadata.js
 *
 * Updates Spotify artist metrics into:
 * - artist_platform_profiles (latest snapshot)
 * - artist_metrics_history (historical log)
 *
 * Only updates artists whose updated_at is older than 5 days.
 */

import dotenv from 'dotenv';
dotenv.config();

import fetch from 'node-fetch';
import { createClient } from '@supabase/supabase-js';

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY
);

const STALE_DAYS = 5;
const BATCH_SIZE = 50;
const BATCH_DELAY_MS = 300;

// Sleep utility
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

// Get Spotify API token
async function getSpotifyToken() {
  const res = await fetch('https://accounts.spotify.com/api/token', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded',
      Authorization:
        'Basic ' +
        Buffer.from(
          `${process.env.SPOTIFY_CLIENT_ID}:${process.env.SPOTIFY_CLIENT_SECRET}`
        ).toString('base64'),
    },
    body: 'grant_type=client_credentials',
  });

  if (!res.ok) {
    const body = await res.text();
    throw new Error(`Spotify auth failed: ${res.status} – ${body}`);
  }

  const { access_token } = await res.json();
  return access_token;
}

// Get stale artists (updated_at older than 5 days)
async function getStaleArtists(cutoffIso) {
  const { data, error } = await supabase
    .from('artist_platform_profiles')
    .select('artist_id, platform_id, updated_at')
    .eq('platform', 'spotify')
    .lt('updated_at', cutoffIso);

  if (error) throw new Error(`Fetch stale artists error: ${error.message}`);
  return data;
}

// Fetch Spotify artist data
async function fetchSpotifyArtists(ids, token) {
  const url = `https://api.spotify.com/v1/artists?ids=${ids.join(',')}`;
  const res = await fetch(url, {
    headers: { Authorization: `Bearer ${token}` },
  });

  if (res.status === 429) {
    const retryAfter = parseInt(res.headers.get('retry-after') || '1', 10);
    console.warn(`Rate limited. Retry after ${retryAfter}s`);
    await sleep(retryAfter * 1000);
    return fetchSpotifyArtists(ids, token);
  }

  if (!res.ok) {
    const body = await res.text();
    throw new Error(`Spotify API error: ${res.status} – ${body}`);
  }

  const { artists } = await res.json();
  return artists;
}

// Main
(async () => {
  console.log('🚀 [refreshSpotifyMetadata] Starting');

  const token = await getSpotifyToken();
  const cutoff = new Date(Date.now() - STALE_DAYS * 86400000).toISOString();

  const stale = await getStaleArtists(cutoff);
  console.log(`📄 Found ${stale.length} stale Spotify profiles`);

  for (let i = 0; i < stale.length; i += BATCH_SIZE) {
    const chunk = stale.slice(i, i + BATCH_SIZE);
    const ids = chunk.map((r) => r.platform_id);

    console.log(`🔍 Processing ${i + 1} to ${i + chunk.length} of ${stale.length}`);

    const artists = await fetchSpotifyArtists(ids, token);
    const now = new Date().toISOString();

    for (const artist of artists) {
      const spotifyId = artist.id;
      const followers = artist.followers?.total ?? null;
      const popularity = artist.popularity ?? null;
      const url = artist.external_urls?.spotify ?? null;
      const image = artist.images?.[0]?.url ?? null;

      const match = chunk.find((r) => r.platform_id === spotifyId);
      if (!match) continue;

      const { error: updateErr } = await supabase
        .from('artist_platform_profiles')
        .update({
          followers,
          popularity,
          url,
          image_url: image,
          updated_at: now,
        })
        .eq('artist_id', match.artist_id)
        .eq('platform', 'spotify');

      if (updateErr) {
        console.error(`❌ Update failed for ${spotifyId}: ${updateErr.message}`);
        continue;
      }

      const { error: histErr } = await supabase
        .from('artist_metrics_history')
        .insert([
          {
            artist_id: match.artist_id,
            platform: 'spotify',
            metric_type: 'followers',
            metric_value: followers,
          },
          {
            artist_id: match.artist_id,
            platform: 'spotify',
            metric_type: 'popularity',
            metric_value: popularity,
          },
        ]);

      if (histErr) {
        console.error(`❌ History insert failed for ${spotifyId}: ${histErr.message}`);
      } else {
        console.log(`✅ ${spotifyId}: followers ${followers}, popularity ${popularity}`);
      }
    }

    await sleep(BATCH_DELAY_MS);
  }

  console.log('🎉 [refreshSpotifyMetadata] Complete');
  process.exit(0);
})();
