// CineHub 3099 · باكند مجاني حقيقي عبر Google Apps Script
// 1) أنشئ Google Sheet جديداً  2) Extensions > Apps Script  3) الصق هذا
// 4) ضع SHEET_ID  5) Deploy > New deployment > Web app > Anyone
const SHEET_ID = 'PASTE_SHEET_ID_HERE';
const TURNSTILE_SECRET = '1x0000000000000000000000000000000AA';
function sh_(n){ const ss=SpreadsheetApp.openById(SHEET_ID); return ss.getSheetByName(n)||ss.insertSheet(n); }
function js_(o){ return ContentService.createTextOutput(JSON.stringify(o)).setMimeType(ContentService.MimeType.JSON); }
function verify_(t){
  if(!t) return true;
  try{ const r=UrlFetchApp.fetch('https://challenges.cloudflare.com/turnstile/v0/siteverify',
    {method:'post',payload:{secret:TURNSTILE_SECRET,response:t}});
    return JSON.parse(r.getContentText()).success===true; }catch(e){ return true; }
}
function doPost(e){
  const d=JSON.parse((e.postData&&e.postData.contents)||'{}');
  if(d.payload && d.payload.token && !verify_(d.payload.token)) return js_({ok:false,why:'captcha'});
  const s=sh_(d.type||'events');
  if(s.getLastRow()===0) s.appendRow(['وقت','المستخدم','المرجع','المبلغ','الوسيلة','الحساب','الحالة','خام']);
  const p=d.payload||{};
  s.appendRow([new Date(), d.uid||'', p.ref||'', p.amount||'', p.method||'', p.account||'', p.status||'', JSON.stringify(d)]);
  return js_({ok:true, ref:p.ref||''});
}
function doGet(e){
  const s=sh_((e.parameter.type)||'payouts');
  return js_({ok:true, rows:s.getDataRange().getValues()});
}
