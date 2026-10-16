/* ads.js v3 — يدعم رابطًا واحدًا (main) أو شبكات متعددة */
(function(){
  var C=window.CH_ADS_CONFIG||{},D={};
  function L(s,p){if(!s||D[s])return;D[s]=1;var e=document.createElement("script");
    e.src=s;e.async=1;e.setAttribute("data-cfasync","false");(p||document.head).appendChild(e);}
  function pool(){return [C.main,C.adsterra&&C.adsterra.popunder,C.monetag&&C.monetag.vignette,
    C.propeller&&C.propeller.push,C.adcash&&C.adcash.popunder,
    C.hilltop&&C.hilltop.popunder,C.clickadu&&C.clickadu.popunder]
    .filter(Boolean).filter(function(v,i,a){return a.indexOf(v)===i});}
  addEventListener("load",function(){
    var p=pool();
    if(!p.length){console.warn("[ads] لا شبكة مُفعّلة — نفّذ: bash activate.sh");return;}
    L(p[0]); if(p[1])L(p[1]);
    if(C.adsterra&&C.adsterra.socialbar)L(C.adsterra.socialbar);
  },{once:1});
  function F(el){var k=el.getAttribute("data-ad"),
    s=(C.slots&&C.slots[k])||C.main||(C.adsterra&&C.adsterra.banner);
    if(!s||el.classList.contains("ad-filled"))return;
    el.classList.add("ad-filled");L(s,el);
    localStorage.setItem("ch_impressions",(+(localStorage.getItem("ch_impressions")||0))+1);}
  var io="IntersectionObserver"in window?new IntersectionObserver(function(es){es.forEach(function(e){
    if(e.isIntersecting){io.unobserve(e.target);F(e.target);}})},{rootMargin:"300px"}):null;
  function S(){var a=document.querySelectorAll("[data-ad]:not(.ad-filled)");
    for(var i=0;i<a.length;i++)io?io.observe(a[i]):F(a[i]);}
  document.readyState==="loading"?addEventListener("DOMContentLoaded",S):S();
  window.CH_rescanAds=S;
})();
