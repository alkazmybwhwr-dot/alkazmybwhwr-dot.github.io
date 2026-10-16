/* CineHub 3099 · محمّل إعلانات حقيقي — Adsterra / Monetag / أي شبكة */
(function () {
  var HOST = 'www.highperformanceformat.com', C = null;
  function load(cb){ fetch('/ads-config.json?t='+Date.now(),{cache:'no-store'}).then(function(r){return r.json()}).then(function(j){C=j;cb()}).catch(function(){C=null;cb()}); }
  function script(src){ if(!src) return; var s=document.createElement('script'); s.src=src; s.async=1; document.body.appendChild(s); }
  function frame(el,key,size){
    if(!key||!el) return;
    var p=String(size).split('x'), w=+p[0]||300, h=+p[1]||250;
    var f=document.createElement('iframe');
    f.src='//'+HOST+'/'+key+'/invoke.html';
    f.width=w; f.height=h; f.scrolling='no'; f.loading='lazy';
    f.style.cssText='border:0;overflow:hidden;max-width:100%;display:block;margin:0 auto';
    el.innerHTML=''; el.appendChild(f);
  }
  function render(){
    if(!C||!C.enabled) return;
    var mob=innerWidth<620, n=0;
    document.querySelectorAll('[data-ad]').forEach(function(el){
      var id=el.getAttribute('data-ad'), b=(C.banners||{})[id];
      if(!b) return;
      var use=(mob&&id==='top'&&(C.banners.mobile||{}).key)?C.banners.mobile:b;
      if(!use.key){ el.style.display='none'; return; }
      frame(el,use.key,use.size); n++;
    });
    if(n){ localStorage.setItem('ch_impressions',(+(localStorage.getItem('ch_impressions')||0))+n);
           document.dispatchEvent(new CustomEvent('ch:impression',{detail:n})); }
    script(C.popunder_src);
    setTimeout(function(){script(C.socialbar_src)},1500);
    if(C.direct_link) document.querySelectorAll('[data-adlink]').forEach(function(a){a.href=C.direct_link;a.target='_blank';a.rel='noopener'});
  }
  function boot(){ load(render); }
  document.readyState==='loading'?addEventListener('DOMContentLoaded',boot):boot();
})();
