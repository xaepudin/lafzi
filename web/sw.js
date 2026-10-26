'use strict';

// Offline support for the Lafzi web build.
//
// The app has no client-side routing, so the worker has two jobs: keep the app
// shell available, and keep the 16 MB Quran database so a reload works without
// a network. Everything is cached as the controlled page requests it — there is
// no large precache list to keep in sync with the Flutter build.
//
// Bump the cache names when the strategy itself changes; new deployments are
// detected through the ETags of main.dart.js and the database, so no manual
// version bump is needed for ordinary releases.

const STATIC_CACHE = 'lafzi-static-v1';
const DATA_CACHE = 'lafzi-data-v1';

const APP_TAG_KEY = '/__lafzi_app_tag';
const DB_TAG_KEY = '/__lafzi_db_tag';

const DB_PATH = '/assets/assets/databases/lafzi.sqlite';

// Small enough to fetch during install. Everything else is cached on demand by
// the fetch handler below.
const SHELL = [
  './',
  './index.html',
  './flutter_bootstrap.js',
  './manifest.json',
  './favicon.png',
  './icons/Icon-192.png',
  './icons/Icon-512.png',
  './icons/Icon-maskable-192.png',
  './icons/Icon-maskable-512.png',
];

self.addEventListener('install', (event) => {
  event.waitUntil((async () => {
    await precacheShell();
    await self.skipWaiting();
  })());
});

self.addEventListener('activate', (event) => {
  event.waitUntil((async () => {
    for (const key of await caches.keys()) {
      if (key !== STATIC_CACHE && key !== DATA_CACHE && key.startsWith('lafzi-')) {
        await caches.delete(key);
      }
    }
    await self.clients.claim();
  })());
});

self.addEventListener('fetch', (event) => {
  const request = event.request;
  if (request.method !== 'GET') return;

  const url = new URL(request.url);
  if (url.origin !== self.location.origin) return;

  if (request.mode === 'navigate') {
    event.respondWith(handleNavigation(request));
    // Refresh the deployment check without holding up the navigation.
    event.waitUntil(syncDeployment().catch(() => {}));
    return;
  }

  const cacheName = url.pathname.endsWith('/lafzi.sqlite')
      ? DATA_CACHE
      : STATIC_CACHE;
  event.respondWith(handleAsset(request, cacheName));
});

/// Network first, with the cached entry document as the offline fallback.
async function handleNavigation(request) {
  try {
    const response = await fetch(request);
    if (response.ok) {
      const cache = await caches.open(STATIC_CACHE);
      await cache.put('./index.html', response.clone());
    }
    return response;
  } catch (error) {
    const cache = await caches.open(STATIC_CACHE);
    const cached = (await cache.match('./index.html')) || (await cache.match('./'));
    if (cached) return cached;
    return new Response('Lafzi belum tersedia secara luring.', {
      status: 503,
      headers: {'Content-Type': 'text/plain; charset=utf-8'},
    });
  }
}

/// Cache first: assets are immutable per deployment and guarded by the ETag
/// check in [syncDeployment].
async function handleAsset(request, cacheName) {
  if (request.headers.has('range')) return fetch(request);

  const cache = await caches.open(cacheName);
  const cached = await cache.match(request);
  if (cached) return cached;

  try {
    const response = await fetch(request);
    if (isCacheable(response)) {
      await cache.put(request, response.clone());
    }
    return response;
  } catch (error) {
    return new Response('', {status: 504, statusText: 'Offline'});
  }
}

function isCacheable(response) {
  if (!response.ok || response.status !== 200) return false;
  if (response.type !== 'basic') return false;
  const cacheControl = response.headers.get('Cache-Control') || '';
  return !/no-store|private/i.test(cacheControl);
}

/// Drops the shell when main.dart.js changes, and the database when the
/// database file itself changes. HEAD requests keep the check cheap.
async function syncDeployment() {
  const appTag = await headTag('./main.dart.js');
  if (appTag) {
    const stored = await readTag(STATIC_CACHE, APP_TAG_KEY);
    if (stored !== appTag) {
      // null means this is the first run: install already cached the shell.
      if (stored !== null) {
        await caches.delete(STATIC_CACHE);
        await precacheShell();
      }
      await writeTag(STATIC_CACHE, APP_TAG_KEY, appTag);
    }
  }

  const dbTag = await headTag(DB_PATH);
  if (dbTag) {
    const stored = await readTag(DATA_CACHE, DB_TAG_KEY);
    if (stored !== dbTag) {
      if (stored !== null) await caches.delete(DATA_CACHE);
      await writeTag(DATA_CACHE, DB_TAG_KEY, dbTag);
    }
  }
}

async function precacheShell() {
  const cache = await caches.open(STATIC_CACHE);
  await Promise.all(SHELL.map(async (url) => {
    try {
      const response = await fetch(url, {cache: 'reload'});
      if (response.ok) await cache.put(url, response);
    } catch (error) {
      // Offline install: the navigation handler caches these on first load.
    }
  }));
}

async function headTag(url) {
  try {
    const response = await fetch(url, {method: 'HEAD', cache: 'no-store'});
    if (!response.ok) return null;
    return response.headers.get('etag') ||
        response.headers.get('last-modified');
  } catch (error) {
    return null;
  }
}

async function readTag(cacheName, key) {
  const cache = await caches.open(cacheName);
  const response = await cache.match(key);
  return response ? await response.text() : null;
}

async function writeTag(cacheName, key, value) {
  const cache = await caches.open(cacheName);
  await cache.put(key, new Response(value));
}
