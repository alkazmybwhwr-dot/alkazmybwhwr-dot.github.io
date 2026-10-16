/* مصادقة بالكابتشا-توكن: هوية دائمة موقّعة بلا بريد ولا كلمة مرور
   المبدأ: كابتشا بشرية → بصمة جهاز → توقيع محلي → توكن هوية يُخزَّن ويُزامَن */
(function(){
 var SALT='ch3099-auth-v1';
 function b64(s){return btoa(unescape(encodeURIComponent(s))).replace(/=+$/,'')}
 function sha(txt){ // SHA-256 متزامن مبسّط عبر SubtleCrypto مع بديل FNV
  return new Promise(function(res){ if(window.crypto&&crypto.subtle){
    crypto.subtle.digest('SHA-256',new TextEncoder().encode(txt)).then(function(b){
      res(Array.from(new Uint8Array(b)).map(function(x){return x.toString(16).padStart(2,'0')}).join(''))});
   }else{var h=0;for(var i=0;i<txt.length;i++)h=(h*31+txt.charCodeAt(i))|0;res('f'+Math.abs(h).toString(16))}})}
 function fp(){
  var s=localStorage.getItem('ch_fp'); if(s)return s;
  var c=document.createElement('canvas').getContext('2d');c.textBaseline='top';c.font='14px Arial';c.fillText('ch3099',2,2);
  var raw=[navigator.userAgent,navigator.language,screen.width+'x'+screen.height,new Date().getTimezoneOffset(),c.canvas.toDataURL().slice(-48)].join('|');
  var h=0;for(var i=0;i<raw.length;i++)h=((h<<5)-h+raw.charCodeAt(i))|0;
  s='F'+Math.abs(h).toString(36);localStorage.setItem('ch_fp',s);return s}
 function token(){return JSON.parse(localStorage.getItem('ch_token')||'null')}
 function valid(){
  var t=token(); if(!t)return false;
  var age=(Date.now()-(t.at||0))/86400000;
  return age < 365; // سنة، ثم تجديد بكابتشا
 }
 async function issue(providerToken){
  var t=fp(),at=Date.now();
  var sig=await sha([t,providerToken||'math',SALT,Math.floor(at/86400000)].join('|'));
  var o={id:'T'+t.slice(1,9).toUpperCase(),fp:t,provider:providerToken?'captcha':'device',
   sig:sig.slice(0,24),at:at,exp:at+365*86400000,level:providerToken?2:1};
  localStorage.setItem('ch_token',JSON.stringify(o));
  if(window.CHCloud)CHCloud.push('auth',0,'token',{id:o.id,provider:o.provider});
  document.dispatchEvent(new CustomEvent('ch:token',{detail:o}));
  return o;
 }
 async function ensure(){
  if(valid())return token();
  return null;
 }
 async function challenge(sel){
  if(!window.CHCaptcha){return null}
  var el=typeof sel==='string'?document.querySelector(sel):sel;
  if(el)CHCaptcha.mount(el);
  return new Promise(function(res){
   if(CHCaptcha.ready())return issue(CHCaptcha.token()).then(res);
   document.addEventListener('ch:captcha',function once(){document.removeEventListener('ch:captcha',once);
    CHCaptcha.verify().then(function(v){ if(v&&v.ok===false)return res(null);
     issue(CHCaptcha.token()).then(res)})});
   setTimeout(function(){ if(!CHCaptcha.ready())issue('math').then(res) },20000);
  })}
 window.CHAuth={token:token,valid:valid,issue:issue,challenge:challenge,id:function(){var t=token();return t?t.id:'anon'},
  fp:fp,level:function(){var t=token();return t?t.level:0},
  reset:function(){localStorage.removeItem('ch_token')}};
 document.addEventListener('DOMContentLoaded',function(){
  var t=token(); if(t)document.documentElement.setAttribute('data-auth',t.provider);
 });
})();
