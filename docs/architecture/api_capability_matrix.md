# API Capability Matrix

## Purpose

This document outlines the available artist-level data accessible from the public APIs (or authenticated APIs where possible) for the platforms integrated into Beatm8: **Spotify**, **Mixcloud**, **SoundCloud**, and **Apple Music**. This serves as the foundation for backend schema design, ingestion workflows, and future feature development.

---

## Capability Table

| Platform   | Metric/Attribute | Available | Description/Notes                                                                      |
|-------------|------------------|-----------|----------------------------------------------------------------------------------------|
| **Spotify** | Artist ID        | ✅        | `spotify_id` from API                                                                  |
|             | Name             | ✅        | Full artist name                                                                       |
|             | Profile URL      | ✅        | `external_urls.spotify`                                                                |
|             | Profile Image    | ✅        | Primary image URL                                                                      |
|             | Followers        | ✅        | `followers.total` — Total followers (static number)                                   |
|             | Popularity       | ✅        | 0–100 score — Opaque algorithm based on streams, recency, activity                    |
|             | Total Plays      | ❌        | Not available                                                                          |
|             | Genres           | ✅        | Array of genre strings                                                                 |
|             | Top Tracks       | ✅        | Can fetch top tracks per artist                                                        |
|             | Releases         | ✅        | Album, EP, Single discography                                                          |

---

| **Mixcloud** | Artist ID       | ✅        | `username` acts as unique ID                                                          |
|               | Name            | ✅        | Channel display name                                                                  |
|               | Profile URL     | ✅        | Mixcloud URL                                                                          |
|               | Profile Image   | ✅        | Avatar image                                                                          |
|               | Followers       | ✅        | Total followers                                                                       |
|               | Total Listens   | ✅        | Total number of listens to the entire profile                                         |
|               | Popularity      | ❌        | No popularity score                                                                   |
|               | Genres          | ❌        | Not directly provided — requires parsing from tags or not available                   |
|               | Total Cloudcasts| ✅        | Number of mixes uploaded                                                              |
|               | Plays per Cloudcast | ✅    | Available for each individual cloudcast                                               |

---

| **SoundCloud** | Artist ID      | ✅        | `permalink` or `id`                                                                   |
|                 | Name           | ✅        | Display name                                                                          |
|                 | Profile URL    | ✅        | `permalink_url`                                                                       |
|                 | Profile Image  | ✅        | Avatar                                                                                |
|                 | Followers      | ✅        | Public                                                                                |
|                 | Following      | ✅        | Public                                                                                |
|                 | Track Count    | ✅        | Total tracks uploaded                                                                 |
|                 | Plays          | ⚠️        | **✅ Only for authenticated user's tracks; ⚠️ Not publicly available for others**      |
|                 | Likes/Favorites| ✅        | Public                                                                                |
|                 | Comments       | ✅        | Public                                                                                |
|                 | Genres         | ✅        | Tags at track level — aggregation required for artist                                 |

---

| **Apple Music** | Artist ID      | ✅        | `id` from catalog API (e.g., `pl.u-xxxx`)                                             |
|                  | Name           | ✅        | Display name                                                                          |
|                  | Profile URL    | ✅        | Web link                                                                              |
|                  | Profile Image  | ✅        | Artwork                                                                               |
|                  | Followers      | ❌        | No concept of followers                                                               |
|                  | Total Plays    | ❌        | Not available                                                                         |
|                  | Popularity     | ❌        | Not available                                                                         |
|                  | Genres         | ✅        | Available from catalog API                                                            |
|                  | Releases       | ✅        | Album, EP, Single discography                                                         |

> ⚠️ Apple Music for Artists API (private) is required for any engagement, plays, or detailed metrics — not accessible without artist account credentials.

---

## Observations

- Spotify and Mixcloud expose reliable **followers**.
- Spotify is the only one with a "popularity" score (albeit opaque and internal to Spotify's ranking).
- Mixcloud uniquely offers **total listens to an artist’s channel**, not just followers.
- SoundCloud’s detailed plays data is **only available if authenticated as the artist**, otherwise inaccessible for third-party public scraping.
- Apple Music is essentially **metadata only** — no public stats on plays, listeners, or followers.

---

## Implications for Schema

1. ✅ **Artist Identity Tables**:
   - Available and consistent across all platforms.

2. ✅ **Followers Tracking**:
   - Supported on Spotify, Mixcloud, SoundCloud.
   - Not possible on Apple Music.

3. ✅ **Popularity/Ranking**:
   - Only Spotify.

4. ✅ **Listens/Plays Tracking**:
   - Mixcloud: **Yes — total listens.**
   - SoundCloud: **Conditional — only if authenticated.**
   - Spotify/Apple Music: **Not possible.**

5. ✅ **Content Asset Tracking (Optional Future)**:
   - Mixcloud: Cloudcasts.
   - Spotify/Apple: Releases/Albums/Tracks.
   - SoundCloud: Tracks.

---

## Recommendations

- Use a **flexible metric model**:
  - For example, store metrics like:
    - `metric_type` = 'followers', 'popularity', 'listens', 'track_count'
    - Value as number
    - Platform identifier

- Avoid rigid column structures assuming metrics are universally present.

---

## Next Step

→ This matrix directly feeds into the proposed SQL schema evolution and Supabase table structure.

→ Backend job scripts (`refreshSpotifyMetadata.js`, `refreshMixcloudMetadata.js`, `refreshSoundCloudMetadata.js`) will be written against this matrix.

---

## Author
Backend Ops — Beatm8 Project
