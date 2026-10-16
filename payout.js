(function(){
  var EP = localStorage.getItem('ch_endpoint') || 'https://script.google.com/macros/s/..../exec';
  function ref(){ var d=new Date(); return 'KW-'+d.getFullYear()+('0'+(d.getMonth()+1)).slice(-2)+('0'+d.getDate()).slice(-2)+'-'+Math.random().toString(36).slice(2,6).toUpperCase(); }
  function list(){ try{ return JSON.parse(localStorage.getItem('ch_payouts')||'[]'); }catch(e){ return []; } }
  function save(a){ localStorage.setItem('ch_payouts',JSON.stringify(a)); }
  window.CHPayout={
    min:5,
    balance:function(){ return window.CHLedger?CHLedger.balance():0; },
    list:list,
    request:async function(o){
      var b=window.CHLedger.balance();
      if(b<5) return {ok:false,why:'الحد الأدنى $5 — رصيدك $'+b.toFixed(4)};
      var r={ ref:ref(), uid:window.CH.uid(), method:o.method, amount:+b.toFixed(4),
              account:o.account, name:o.name, at:new Date().toISOString(), status:'pending',
              token: window.CH_CAPTCHA?CH_CAPTCHA.token():'' };
      var a=list(); a.unshift(r); save(a);
      if(window.CHLedger) CHLedger.pay(r.amount);
      if(EP){ try{ await fetch(EP,{method:'POST',mode:'no-cors',headers:{'Content-Type':'text/plain'},
        body:JSON.stringify({type:'payouts',uid:r.uid,payload:r})}); }catch(e){} }
      return {ok:true,req:r};
    }
  };
})();
