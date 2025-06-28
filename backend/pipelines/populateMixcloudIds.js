/**
 * populateMixcloudIds.js
 *
 * Looks up Mixcloud usernames for each artist in Supabase.
 * Updates mixcloud_id in artists if a clear match is found.
 * Logs duplicates and unresolved entries.
 */

import dotenv from 'dotenv';
dotenv.config();

import fetch from 'node-fetch';
import { createClient } from '@supabase/supabase-js';
import fs from 'fs';

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY
);

const MIXCLOUD_SEARCH_URL = 'https://api.mixcloud.com/search/';

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const BATCH_DELAY_MS = 500;

// ----------------------
// MAIN FUNCTION
// ----------------------
(async () => {
  console.log('🚀 Starting Mixcloud ID population...');

  // Fetch artist names from Supabase
  const { data: artists, error } = await supabase
    .from('artists')
    .select('beatm8_uuid, artist_name, mixcloud_id');

  if (error) throw error;
  console.log(`🎯 Fetched ${artists.length} artists from Supabase.`);

  const unresolved = [];
  const duplicates = [];

  for (const artist of artists) {
    const name = artist.artist_name;
    const artistId = artist.beatm8_uuid;

    console.log(`🔍 Searching Mixcloud for: "${name}"`);

    const results = await fetchMixcloudUsers(name);
    await sleep(BATCH_DELAY_MS);

    if (results.length === 0) {
      console.log(`❌ No Mixcloud user found for "${name}"`);
      unresolved.push({ artist_name: name, reason: 'No results' });
      continue;
    }

    // Filter for users who have uploaded cloudcasts
    const validResults = results.filter((r) => r.cloudcast_count > 0);

    if (validResults.length === 0) {
      console.log(`❌ No valid artist with uploads found for "${name}"`);
      unresolved.push({ artist_name: name, reason: 'No uploads' });
      continue;
    }

    if (validResults.length === 1) {
      const mixcloudId = validResults[0].username;
      console.log(`✅ Found: "${name}" → ${mixcloudId}`);

      const { error: updateError } = await supabase
        .from('artists')
        .update({ mixcloud_id: mixcloudId })
        .eq('beatm8_uuid', artistId);

      if (updateError) {
        console.error(`❌ Failed to update "${name}": ${updateError.message}`);
      }
    } else {
      console.log(`⚠️ Multiple valid results for "${name}" → ${validResults.map(r => r.username).join(', ')}`);
      duplicates.push({
        artist_name: name,
        candidates: validResults.map(r => ({
          username: r.username,
          url: r.url,
          cloudcast_count: r.cloudcast_count
        }))
      });
    }
  }

  // Write unresolved and duplicates to JSON for review
  fs.writeFileSync('./mixcloud_unresolved.json', JSON.stringify(unresolved, null, 2));
  fs.writeFileSync('./mixcloud_duplicates.json', JSON.stringify(duplicates, null, 2));

  console.log('🎉 Mixcloud ID population complete.');
  console.log(`🚫 Unresolved: ${unresolved.length}`);
  console.log(`⚠️ Duplicates: ${duplicates.length}`);
})();

// ----------------------
// MIXCLOUD API SEARCH FUNCTION
// ----------------------
async function fetchMixcloudUsers(query) {
  const url = `${MIXCLOUD_SEARCH_URL}?q=${encodeURIComponent(query)}&type=user`;
  const res = await fetch(url);

  if (!res.ok) {
    const body = await res.text();
    throw new Error(`Mixcloud search failed: ${res.status} — ${body}`);
  }

  const data = await res.json();
  return (data.data || []).map((item) => ({
    username: item.username,
    url: item.url,
    cloudcast_count: item.cloudcast_count,
    name: item.name
  }));
}
