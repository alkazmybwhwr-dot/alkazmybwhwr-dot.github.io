(function(){
  var KEY='ch3099_earn_v2';
  function st(){try{return JSON.parse(localStorage.getItem(KEY))||{}}catch(e){return{}}}
  function sv(s){localStorage.setItem(KEY,JSON.stringify(s))}
  var cfg={rpm:1.2,split:0.7};
  fetch('/ads-config.json',{cache:'no-store'}).then(r=>r.json()).then(j=>{
    if(j.rpm_estimate_usd)cfg.rpm=j.rpm_estimate_usd;
    if(j.commission_split)cfg.split=j.commission_split.owner;
  }).catch(()=>{});
  function tick(){
    var s=st(),now=Date.now();
    s.views=(s.views||0); s.imp=(s.imp||0); s.usd=(s.usd||0); s.last=s.last||now;
    var hrs=Math.floor((now-s.last)/3600000);
    if(hrs>0){
      var imp=Math.max(1,Math.round((s.imp||1)/24));
      s.usd=+(s.usd+imp*cfg.rpm/1000*cfg.split*hrs).toFixed(6);
      s.imp+=imp; s.last+=hrs*3600000;
      s.hist=(s.hist||[]).concat([{t:new Date().toISOString(),d:imp*cfg.rpm/1000*cfg.split}]).slice(-720);
    }
    sv(s); render(s);
  }
  function render(s){
    document.querySelectorAll('[data-earn]').forEach(function(e){
      e.textContent='$'+Number(s.usd||0).toFixed(4);
    });
    document.querySelectorAll('[data-views]').forEach(function(e){e.textContent=s.views||0});
    document.querySelectorAll('[data-imp]').forEach(function(e){e.textContent=s.imp||0});
  }
  document.addEventListener('DOMContentLoaded',function(){
    var s=st(); s.views=(s.views||0)+1; s.imp=(s.imp||0)+1; s.last=s.last||Date.now(); sv(s);
    tick(); setInterval(tick,60000);
    if('Notification' in window && Notification.permission==='default'){try{Notification.requestPermission()}catch(e){}}
    if(navigator.storage&&navigator.storage.persist){try{navigator.storage.persist()}catch(e){}}
  });
  window.chEarn={state:st,tick:tick};
})();
