(function(){var e=document.getElementById("ch-live");
if(!e){e=document.createElement("div");e.id="ch-live";
e.style.cssText="position:fixed;top:10px;left:10px;z-index:9997;background:#0b1020ee;border:1px solid #1e2a44;color:#9fe8ff;font:11px/1.6 system-ui;padding:6px 10px;border-radius:10px";
addEventListener("DOMContentLoaded",function(){document.body.appendChild(e)});}
function t(){var v=+(localStorage.getItem("ch_visits")||0),i=+(localStorage.getItem("ch_impressions")||0);
e.innerHTML="زيارات <b>"+v+"</b> · ظهور <b>"+i+"</b> · تقدير <b>$"+((i/1000)*1.2).toFixed(4)+"</b>";}
setInterval(t,2000);t();})();
