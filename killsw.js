/* قاتل الكاش: يشتغل مرة واحدة، يلغي كل service worker ويحذف كل الكاش، ثم يتابع بلا كسر */
(function(){
 var V='sw9';
 try{
  if(localStorage.getItem('ch_kill')!==V){
   localStorage.setItem('ch_kill',V);
   if('serviceWorker' in navigator){
    navigator.serviceWorker.getRegistrations().then(function(r){r.forEach(function(x){x.unregister()})}).catch(function(){});
   }
   if(window.caches&&caches.keys){caches.keys().then(function(k){k.forEach(function(n){caches.delete(n)})}).catch(function(){})}
  }
 }catch(e){}
 window.addEventListener('error',function(ev){
  try{var b=document.getElementById('ch-err');
   if(!b){b=document.createElement('div');b.id='ch-err';
    b.style.cssText='position:fixed;bottom:70px;left:8px;right:8px;z-index:99999;background:#7f1d1d;color:#fff;font:12px system-ui;padding:6px 10px;border-radius:8px;display:none';
    document.body&&document.body.appendChild(b)}
   if(b){b.style.display='block';b.textContent='⚠ '+(ev.message||'خطأ')}
  }catch(x){}
 });
 window.addEventListener('unhandledrejection',function(ev){
  try{var b=document.getElementById('ch-err'); if(!b)return;
   b.style.display='block'; b.textContent='⚠ '+((ev.reason&&ev.reason.message)||ev.reason)}
  catch(x){}
 });
 window.addEventListener('load',function(){
  if(!('serviceWorker' in navigator))return;
  navigator.serviceWorker.register('/sw.js',{updateViaCache:'none'}).then(function(reg){
   try{reg.update()}catch(e){}
   if(reg.waiting){try{reg.waiting.postMessage({sw:'skip'})}catch(e){}}
  }).catch(function(){});
  navigator.serviceWorker.addEventListener('message',function(m){
   if(m.data&&m.data.sw==='updated'&&!sessionStorage.getItem('ch_rl')){sessionStorage.setItem('ch_rl','1');location.reload()}
  });
 });
})();
