const V="ch3099-1792157602";
const CORE=["/","/index.html","/ads.js","/manifest.json"];
self.addEventListener("install",e=>{self.skipWaiting();e.waitUntil(caches.open(V).then(c=>c.addAll(CORE).catch(()=>{})))});
self.addEventListener("activate",e=>{e.waitUntil(caches.keys().then(k=>Promise.all(k.filter(x=>x!==V).map(x=>caches.delete(x)))).then(()=>self.clients.claim()))});
self.addEventListener("fetch",e=>{const r=e.request;if(r.method!=="GET")return;
e.respondWith(caches.match(r).then(hit=>{const net=fetch(r).then(res=>{caches.open(V).then(c=>c.put(r,res.clone()));return res}).catch(()=>hit);return hit||net;}))});
