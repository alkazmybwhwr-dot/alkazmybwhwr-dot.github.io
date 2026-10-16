(function(){
 function nz(id,msg){var e=document.getElementById(id);if(e&&e.textContent.trim().length<2)e.textContent=msg}
 window.addEventListener('load',function(){
  setTimeout(function(){
   var t=(document.body.innerText||'').trim();
   if(t.length<60){
    var d=document.createElement('div');
    d.style.cssText='max-width:760px;margin:24px auto;padding:18px;border:1px solid #1e2a44;border-radius:14px;font:15px system-ui';
    d.innerHTML='<h2 style="margin:0 0 8px">CineHub 3099</h2><p>تعذّر تحميل بعض الأجزاء. افتح:</p><ul>'+
     ['/cinema.html','/watch.html','/img.html','/withdraw.html'].map(function(u){return '<li><a href="'+u+'">'+u+'</a></li>'}).join('')+'</ul>';
    document.body.appendChild(d);
   }
   ['status','films','nets','kuraimi','stamp'].forEach(function(i){nz(i,'—')});
  },3000);
 });
})();
