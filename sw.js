const V='ch9-1792191793';
const CORE=['/','/index.html','/manifest.json','/theme.css','/ads.js','/owner.js'];
self.addEventListener('install',function(e){self.skipWaiting();
 e.waitUntil(caches.open(V).then(function(c){return c.addAll(CORE).catch(function(){})}))});
self.addEventListener('activate',function(e){e.waitUntil(
 caches.keys().then(function(k){return Promise.all(k.filter(function(x){return x!==V}).map(function(x){return caches.delete(x)}))})
 .then(function(){return self.clients.claim()})
 .then(function(){return self.clients.matchAll({type:'window'})})
 .then(function(cl){cl.forEach(function(c){try{c.postMessage({sw:'updated',v:V})}catch(x){}})})});
self.addEventListener('fetch',function(e){
 var r=e.request; if(r.method!=='GET')return;
 var u=new URL(r.url); if(u.origin!==location.origin)return;
 var p=u.pathname;
 if(p==='/sw.js'){ e.respondWith(fetch(r,{cache:'no-store'}).catch(function(){return caches.match(r)})); return }
 var fresh=/\.(json|xml|txt|md|jsonl)$/.test(p)||r.mode==='navigate'||/\.html?$/.test(p);
 if(fresh){ e.respondWith(fetch(r,{cache:'no-store'}).then(function(res){
    if(res&&res.status===200){var cl=res.clone();caches.open(V).then(function(c){c.put(r,cl)})}return res
  }).catch(function(){return caches.match(r)})); return }
 e.respondWith(caches.match(r).then(function(hit){return hit||fetch(r).then(function(res){
    if(res&&res.status===200){var cl=res.clone();caches.open(V).then(function(c){c.put(r,cl)})}return res})}));
});
