# Mixcloud API Data Model — Beatm8

## 📘 Purpose
This document captures the data model understanding of the Mixcloud API as it applies to Beatm8. It defines how Mixcloud entities like users, cloudcasts, tags, and categories map to the Beatm8 schema and backend pipelines.

---

## 🔍 Deep Model Reasoning

| Mixcloud Entity | Definition | Beatm8 Mapping |
|-----------------|------------|-----------------|
| **User** | Represents an account on Mixcloud. A user can be:<br>• An **artist/DJ/label/radio station** (uploads cloudcasts)<br>• Or a **listener** (no uploads) | ✅ Mapped to `artists` and `artist_platform_profiles` **if and only if** the user has uploaded cloudcasts. |
| **Cloudcast** | A single show, mix, podcast, or DJ set.<br>Includes plays, tags, duration, upload date. | → Becomes part of a future `content_metrics_history` table.<br>Currently not needed for platform-level metrics like followers. |
| **Followers (User)** | Total follower count for a user profile. | ✅ Captured in `artist_platform_profiles.followers` and `artist_metrics_history`. |
| **Listens (Cloudcast)** | Only applies to individual cloudcasts — **no total listens per user.** | 🚩 If needed, a scraper would be required to sum listens across all cloudcasts for an artist. |
| **Tags (Cloudcast)** | Tags are applied to individual cloudcasts to represent genres, moods, or topics. | ✅ Possible genre feed into `edm_genres`.<br>🚩 Not linked directly to users — would require aggregation logic. |
| **Categories** | Curated top-level taxonomy from Mixcloud (e.g., `Bass`, `House`, `Jazz`). | ✅ Could be leveraged to structure `edm_genres` into a hierarchy. |

---

## 🔥 Key Insights
- A **User is an artist** if and only if `cloudcast_count > 0`.
- **Followers are available directly on the user profile.**
- **Listens must be aggregated manually from cloudcasts if desired.**
- **Genres are represented via tags attached to cloudcasts, not users.**
- **Mixcloud categories provide a higher-level genre taxonomy.**

---

## 🚩 API Limitations
- No "popularity" metric like Spotify.
- No total listens at the artist level — only per cloudcast.
- No direct genre-to-user linkage — must be inferred via tags.

---

## 🏗️ Operational Model for Beatm8
- **Mixcloud ID:** This is the **username**, which is embedded in the URL structure:  
  → `https://www.mixcloud.com/{username}/`  
  → ✅ `username` → becomes `mixcloud_id` in `artists`.
- **Search API:** Used to resolve usernames based on `artist_name`:  
  → `GET https://api.mixcloud.com/search/?q={artist_name}&type=user`
- **Verification:** Confirm `cloudcast_count > 0` to ensure it's an artist, not a listener.

---

## 🚀 Current Process Flow
1. **Input:** List of `artist_name` from Supabase.
2. **Search:** Query Mixcloud API for each name.
3. **Validate:** Ensure `cloudcast_count > 0`.
4. **Output:** Populate `mixcloud_id` directly into the `artists` table.

---

## 🔥 Next Step Opportunities
- Fetch and store Mixcloud categories for potential genre hierarchy.
- Explore optional aggregation of cloudcast listens in the future.

---

## 👷 Maintained by:
- Nuno Soares Carneiro  
- Beatm8 Project — June 2025
