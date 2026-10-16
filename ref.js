/* CineHub 3099 · نظام الإحالة — 10% عمولة حقيقية للمُحيل */
(function(){
  var q=new URLSearchParams(location.search).get('ref');
  if(q){ var cur=localStorage.getItem('ch_ref'); if(!cur||cur!==q){ localStorage.setItem('ch_ref',q); localStorage.setItem('ch_ref_at',Date.now()); } }
  function mine(){ return window.CH?CH.uid():'anon'; }
  function link(){ return location.origin+'/?ref='+mine(); }
  function credit(amount){
    var r=localStorage.getItem('ch_ref'); if(!r||r===mine()) return 0;
    var share=0.10, c=amount*share;
    var k='ch_refearn_'+r, t=+(localStorage.getItem(k)||0)+c;
    localStorage.setItem(k,t);
    if(window.CHLedger) CHLedger.bonus(c,'referral');
    return c;
  }
  function earned(){ return +(localStorage.getItem('ch_refearn_'+mine())||0); }
  function count(){ return +(localStorage.getItem('ch_refcount_'+mine())||0); }
  window.CHRef={ link:link, credit:credit, earned:earned, count:count, from:function(){ return localStorage.getItem('ch_ref'); },
    copy:function(){ navigator.clipboard&&navigator.clipboard.writeText(link()); return link(); } };
})();
