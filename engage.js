(function(){var C="ch_continue";
function T(e){try{(window.CH_track||(window.abacus&&window.abacus.track)||function(){})(e)}catch(x){}}
addEventListener("DOMContentLoaded",function(){var d=(+sessionStorage.getItem("ch_depth")||0)+1;
sessionStorage.setItem("ch_depth",d);localStorage.setItem("ch_visits",(+(localStorage.getItem("ch_visits")||0))+1);T("page_view");
var t=document.querySelector("h1,.title");if(t)localStorage.setItem(C,JSON.stringify({t:t.textContent.trim().slice(0,70),u:location.pathname}));
try{var r=JSON.parse(localStorage.getItem(C)||"null");if(r&&r.u&&r.u!==location.pathname){var b=document.createElement("div");
b.style.cssText="position:fixed;left:0;right:0;bottom:0;z-index:9998;background:#0b1020ee;color:#e8f6ff;font:14px system-ui;padding:8px 12px;display:flex;gap:10px;align-items:center;border-top:1px solid #1e2a44";
b.innerHTML='<span style="opacity:.6">تابع:</span><b style="flex:1;overflow:hidden;white-space:nowrap;text-overflow:ellipsis">'+r.t+'</b><a href="'+r.u+'" style="color:#4dd0e1;font-weight:700;text-decoration:none">▶</a>';
document.body.appendChild(b);}}catch(x){}
var nx=document.querySelector('a[rel="next"],a.next,.next a');
if(nx&&nx.pathname!==location.pathname){var n=5,bx=document.createElement("div");
bx.style.cssText="position:fixed;right:12px;bottom:52px;z-index:9999;background:#0b1020ee;border:1px solid #1e2a44;color:#e8f6ff;font:13px system-ui;padding:8px 10px;border-radius:10px";
bx.innerHTML='التالي خلال <b id="chn">5</b>s · <a href="'+nx.href+'" style="color:#4dd0e1">الآن</a>';document.body.appendChild(bx);
var id=setInterval(function(){n--;var e=document.getElementById("chn");if(e)e.textContent=n;
if(n<=0){clearInterval(id);location.href=nx.href;}},1000);}
if(!window.OneSignalDeferred)return;setTimeout(function(){OneSignalDeferred.push(function(O){try{O.Slidedown.promptPush()}catch(x){}})},25000);});
if(!/\/b\//.test(location.pathname))return;var busy=0;
addEventListener("scroll",function(){if(busy)return;if(innerHeight+scrollY<document.body.scrollHeight-900)return;busy=1;
var lk=[].slice.call(document.querySelectorAll("a[href$='.html']")).map(function(a){return a.href})
.filter(function(h,i,a){return h.indexOf("/b/")>-1&&a.indexOf(h)===i});var nx=lk[Math.floor(Math.random()*Math.min(lk.length,12))];
if(!nx){busy=0;return}fetch(nx).then(function(r){return r.text()}).then(function(h){
var d=new DOMParser().parseFromString(h,"text/html"),c=d.querySelectorAll("article,.card,.poster,li");if(!c.length)return;
[].slice.call(c).slice(0,12).forEach(function(x){document.body.appendChild(x.cloneNode(true))});
if(window.CH_rescanAds)window.CH_rescanAds();T("infinite_load")}).catch(function(){}).then(function(){busy=0});},{passive:1});})();
