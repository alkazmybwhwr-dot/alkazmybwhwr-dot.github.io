/* CineHub 3099 · محمّل إعلانات v2 · مفاتيح حقيقية = ظهور حقيقي = أرباح حقيقية */
(function(){
 var C=null,HOST='www.highperformanceformat.com';
 function load(cb){fetch('/ads-config.json?t='+Date.now(),{cache:'no-store'})
  .then(function(r){return r.json()}).then(function(j){C=j||{};cb()}).catch(function(){C={};cb()})}
 function scr(src){if(!src)return;var s=document.createElement('script');s.src=src;s.async=1;document.body.appendChild(s)}
 function html(h){if(!h)return;var d=document.createElement('div');d.innerHTML=h;
  Array.prototype.slice.call(d.childNodes).forEach(function(n){document.head.appendChild(n)})}
 function key(b){return b&&(b.key||b.zone||b.id)||''}
 function frame(el,k,size){if(!el||!k)return false;var p=String(size||'300x250').split('x'),
  w=+p[0]||300,h=+p[1]||250,f=document.createElement('iframe');
  f.src='//'+((C&&C.banner_host)||HOST)+'/'+k+'/invoke.html';f.width=w;f.height=h;f.scrolling='no';
  f.loading='lazy';f.setAttribute('frameborder','0');
  f.style.cssText='border:0;overflow:hidden;max-width:100%;display:block;margin:0 auto';
  el.innerHTML='';el.appendChild(f);return true}
 function ins(el,client,slot,size){if(!el||!client)return false;var p=String(size||'300x250').split('x');
  el.innerHTML='<ins class="adsbygoogle" style="display:inline-block;width:'+(+p[0]||300)+'px;height:'+(+p[1]||250)+'px" data-ad-client="'+client+'" data-ad-slot="'+(slot||'')+'"></ins>';
  try{(window.adsbygoogle=window.adsbygoogle||[]).push({})}catch(e){}
  if(!document.querySelector('script[data-adsbygoogle]')){var s=document.createElement('script');
   s.setAttribute('data-adsbygoogle','1');s.async=1;
   s.src='https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js?client='+client;document.head.appendChild(s)}return true}
 function render(){
  var cfg=C||{},B=cfg.banners||{},mob=innerWidth<620,n=0,keys=0;
  Object.keys(B).forEach(function(k){if(key(B[k]))keys++});
  if(cfg.head_html)html(cfg.head_html);
  document.querySelectorAll('[data-ad]').forEach(function(el){
   var id=el.getAttribute('data-ad'),b=B[id];if(!b){el.style.display='none';return}
   var use=(mob&&id==='top'&&key(B.mobile))?B.mobile:b;
   if(key(use)){el.style.display='';if(frame(el,key(use),use.size))n++}
   else if(cfg.adsense_client){el.style.display='';if(ins(el,cfg.adsense_client,cfg.adsense_slot,use.size))n++}
   else{el.style.display='none'}
  });
  if(mob&&cfg.sticky_mobile&&key(B.mobile)&&!document.querySelector('[data-ad="sticky"]')){
   var s=document.createElement('div');s.setAttribute('data-ad','sticky');
   s.style.cssText='position:fixed;bottom:0;left:0;right:0;z-index:9990;background:#0b1020;border-top:1px solid #1e2a44;text-align:center;padding:2px';
   document.body.appendChild(s);if(frame(s,key(B.mobile),'320x50'))n++}
  scr(cfg.popunder_src);setTimeout(function(){scr(cfg.socialbar_src)},1200);
  setTimeout(function(){scr(cfg.inpage_src)},2200);scr(cfg.monetag_src);
  if(cfg.body_html)html(cfg.body_html);
  if(cfg.direct_link)document.querySelectorAll('[data-adlink]').forEach(function(a){a.href=cfg.direct_link;a.target='_blank';a.rel='noopener'});
  if(n){localStorage.setItem('ch_impressions',(+(localStorage.getItem('ch_impressions')||0))+n);
   localStorage.setItem('ch_imp_last',Date.now());
   document.dispatchEvent(new CustomEvent('ch:impression',{detail:n}));
   if(window.CHImp){fetch((window.CHImp||'')+'',{method:'POST'}).catch(function(){})}
  }
  document.dispatchEvent(new CustomEvent('ch:ads-ready',{detail:{rendered:n,keys:keys,cfg:cfg}}));
 }
 document.readyState==='loading'?addEventListener('DOMContentLoaded',function(){load(render)}):load(render);
 window.CHAds={config:function(){return C},reload:function(){load(render)}};
})();
