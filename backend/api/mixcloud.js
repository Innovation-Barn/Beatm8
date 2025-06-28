import fetch from 'node-fetch';

const BASE_URL = 'https://api.mixcloud.com';

export async function getMixcloudProfile(username) {
  const url = `${BASE_URL}/${username}`;

  const res = await fetch(url);
  if (!res.ok) {
    const body = await res.text();
    throw new Error(`Mixcloud API error ${res.status}: ${body}`);
  }

  const data = await res.json();

  return {
    username: data.username,
    url: data.url,
    followers: data.follower_count,
    image_url: data.pictures?.large || null
  };
}
