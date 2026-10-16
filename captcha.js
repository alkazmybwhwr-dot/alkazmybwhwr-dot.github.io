/* CineHub 3099 · بوابة كابتشا — Cloudflare Turnstile */
(function(){
  var SITEKEY='1x00000000000000000000AA';
  window.CH_CAPTCHA={
    sitekey:SITEKEY, ready:false, widgetId:null,
    mount:function(sel){
      var el=typeof sel==='string'?document.querySelector(sel):sel;
      if(!el||!window.turnstile) return false;
      el.innerHTML=''; window.CH_CAPTCHA.widgetId=window.turnstile.render(el,{sitekey:SITEKEY,theme:'dark'});
      return true;
    },
    token:function(){ try{ return window.turnstile.getResponse(window.CH_CAPTCHA.widgetId)||''; }catch(e){ return ''; } },
    reset:function(){ try{ window.turnstile.reset(window.CH_CAPTCHA.widgetId); }catch(e){} }
  };
  var s=document.createElement('script');
  s.src='https://challenges.cloudflare.com/turnstile/v0/api.js?onload=chTurnstileReady';
  s.async=1; s.defer=1; document.head.appendChild(s);
  window.chTurnstileReady=function(){ window.CH_CAPTCHA.ready=true; document.dispatchEvent(new Event('ch:captcha')); };
})();
