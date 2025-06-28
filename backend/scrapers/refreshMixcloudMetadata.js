/**
 * Refresh Mixcloud metadata for all tracked artists.
 * Updates artist_platform_profiles and logs to artist_metrics_history.
 */

import dotenv from 'dotenv';
dotenv.config();

import { createClient } from '@supabase/supabase-js';
import { getMixcloudProfile } from '../api/mixcloud.js';

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY
);

const STALE_DAYS = 5;
const BATCH_DELAY_MS = 300; // Delay to avoid rate limiting

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

(async () => {
  console.log('🚀 [refreshMixcloudMetadata] Starting');

  const cutoff = new Date(Date.now() - STALE_DAYS * 86400000).toISOString();

  const { data: staleProfiles, error } = await supabase
    .from('artist_platform_profiles')
    .select('artist_id, platform_id, updated_at')
    .eq('platform', 'mixcloud')
    .lt('updated_at', cutoff);

  if (error) throw error;

  console.log(`📄 Found ${staleProfiles.length} stale Mixcloud profiles`);

  for (const profile of staleProfiles) {
    const username = profile.platform_id;
    const artistId = profile.artist_id;
    const now = new Date().toISOString();

    try {
      const mixcloudData = await getMixcloudProfile(username);

      // Update platform profile
      const { error: updateError } = await supabase
        .from('artist_platform_profiles')
        .update({
          followers: mixcloudData.followers,
          url: mixcloudData.url,
          image_url: mixcloudData.image_url,
          updated_at: now
        })
        .eq('artist_id', artistId)
        .eq('platform', 'mixcloud');

      if (updateError) {
        console.error(`❌ Failed to update ${username}: ${updateError.message}`);
        continue;
      }

      // Insert metrics history
      const { error: histError } = await supabase
        .from('artist_metrics_history')
        .insert([
          {
            artist_id: artistId,
            platform: 'mixcloud',
            metric_type: 'followers',
            metric_value: mixcloudData.followers
          }
        ]);

      if (histError) {
        console.error(`❌ History insert failed for ${username}: ${histError.message}`);
      } else {
        console.log(`✅ Updated ${username}: followers ${mixcloudData.followers}`);
      }

      await sleep(BATCH_DELAY_MS);

    } catch (err) {
      console.error(`❌ Error fetching ${username}: ${err.message}`);
      await sleep(BATCH_DELAY_MS);
    }
  }

  console.log('🎉 [refreshMixcloudMetadata] Complete');
})();
