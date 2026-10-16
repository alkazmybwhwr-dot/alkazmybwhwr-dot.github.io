const V='ch3099-v703-1792183697';
const CORE=['/','/index.html','/manifest.json','/ads.js'];
self.addEventListener('install',e=>{self.skipWaiting();e.waitUntil(caches.open(V).then(c=>c.addAll(CORE).catch(()=>{})))});
self.addEventListener('activate',e=>{e.waitUntil(caches.keys().then(k=>Promise.all(k.filter(x=>x!==V).map(x=>caches.delete(x)))).then(()=>self.clients.claim()))});
self.addEventListener('fetch',e=>{const r=e.request;if(r.method!=='GET')return;const u=new URL(r.url);
 if(u.origin!==location.origin)return;
 const nf=/\.(json|xml|txt)$/.test(u.pathname)||r.mode==='navigate'||/\.html?$/.test(u.pathname);
 e.respondWith(caches.match(r).then(hit=>{const net=fetch(r).then(res=>{if(res&&res.status===200)caches.open(V).then(c=>c.put(r,res.clone()));return res}).catch(()=>hit);return nf?net.catch(()=>hit):(hit||net);}))});
