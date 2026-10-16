/* زر عائم يوجّه لصفحة الكسب — يظهر فقط إذا فُعّلت منصّة */
(function(){
"use strict";
fetch("./surveys-config.json",{cache:"no-store"}).then(function(r){return r.json();}).then(function(c){
  if(!c||!c.provider||!c.id) return;
  var a=document.createElement("a");
  a.href="./earn.html";
  a.textContent="💰 اكسب";
  a.style.cssText="position:fixed;bottom:16px;left:16px;z-index:9998;background:linear-gradient(180deg,#22c55e,#16a34a);color:#fff;padding:11px 16px;border-radius:999px;font:700 13px system-ui;text-decoration:none;box-shadow:0 6px 20px rgba(0,0,0,.4)";
  document.body.appendChild(a);
}).catch(function(){});
})();
