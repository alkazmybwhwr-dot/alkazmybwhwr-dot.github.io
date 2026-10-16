const V="cinehub-v4";
const CORE=["./","./index.html","./live.js","./manifest.json","./icon.svg","./og.png","./partners.html"];
self.addEventListener("install",e=>{e.waitUntil(caches.open(V).then(c=>c.addAll(CORE)).then(()=>self.skipWaiting()));});
self.addEventListener("activate",e=>{e.waitUntil(caches.keys().then(k=>Promise.all(k.filter(x=>x!==V).map(x=>caches.delete(x)))).then(()=>self.clients.claim()));});
self.addEventListener("fetch",e=>{
  const r=e.request; if(r.method!=="GET") return;
  const u=new URL(r.url); if(u.origin!==location.origin) return;
  const isHTML = r.mode==="navigate"||u.pathname.endsWith(".html")||u.pathname.endsWith("/");
  if(isHTML){
    e.respondWith(fetch(r).then(res=>{const c=res.clone();caches.open(V).then(x=>x.put(r,c));return res;})
      .catch(()=>caches.match(r).then(m=>m||caches.match("./index.html"))));
    return;
  }
  e.respondWith(caches.match(r).then(m=>m||fetch(r).then(res=>{const c=res.clone();caches.open(V).then(x=>x.put(r,c));return res;})));
});
