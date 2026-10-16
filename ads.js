/* CineHub 3099 · AdEngine v3 — waterfall · 14 شبكة · viewability · anti-adblock · rewarded */
(function(){
 var N=null,C=null,seen={},shown={};
 function load(cb){Promise.all([
   fetch('/networks.json?t='+Date.now(),{cache:'no-store'}).then(function(r){return r.json()}).catch(function(){return{}}),
   fetch('/ads-config.json?t='+Date.now(),{cache:'no-store'}).then(function(r){return r.json()}).catch(function(){return{}})
  ]).then(function(a){N=a[0]||{};C=a[1]||{};cb()})}
 function net(id){return (N.networks||[]).filter(function(n){return n.id===id})[0]}
 function key(n,f){return n&&n.keys&&(n.keys[f]||'')||''}
 function scr(src,attrs){if(!src)return null;var s=document.createElement('script');s.src=src;s.async=1;
  if(attrs)for(var k in attrs)s.setAttribute(k,attrs[k]);document.body.appendChild(s);return s}
 function frag(h,to){if(!h)return;var d=document.createElement('div');d.innerHTML=h;
  Array.prototype.slice.call(d.childNodes).forEach(function(n){to.appendChild(n)})}
 function iframe(el,k,size,host){if(!el||!k)return false;var p=String(size||'300x250').split('x');
  var f=document.createElement('iframe');f.src='//'+(host||'www.highperformanceformat.com')+'/'+k+'/invoke.html';
  f.width=+p[0]||300;f.height=+p[1]||250;f.scrolling='no';f.loading='lazy';f.setAttribute('frameborder','0');
  f.style.cssText='border:0;overflow:hidden;max-width:100%;display:block;margin:0 auto';
  el.innerHTML='';el.appendChild(f);return true}
 function ins(el,client,slot,size){if(!el||!client)return false;var p=String(size||'300x250').split('x');
  el.innerHTML='<ins class="adsbygoogle" style="display:inline-block;width:'+(+p[0]||300)+'px;height:'+(+p[1]||250)+'px" data-ad-client="'+client+'" data-ad-slot="'+(slot||'')+'"></ins>';
  try{(window.adsbygoogle=window.adsbygoogle||[]).push({})}catch(e){}
  if(!document.querySelector('script[data-ga]')){var s=document.createElement('script');s.setAttribute('data-ga','1');s.async=1;
   s.src='https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js?client='+client;document.head.appendChild(s)}return true}
 function render(el,slot){
  var cand=(N.slots||{})[slot]||[],mob=innerWidth<620;
  var order=mob&&slot==='top'?[['adsterra','banner_mobile']].concat(cand):cand;
  for(var i=0;i<order.length;i++){
   var n=net(order[i][0]),f=order[i][1];if(!n||!n.enabled)continue;
   if(f==='ins'){if(C.adsense_client&&ins(el,C.adsense_client,C.adsense_slot,(C.banners[slot]||{}).size))return n.id}
   var k=key(n,f);if(!k)continue;
   if(f.indexOf('banner')===0||f==='banner'){var b=(C.banners||{})[slot]||{};
    if(iframe(el,k,b.size||(n.keys['size_'+slot]||'300x250'),C.banner_host))return n.id}
  }
  return null}
 function view(el,cb){if(!('IntersectionObserver' in window))return cb();
  var o=new IntersectionObserver(function(es){es.forEach(function(e){
   if(e.intersectionRatio>=((N.viewability||{}).min_ratio||0.5)){
    setTimeout(function(){cb();o.disconnect()},(N.viewability||{}).min_ms||1000)}})},{threshold:[0.5,0.9]});o.observe(el)}
 function adblock(){
  if(!C.anti_adblock)return;
  var d=document.createElement('div');d.className='adsbox ad-placement';d.style.cssText='position:absolute;left:-9999px;height:10px;width:10px';
  d.innerHTML='&nbsp;';document.body.appendChild(d);
  setTimeout(function(){var blocked=d.offsetHeight===0;document.documentElement.setAttribute('data-adblock',blocked?'1':'0');
   if(blocked)document.dispatchEvent(new CustomEvent('ch:adblock'));},1800)}
 function pop(){
  var cap=((C.frequency_cap||{}).popunder_min||30)*60000;
  if(N.popunder&&N.popunder.enabled===false)return;
  if(Date.now()-(+(localStorage.getItem('ch_pop_ts')||0))<cap)return;
  for(var i=0;i<(N.networks||[]).length;i++){var n=N.networks[i];if(!n.enabled)continue;
   var s=key(n,'popunder')||key(n,'onclick')||key(n,'pop')||key(n,'socialbar');
   if(s){localStorage.setItem('ch_pop_ts',Date.now());scr(s);return}}
 }
 function boot(){
  load(function(){
   document.documentElement.setAttribute('data-nets',(N.networks||[]).filter(function(n){return n.enabled}).length);
   if(C.head_html)frag(C.head_html,document.head);
   if(N.rewarded&&N.rewarded.enabled)scr('/rewarded.js');
   adblock();
   var slots=[].slice.call(document.querySelectorAll('[data-ad]'));
   if(innerWidth<620&&C.sticky_mobile&&!document.querySelector('[data-ad="sticky"]')){
    var s=document.createElement('div');s.setAttribute('data-ad','sticky');
    s.style.cssText='position:fixed;bottom:0;left:0;right:0;z-index:9990;background:#0b1020;border-top:1px solid #1e2a44;text-align:center;padding:2px';
    document.body.appendChild(s);slots.push(s)}
   slots.forEach(function(el){
    var slot=el.getAttribute('data-ad');
    view(el,function(){
     var who=render(el,slot);if(!who){el.style.display='none';return}
     var k='ch_imp_'+(localStorage.getItem('ch_fp')||'x')+'_'+slot;
     var n=(+(localStorage.getItem('ch_impressions')||0))+1;localStorage.setItem('ch_impressions',n);
     localStorage.setItem('ch_imp_last',Date.now());
     document.dispatchEvent(new CustomEvent('ch:impression',{detail:1,net:who,slot:slot}));
    })});
   setTimeout(pop,2500);
   if(C.body_html)frag(C.body_html,document.body);
   document.dispatchEvent(new CustomEvent('ch:ads-ready',{detail:{nets:(N.networks||[]).filter(function(n){return n.enabled}).length}}));
  })}
 document.readyState==='loading'?addEventListener('DOMContentLoaded',boot):boot();
 window.CHAds={nets:function(){return N},cfg:function(){return C},reload:function(){load(function(){})}};
})();
