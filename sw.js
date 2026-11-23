// Block City Blasters service worker: always try the newest game first, fall back to the saved copy when offline
const C='bcb-v1';
self.addEventListener('install',e=>{self.skipWaiting();e.waitUntil(caches.open(C).then(c=>c.addAll(['/','/icon-192.png','/icon-512.png','/manifest.webmanifest'])).catch(()=>{}));});
self.addEventListener('activate',e=>e.waitUntil(self.clients.claim()));
self.addEventListener('fetch',e=>{const r=e.request;if(r.method!=='GET')return;const u=new URL(r.url);
  if(r.mode==='navigate'){e.respondWith(fetch(r).then(res=>{const cp=res.clone();caches.open(C).then(c=>c.put('/',cp));return res;}).catch(()=>caches.match('/')));return;}
  if(u.origin===location.origin||u.hostname==='cdnjs.cloudflare.com'||u.hostname==='cdn.jsdelivr.net'){e.respondWith(fetch(r).then(res=>{if(res.ok){const cp=res.clone();caches.open(C).then(c=>c.put(r,cp));}return res;}).catch(()=>caches.match(r)));}
});
