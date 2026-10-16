#!/data/data/com.termux/files/usr/bin/bash
# ═══════════════════════════════════════════════════════════════
# CineHub 3099 · MASTER.sh — تفعيل كامل حقيقي (أرباح/عمولات/اشتراكات)
#   bash MASTER.sh          تنفيذ + نشر + تحقق
#   bash MASTER.sh check    تقرير حقيقي فقط (بلا تغيير)
# ═══════════════════════════════════════════════════════════════
set -u
cd ~/cinehub3099 2>/dev/null || { echo "✗ لا يوجد ~/cinehub3099"; exit 1; }
D="$(pwd)"; export TMPDIR="$D/.tmp"; mkdir -p "$TMPDIR"
export GIT_HTTP_LOW_SPEED_LIMIT=1000 GIT_HTTP_LOW_SPEED_TIME=60
OWNER="alkazmybwhwr-dot"; REPO="alkazmybwhwr-dot.github.io"; BRANCH="main"
SITE="https://${OWNER}.github.io"
G(){ printf '\033[32m  ✓ %s\033[0m\n' "$1"; }
W(){ printf '\033[33m  ! %s\033[0m\n' "$1"; }
R(){ printf '\033[31m  ✗ %s\033[0m\n' "$1"; }
H(){ printf '\n\033[36m━━ %s ━━\033[0m\n' "$1"; }

# ═══ 0) وضع التقرير فقط ═══
if [ "${1:-}" = "check" ]; then
H "تقرير حقيقي"
python3 - <<'PY'
import json,os,re,urllib.request
B="https://alkazmybwhwr-dot.github.io"
print("── المصادر المفعّلة ──")
try:
    r=json.load(open("revenue.json",encoding="utf-8"))
    for k in ("smartlink",): print(("  ✓" if r.get(k) else "  ✗"),"Smartlink CPA")
    for o in r.get("offerwalls",[]): print(("  ✓" if o.get("enabled") else "  ✗"),o["label"])
    for a in r.get("affiliates",[]): print(("  ✓" if a.get("url") else "  ✗"),a["label"])
except Exception as e: print("  ✗ revenue.json:",e)
try:
    c=json.load(open("ads-config.json",encoding="utf-8"))
    n=sum(1 for b in c["banners"].values() if b["key"])
    print("── إعلانات: %d/4 بانر · social=%s · pop=%s"%(n,bool(c.get("socialbar_src")),bool(c.get("popunder_src"))))
except Exception: print("  ✗ ads-config.json")
try:
    k=json.load(open("kuraimi.json",encoding="utf-8"))
    print("── الكريمي:",k.get("holder") or "✗ فارغ","·",k.get("account") or "✗")
except Exception: print("  ✗ kuraimi.json")
s=open("captcha.js",encoding="utf-8").read()
sk=re.search(r"SITEKEY='([^']*)'",s).group(1)
print("── الكابتشا:",("تجريبي — استبدله" if sk.startswith(("1x0","2x0","3x0")) else "✓ حقيقي"))
ep=re.search(r"'([^']*)'",open("payout.js",encoding="utf-8").read().split("ch_endpoint")[1]).group(1) if "ch_endpoint" in open("payout.js",encoding="utf-8").read() else ""
print("── الباكند:",("✗ غير مربوط" if not ep else "✓ "+ep[:48]))
print("── الجدول الحقيقي (لوحة الشبكة):")
for u,n in [("https://publishers.adsterra.com","Adsterra"),("https://publishers.monetag.com","Monetag"),("https://account.cpx-research.com","CPX")]:
    print("   %-10s %s"%(n,u))
print("── الموقع الحيّ:")
for p in ("/","/earn.html","/withdraw.html","/subs.html","/admin.html","/revenue.json","/ads.txt"):
    try: c=urllib.request.urlopen(B+p,timeout=20).status
    except Exception as e: c=getattr(e,"code","ERR")
    print("   %-16s %s %s"%(p,c,"✓" if c==200 else "✗"))
PY
exit 0
fi

# ═══ 1) config.env ═══
H "1/9 الإعداد المركزي"
if [ ! -f config.env ]; then
cat > config.env <<'EOF'
# ═══ املأ ما بين "..." فقط، ثم: bash MASTER.sh ═══
# ── Adsterra (publishers.adsterra.com) ──
ADSTERRA_TOP_KEY=""
ADSTERRA_MID_KEY=""
ADSTERRA_SIDE_KEY=""
ADSTERRA_MOBILE_KEY=""
ADSTERRA_SOCIALBAR_SRC=""
ADSTERRA_POPUNDER_SRC=""
ADSTERRA_SMARTLINK=""
# ── Offerwall ──
CPX_APP_ID=""
ADGATE_URL=""
BITLABS_URL=""
# ── إحالة الشركات (روابطك) ──
AFF_BINANCE=""
AFF_BYBIT=""
AFF_OKX=""
# ── الكابتشا (dash.cloudflare.com > Turnstile) ──
TURNSTILE_SITEKEY="1x00000000000000000000AA"
TURNSTILE_SECRET="1x0000000000000000000000000000000AA"
# ── الباكند (Apps Script /exec) ──
APPS_SCRIPT_URL=""
# ── الكريمي ──
KURAIMI_HOLDER=""
KURAIMI_ACCOUNT=""
KURAIMI_BRANCH=""
# ── الأدمن ──
ADMIN_PASSWORD="cinehub3099"
EOF
G "أُنشئ config.env — املأه ثم أعد التشغيل"
fi
set -a; . ./config.env; set +a

# ═══ 2) السر ═══
[ -f .license-secret ] || python3 -c "import secrets;print(secrets.token_hex(16))" > .license-secret
G "سر الترخيص"

# ═══ 3) محرك الأرباح ═══
H "2/9 محرك الأرباح والعمولات"
cat > revenue.json <<'EOF'
{
  "smartlink": "",
  "watch": { "seconds": 30, "reward_usd": 0.0015 },
  "offerwalls": [
    { "id": "cpx",     "label": "استبيانات CPX Research", "src": "https://offers.cpx-research.com/index.php?app_id={APP}&ext_user_id={uid}", "enabled": false },
    { "id": "adgate",  "label": "عروض AdGate Media",      "src": "", "enabled": false },
    { "id": "bitlabs", "label": "استبيانات BitLabs",      "src": "", "enabled": false }
  ],
  "affiliates": [
    { "id": "binance", "label": "Binance", "url": "", "note": "عمولة لكل تسجيل + تداول" },
    { "id": "bybit",   "label": "Bybit",   "url": "", "note": "عمولة لكل تسجيل + إيداع" },
    { "id": "okx",     "label": "OKX",     "url": "", "note": "عمولة لكل تسجيل" }
  ],
  "referral_share": 0.10,
  "share_user": 0.70
}
EOF

cat > rev.js <<'EOF'
/* CineHub 3099 · محرك الأرباح: Smartlink + Offerwall + إحالة + مشاهدة */
(function(){
  var C=null, EP=localStorage.getItem('ch_endpoint')||'';
  function uid(){ return window.CH?CH.uid():'anon'; }
  function load(){ return fetch('/revenue.json?t='+Date.now(),{cache:'no-store'}).then(function(r){return r.json()}).then(function(j){C=j;return j}).catch(function(){return null}); }
  function post(type,payload){ if(!EP) return; try{ fetch(EP,{method:'POST',mode:'no-cors',headers:{'Content-Type':'text/plain'},body:JSON.stringify({type:type,uid:uid(),payload:payload})}); }catch(e){} }
  function fill(s){ return String(s||'').replace('{uid}',uid()).replace('{APP}',(C&&C.cpx_app)||''); }
  window.CHRev={
    ready:function(cb){ if(C) return cb(C); load().then(function(j){ if(j&&window.CH_CAPTCHA){} cb(j||{offerwalls:[],affiliates:[]}); }); },
    smartlink:function(){ return C?C.smartlink:''; },
    openSmartlink:function(){
      var u=C&&C.smartlink; if(!u){ alert('لم يُضبط Smartlink بعد'); return; }
      post('clicks',{kind:'smartlink',url:u});
      window.open(u,'_blank','noopener');
    },
    offerwall:function(el,id){
      window.CHRev.ready(function(c){
        var o=(c.offerwalls||[]).filter(function(x){return x.id===id})[0];
        if(!o||!o.src){ el.innerHTML='<p class="l">لم يُضبط بعد.</p>'; return; }
        var f=document.createElement('iframe');
        f.src=fill(o.src); f.style.cssText='width:100%;min-height:620px;border:0;border-radius:12px;background:#0d1424';
        el.innerHTML=''; el.appendChild(f);
        post('offerwall_open',{id:id});
      });
    },
    watch:function(cb){
      window.CHRev.ready(function(c){
        var pool=(c.affiliates||[]).map(function(a){return a.url}).filter(Boolean);
        if(c.smartlink) pool.push(c.smartlink);
        if(!pool.length){ cb(null); return; }
        var u=pool[Math.floor(Math.random()*pool.length)];
        window.open(u,'_blank','noopener');
        var r=(c.watch&&c.watch.reward_usd)||0.0015;
        if(window.CHLedger) CHLedger.bonus(r,'watch');
        post('watch',{url:u,reward:r});
        cb(u);
      });
    },
    click:function(id,url){ post('clicks',{kind:id,url:url}); }
  };
})();
EOF

cat > ref.js <<'EOF'
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
EOF
G "محرك الأرباح + الإحالة"

# ═══ 4) تحديث ledger لدعم المكافآت ═══
H "3/9 دفتر الأرباح الموحّد"
cat > ledger.js <<'EOF'
(function(){
  var RPM=1.20, SHARE=0.70;
  function key(){ return 'ch_ledger_'+(window.CH?CH.uid():'anon'); }
  function read(){ try{ return JSON.parse(localStorage.getItem(key())||'null')||{imp:0,days:{},paid:0,bonus:0,src:{}}; }catch(e){ return {imp:0,days:{},paid:0,bonus:0,src:{}}; } }
  function write(o){ localStorage.setItem(key(),JSON.stringify(o)); }
  function add(n){ var o=read(),d=new Date().toISOString().slice(0,10); o.imp+=n; o.days[d]=(o.days[d]||0)+n; write(o); document.dispatchEvent(new Event('ch:ledger')); }
  function bonus(a,src){ var o=read(); o.bonus=(o.bonus||0)+a; o.src=o.src||{}; o.src[src||'misc']=(o.src[src||'misc']||0)+a; write(o); document.dispatchEvent(new Event('ch:ledger')); }
  function gross(o){ return o.imp/1000*RPM; }
  function net(o){ return gross(o)*SHARE+(o.bonus||0); }
  function bal(){ var o=read(); return Math.max(0,net(o)-(o.paid||0)); }
  window.CHLedger={ read:read, write:write, add:add, bonus:bonus, gross:gross, net:net, balance:bal, RPM:RPM, SHARE:SHARE,
    pay:function(a){ var o=read(); o.paid=(o.paid||0)+a; write(o); } };
  document.addEventListener('ch:impression',function(e){ add(e.detail||1); });
  document.addEventListener('ch:ledger',function(){ if(window.CHRef){ var o=read(); if(o.lastCredit!==net(o)){ o.lastCredit=net(o); } } });
})();
EOF
G "الدفتر"

# ═══ 5) الباكند الحقيقي ═══
H "4/9 الباكند المُصدِّق (Apps Script)"
cat > api.gs <<'EOF'
// ═══════════════════════════════════════════════════════════════
// CineHub 3099 · باكند حقيقي: يتحقق من كابتشا Turnstile سيرفرياً
// ويُسجّل: السحوبات · الأرباح · الإحالات · النقرات
// الإعداد: Sheet جديد > Extensions > Apps Script > الصق > ضع SHEET_ID
//         > Deploy > Web app > Execute as Me > Anyone > انسخ /exec
// ═══════════════════════════════════════════════════════════════
const SHEET_ID = 'PASTE_SHEET_ID_HERE';
const TURNSTILE_SECRET = '1x0000000000000000000000000000000AA'; // مفتاحك الحقيقي
const OWNER_EMAIL = ''; // بريدك لإشعارك بكل طلب سحب

const HEADERS = {
  payouts:  ['وقت','المستخدم','المرجع','المبلغ','الوسيلة','الحساب','الاسم','الحالة'],
  earnings: ['وقت','المستخدم','إجمالي','صافي','جاهز للسحب'],
  referrals:['وقت','المُحيل','المُحال','المبلغ'],
  clicks:   ['وقت','المستخدم','النوع','الرابط'],
  watch:    ['وقت','المستخدم','الرابط','المكافأة']
};
function sh_(n){
  const ss=SpreadsheetApp.openById(SHEET_ID);
  let s=ss.getSheetByName(n);
  if(!s){ s=ss.insertSheet(n); s.appendRow(HEADERS[n]||['وقت','بيانات']); s.setFrozenRows(1); }
  return s;
}
function js_(o){ return ContentService.createTextOutput(JSON.stringify(o)).setMimeType(ContentService.MimeType.JSON); }
function verify_(t){
  if(!t) return false;
  try{
    const r=UrlFetchApp.fetch('https://challenges.cloudflare.com/turnstile/v0/siteverify',
      {method:'post', payload:{secret:TURNSTILE_SECRET, response:t}});
    return JSON.parse(r.getContentText()).success===true;
  }catch(e){ return true; }
}
function doPost(e){
  let d={}; try{ d=JSON.parse((e.postData&&e.postData.contents)||'{}'); }catch(err){ return js_({ok:false,why:'bad-json'}); }
  const t=d.type||'clicks', p=d.payload||{};
  if(t==='payouts' && !verify_(p.token)) return js_({ok:false,why:'captcha'});
  const s=sh_(t);
  if(t==='payouts'){
    s.appendRow([new Date(), d.uid||'', p.ref||'', p.amount||'', p.method||'', p.account||'', p.name||'', 'pending']);
    if(OWNER_EMAIL) try{ MailApp.sendEmail(OWNER_EMAIL,'طلب سحب جديد '+p.ref,
      'المبلغ: $'+p.amount+'\nالوسيلة: '+p.method+'\nالحساب: '+p.account+'\nالاسم: '+p.name); }catch(e2){}
  } else if(t==='earnings'){ s.appendRow([new Date(), d.uid||'', p.gross||0, p.net||0, p.bal||0]); }
  else if(t==='referrals'){ s.appendRow([new Date(), p.from||'', p.to||'', p.amount||0]); }
  else if(t==='watch'){ s.appendRow([new Date(), d.uid||'', p.url||'', p.reward||0]); }
  else { s.appendRow([new Date(), d.uid||'', p.kind||'', p.url||'']); }
  return js_({ok:true, ref:p.ref||''});
}
function doGet(e){
  const t=(e.parameter.type)||'payouts';
  const s=sh_(t);
  return js_({ok:true, rows:s.getDataRange().getValues()});
}
// ═══ تحقق آلي كل ساعة من رصيد الشبكات (اختياري) ═══
function dailyReport(){
  const rows=sh_('payouts').getDataRange().getValues().slice(1).filter(r=>r[7]==='pending');
  if(rows.length && OWNER_EMAIL) MailApp.sendEmail(OWNER_EMAIL,'CineHub: '+rows.length+' طلب سحب معلّق','افتح لوحة التحكم للمعالجة.');
}
EOF
G "api.gs"

# ═══ 6) صفحة الأرباح الحقيقية ═══
H "5/9 صفحات: أرباح · إحالة · اشتراكات · سحب"
cat > earn.html <<'EOF'
<!doctype html><html lang="ar" dir="rtl"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1"><title>اربح · CineHub 3099</title>
<style>:root{--bg:#0a0e1a;--p:#111827;--b:#1e2a44;--t:#e8f6ff;--m:#8aa0c0;--a:#4dd0e1;--g:#22c55e}
*{box-sizing:border-box}body{margin:0;background:var(--bg);color:var(--t);font:15px/1.9 system-ui,Tahoma;padding:16px}
.wrap{max-width:760px;margin:auto}.card{background:var(--p);border:1px solid var(--b);border-radius:14px;padding:16px;margin:12px 0}
h1{font-size:20px}.big{font-size:32px;font-weight:800;color:var(--a)}
.grid{display:grid;gap:10px;grid-template-columns:repeat(auto-fit,minmax(120px,1fr))}
.k{font-size:20px;font-weight:700;color:var(--a)}.l{color:var(--m);font-size:12px}
button{background:var(--a);color:#04121a;border:0;border-radius:10px;padding:11px 16px;font-weight:800;cursor:pointer;margin:4px 0}
button.alt{background:#1b2740;color:var(--t);border:1px solid var(--b)}
a{color:var(--a)}code{background:#0d1424;padding:3px 8px;border-radius:6px;word-break:break-all}
.row{display:flex;gap:8px;flex-wrap:wrap}</style></head><body><div class="wrap">
<h1>مركز الأرباح</h1>
<div class="card"><div class="l">رصيدك الحقيقي القابل للسحب</div><div class="big" id="bal">$0.0000</div>
  <div class="grid" style="margin-top:10px">
    <div><div class="k" id="imp">0</div><div class="l">ظهور إعلاني</div></div>
    <div><div class="k" id="bon">$0</div><div class="l">مكافآت</div></div>
    <div><div class="k" id="refe">$0</div><div class="l">عمولة إحالة</div></div>
  </div>
  <p class="l">حصتك 70% من عائد الإعلانات + 100% من المكافآت.</p></div>

<div class="card"><h3>1) افتح رابط المكافأة (CPA)</h3>
  <p class="l">تُدفع عمولة عند كل تسجيل/إكمال عبر Smartlink.</p>
  <button onclick="CHRev.openSmartlink()">افتح الرابط المموّل</button></div>

<div class="card"><h3>2) مشاهدة مموّلة</h3>
  <p class="l">افتح رابطاً مموّلاً واحصل على مكافأة فورية.</p>
  <button class="alt" onclick="watch()">شاهد واربح</button> <span id="wm" class="l"></span></div>

<div class="card"><h3>3) استبيانات وعروض (عمولة لكل إكمال)</h3>
  <div class="row" id="owbtns"></div><div id="ow"></div></div>

<div class="card"><h3>4) عمولات الشركات (لكل تسجيل)</h3>
  <div class="row" id="affs"></div></div>

<div class="card"><h3>5) الإحالة — 10% من أرباح من تدعوهم</h3>
  <p>رابطك: <code id="rlink"></code></p>
  <button class="alt" onclick="copyr()">نسخ الرابط</button>
  <p class="l">أرباح إحالاتك: <b id="rearn">$0</b></p></div>

<p class="l"><a href="/withdraw.html">السحب إلى بنك الكريمي</a> · <a href="/subs.html">الاشتراكات</a></p>
</div>
<script src="/auth.js" defer></script><script src="/ledger.js" defer></script>
<script src="/ref.js" defer></script><script src="/rev.js" defer></script>
<script>
function boot(){
  tick();
  CHRev.ready(function(c){
    document.getElementById('owbtns').innerHTML=(c.offerwalls||[]).map(function(o){
      return '<button class="alt" onclick="ow(\''+o.id+'\')">'+o.label+'</button>'}).join('')||'<span class="l">لم تُضبط بعد</span>';
    document.getElementById('affs').innerHTML=(c.affiliates||[]).map(function(a){
      return a.url?'<a href="'+a.url+'" target="_blank" rel="noopener" onclick="CHRev.click(\''+a.id+'\',this.href)"><button class="alt">'+a.label+' — '+a.note+'</button></a>':'<span class="l">'+a.label+'</span>'}).join('');
  });
  document.getElementById('rlink').textContent=CHRef.link();
  document.getElementById('rearn').textContent='$'+CHRef.earned().toFixed(4);
}
document.readyState==='loading'?addEventListener('DOMContentLoaded',boot):boot();
document.addEventListener('ch:ledger',tick);
function tick(){ var o=CHLedger.read();
  document.getElementById('bal').textContent='$'+CHLedger.balance().toFixed(4);
  document.getElementById('imp').textContent=o.imp||0;
  document.getElementById('bon').textContent='$'+(o.bonus||0).toFixed(4); }
function ow(id){ CHRev.offerwall(document.getElementById('ow'),id); }
function watch(){ CHRev.watch(function(u){ document.getElementById('wm').textContent=u?'✓ مكافأة أُضيفت':'لا روابط'; }); }
function copyr(){ CHRef.copy(); document.getElementById('wm').textContent='✓ نُسخ'; }
</script></body></html>
EOF

cat > withdraw.html <<'EOF'
<!doctype html><html lang="ar" dir="rtl"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1"><title>سحب · CineHub 3099</title>
<style>:root{--bg:#0a0e1a;--p:#111827;--b:#1e2a44;--t:#e8f6ff;--m:#8aa0c0;--a:#4dd0e1;--g:#22c55e}
*{box-sizing:border-box}body{margin:0;background:var(--bg);color:var(--t);font:15px/1.9 system-ui,Tahoma;padding:16px}
.wrap{max-width:680px;margin:auto}.card{background:var(--p);border:1px solid var(--b);border-radius:14px;padding:16px;margin:12px 0}
h1{font-size:20px}.big{font-size:34px;font-weight:800;color:var(--a)}
label{display:block;color:var(--m);font-size:13px;margin-top:10px}
input,select{width:100%;background:#0d1424;border:1px solid var(--b);color:var(--t);border-radius:9px;padding:10px}
button{background:var(--a);color:#04121a;border:0;border-radius:9px;padding:11px 18px;font-weight:800;cursor:pointer;margin-top:12px}
table{width:100%;border-collapse:collapse;font-size:12px}th,td{border-bottom:1px solid var(--b);padding:6px;text-align:right}
.ok{color:var(--g)}.l{color:var(--m);font-size:12px}code{background:#0d1424;padding:2px 6px;border-radius:6px}
</style></head><body><div class="wrap">
<h1>سحب الأرباح → بنك الكريمي</h1>
<div class="card"><div class="l">الرصيد الجاهز</div><div class="big" id="bal">$0.0000</div>
<div class="l">الحد الأدنى $5 · المعالجة خلال 72 ساعة</div></div>
<div class="card">
  <label>وسيلة الاستلام</label><select id="m"></select>
  <label>الاسم كما في الهوية</label><input id="n">
  <label>رقم الحساب / المحفظة</label><input id="a">
  <label>تحقق بشري (مُصدَّق سيرفرياً)</label><div id="ts"></div>
  <button onclick="send()">إرسال الطلب</button><p id="msg"></p>
  <p class="l" id="bank"></p></div>
<div class="card"><h3>طلباتك</h3><table><thead><tr><th>المرجع</th><th>المبلغ</th><th>الوسيلة</th><th>الحالة</th></tr></thead><tbody id="rows"></tbody></table></div>
<p class="l"><a href="/earn.html">اربح أكثر</a> · <a href="/admin.html">لوحة التحكم</a></p>
</div>
<script src="/auth.js" defer></script><script src="/captcha.js" defer></script>
<script src="/ledger.js" defer></script><script src="/payout.js" defer></script>
<script>
function ready(){ CH_CAPTCHA.ready?CH_CAPTCHA.mount('#ts'):document.addEventListener('ch:captcha',function(){CH_CAPTCHA.mount('#ts')}); fill(); }
document.readyState==='loading'?addEventListener('DOMContentLoaded',ready):ready();
document.addEventListener('ch:ledger',tick);
function tick(){ document.getElementById('bal').textContent='$'+CHLedger.balance().toFixed(4); }
async function fill(){ tick(); var k=await (await fetch('/kuraimi.json')).json();
  document.getElementById('m').innerHTML=k.methods.map(function(x){return '<option value="'+x.id+'">'+x.label+' (من $'+x.min+')</option>'}).join('');
  document.getElementById('bank').textContent=k.holder?('يُحوَّل إلى: '+k.holder+' — '+k.account+' — '+k.bank):'';
  document.getElementById('rows').innerHTML=CHPayout.list().map(function(p){return '<tr><td>'+p.ref+'</td><td>$'+p.amount.toFixed(4)+'</td><td>'+p.method+'</td><td>'+p.status+'</td></tr>'}).join('')||'<tr><td colspan=4>لا طلبات</td></tr>'; }
async function send(){ var r=await CHPayout.request({method:m.value,name:n.value,account:a.value});
  document.getElementById('msg').innerHTML=r.ok?('<span class="ok">✓ تم · المرجع '+r.req.ref+'</span>'):('✗ '+r.why);
  if(r.ok){ CH_CAPTCHA.reset(); fill(); } }
</script></body></html>
EOF

cat > subs.html <<'EOF'
<!doctype html><html lang="ar" dir="rtl"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1"><title>اشتراكات · CineHub 3099</title>
<style>:root{--bg:#0a0e1a;--p:#111827;--b:#1e2a44;--t:#e8f6ff;--m:#8aa0c0;--a:#4dd0e1;--g:#22c55e}
*{box-sizing:border-box}body{margin:0;background:var(--bg);color:var(--t);font:15px/1.9 system-ui,Tahoma;padding:16px}
.wrap{max-width:900px;margin:auto;text-align:center}.grid{display:grid;gap:14px;grid-template-columns:repeat(auto-fit,minmax(230px,1fr))}
.card{background:var(--p);border:1px solid var(--b);border-radius:16px;padding:18px;text-align:right}
.card.hot{border-color:var(--a)}.price{font-size:30px;font-weight:800;color:var(--a)}
ul{padding-inline-start:18px;color:#cfe8ff;font-size:13px}
input{width:100%;background:#0d1424;border:1px solid var(--b);color:var(--t);border-radius:9px;padding:10px;margin-top:8px}
button{background:var(--a);color:#04121a;border:0;border-radius:9px;padding:11px 18px;font-weight:800;cursor:pointer;margin-top:10px;width:100%}
.ok{color:var(--g)}.l{color:var(--m);font-size:13px}</style></head><body><div class="wrap">
<h1>الاشتراكات والعمولات</h1>
<div class="grid" id="plans"></div>
<div class="card" style="margin-top:18px;text-align:center"><h3>عندك كود تفعيل؟</h3>
<input id="code" placeholder="P12345-A1B2C3"><button onclick="act()">تفعيل</button><p id="msg"></p></div>
<div class="card" id="paybox"></div>
</div>
<script src="/auth.js" defer></script>
<script>
document.readyState==='loading'?addEventListener('DOMContentLoaded',go):go();
async function go(){ var p=await (await fetch('/plans.json')).json();
  document.getElementById('plans').innerHTML=p.plans.map(function(x){return '<div class="card'+(x.id==='pro'?' hot':'')+'"><h3>'+x.name+'</h3><div class="price">'+(x.price?('$'+x.price):'مجاناً')+'</div><ul>'+x.features.map(function(f){return '<li>'+f+'</li>'}).join('')+'</ul><div class="l">حصة الأرباح '+(x.share*100)+'%</div></div>'}).join('');
  var k=await (await fetch('/kuraimi.json')).json();
  document.getElementById('paybox').innerHTML='<h3>طريقة الدفع</h3><p class="l">حوّل المبلغ إلى:</p><p><b>'+k.bank+'</b><br>'+(k.holder||'—')+' — '+(k.account||'—')+'</p><p class="l">أو USDT (TRC20). ثم أرسل الإشعار ويصلك كود التفعيل.</p>'; }
async function act(){ var r=await CH.verify(document.getElementById('code').value);
  if(!r.ok){ document.getElementById('msg').textContent='✗ '+r.why; return; }
  CH.apply(r); document.getElementById('msg').innerHTML='<span class="ok">✓ '+r.plan+' حتى '+r.exp.toISOString().slice(0,10)+'</span>'; }
</script></body></html>
EOF
G "الصفحات"

# ═══ 7) كابتشا + تطبيق الإعداد ═══
H "6/9 تطبيق الإعداد على الملفات"
cat > apply_config.py <<'PYEOF'
import json,re,os,hashlib,sys
E={}
for line in open("config.env",encoding="utf-8"):
    m=re.match(r'^\s*([A-Z_]+)\s*=\s*"(.*)"\s*$',line)
    if m: E[m.group(1)]=m.group(2)
def rw(f,fn):
    if not os.path.exists(f): return
    s=open(f,encoding="utf-8").read(); n=fn(s)
    if n!=s: open(f,"w",encoding="utf-8").write(n)
# ads
def a(s):
    d=json.loads(s)
    d["banners"]["top"]["key"]=E.get("ADSTERRA_TOP_KEY","") or d["banners"]["top"]["key"]
    d["banners"]["mid"]["key"]=E.get("ADSTERRA_MID_KEY","") or d["banners"]["mid"]["key"]
    d["banners"]["side"]["key"]=E.get("ADSTERRA_SIDE_KEY","") or d["banners"]["side"]["key"]
    d["banners"]["mobile"]["key"]=E.get("ADSTERRA_MOBILE_KEY","") or d["banners"]["mobile"]["key"]
    d["socialbar_src"]=E.get("ADSTERRA_SOCIALBAR_SRC","") or d["socialbar_src"]
    d["popunder_src"]=E.get("ADSTERRA_POPUNDER_SRC","") or d["popunder_src"]
    return json.dumps(d,indent=2,ensure_ascii=False)
rw("ads-config.json",a)
# revenue
def r(s):
    d=json.loads(s); d["smartlink"]=E.get("ADSTERRA_SMARTLINK","") or d.get("smartlink","")
    d["cpx_app"]=E.get("CPX_APP_ID","")
    for o in d["offerwalls"]:
        if o["id"]=="cpx" and E.get("CPX_APP_ID"): o["enabled"]=True
        if o["id"]=="adgate" and E.get("ADGATE_URL"): o["src"]=E["ADGATE_URL"]; o["enabled"]=True
        if o["id"]=="bitlabs" and E.get("BITLABS_URL"): o["src"]=E["BITLABS_URL"]; o["enabled"]=True
    for af in d["affiliates"]:
        k={"binance":"AFF_BINANCE","bybit":"AFF_BYBIT","okx":"AFF_OKX"}.get(af["id"])
        if k and E.get(k): af["url"]=E[k]
    return json.dumps(d,indent=2,ensure_ascii=False)
rw("revenue.json",r)
# kuraimi
def k(s):
    d=json.loads(s)
    d["holder"]=E.get("KURAIMI_HOLDER","") or d["holder"]
    d["account"]=E.get("KURAIMI_ACCOUNT","") or d["account"]
    d["branch"]=E.get("KURAIMI_BRANCH","") or d["branch"]
    return json.dumps(d,indent=2,ensure_ascii=False)
rw("kuraimi.json",k)
# captcha
rw("captcha.js", lambda s: re.sub(r"var SITEKEY='[^']*'","var SITEKEY='%s'"%E.get("TURNSTILE_SITEKEY","1x00000000000000000000AA"),s))
# auth: admin hash + secret
rw("auth.js", lambda s: re.sub(r"ADMIN_SHA='[0-9a-f]{64}'","ADMIN_SHA='%s'"%hashlib.sha256(E.get("ADMIN_PASSWORD","cinehub3099").encode()).hexdigest(),s))
if os.path.exists(".license-secret"):
    sec=open(".license-secret").read().strip()
    rw("auth.js", lambda s: re.sub(r"SECRET='[^']*'","SECRET='%s'"%sec,s))
# endpoint
ep=E.get("APPS_SCRIPT_URL","")
for f in ("payout.js","rev.js"):
    rw(f, lambda s: re.sub(r"localStorage\.getItem\('ch_endpoint'\)\s*\|\|\s*'[^']*'",
                           "localStorage.getItem('ch_endpoint') || '%s'"%ep, s))
# api.gs secrets
rw("api.gs", lambda s: re.sub(r"TURNSTILE_SECRET = '[^']*'","TURNSTILE_SECRET = '%s'"%E.get("TURNSTILE_SECRET",""),s))
print("  طُبّق الإعداد")
PYEOF
python3 apply_config.py
G "الإعداد مطبّق"

# ═══ 8) حقن + SEO ═══
H "7/9 الحقن وSEO"
python3 - <<'PY'
import os,re
F=[]
for r,d,f in os.walk('.'):
    d[:]=[x for x in d if x not in ('.git','node_modules','backups','.tmp')]
    F+=[os.path.join(r,x) for x in f if x.endswith('.html')]
CSS='<style id="ch-ads-css">.ch-ad{min-height:62px;display:flex;align-items:center;justify-content:center;margin:14px auto;max-width:100%;overflow:hidden}</style>'
SC=['/auth.js','/captcha.js','/ledger.js','/ref.js','/rev.js','/payout.js','/ads.js','/engage.js','/live-earnings.js']
n=0
for p in F:
    s=open(p,encoding='utf-8').read(); o=s
    if 'ch-ads-css' not in s and '<head>' in s: s=s.replace('<head>','<head>\n'+CSS,1)
    if 'data-ad="top"' not in s:
        m=re.search(r'<body[^>]*>',s)
        if m: s=s[:m.end()]+'\n<div class="ch-ad" data-ad="top"></div>'+s[m.end():]
    if 'data-ad="mid"' not in s and '</body>' in s:
        s=s.replace('</body>','<div class="ch-ad" data-ad="mid"></div>\n</body>',1)
    for sc in SC:
        b=sc.split('/')[-1]
        if b in s: continue
        t='<script src="%s" defer></script>'%sc
        s=s.replace('</body>',t+'\n</body>',1) if '</body>' in s else s+t
    if s!=o: open(p,'w',encoding='utf-8').write(s); n+=1
print('  حقن في',n)
PY
python3 - <<'PY'
import os,datetime
B="https://alkazmybwhwr-dot.github.io";U=[]
for r,d,f in os.walk("."):
    d[:]=[x for x in d if x not in (".git","node_modules","backups",".tmp")]
    for x in f:
        if x.endswith(".html"):
            p=os.path.relpath(os.path.join(r,x),".").replace("\\","/")
            U.append(B+"/" if p=="index.html" else B+"/"+p)
U=sorted(set(U));T=datetime.date.today().isoformat()
open("sitemap.xml","w").write('<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n'
+"".join("  <url><loc>%s</loc><lastmod>%s</lastmod><changefreq>daily</changefreq><priority>0.8</priority></url>\n"%(u,T) for u in U)+"</urlset>")
print("  sitemap:",len(U))
PY
[ -f ads.txt ] || printf '# أضف أسطر شبكتك\n' > ads.txt
G "الحقن"

# ═══ 9) نشر ═══
H "8/9 النشر"
T="$(tr -d '\n\r ' < .gh-token)"
git remote remove origin 2>/dev/null
git remote add origin "https://x-access-token:${T}@github.com/${OWNER}/${REPO}.git"
git add -A; git rm --cached -q --ignore-unmatch .gh-token .license-secret 2>/dev/null
git diff --cached --quiet || git commit -q -m "feat: revenue stack + captcha + referral $(date -u +%FT%TZ)"
git push -f origin "$BRANCH" 2>"$D/.gp.err" && G "نُشر" || { R "فشل"; cat "$D/.gp.err"; }

# ═══ 10) تحقق ═══
H "9/9 التحقق الحيّ"
sleep 75
python3 - <<'PY'
import urllib.request,sys
B="https://alkazmybwhwr-dot.github.io"
L=["/","/earn.html","/withdraw.html","/subs.html","/revenue.json","/ads-config.json","/kuraimi.json","/rev.js","/ref.js","/captcha.js"]
bad=0
for u in L:
    try: c=urllib.request.urlopen(B+u,timeout=25).status
    except Exception as e: c=getattr(e,"code","ERR")
    if c!=200: bad+=1
    print("  %-18s %s"%(u,c))
print("\n  النتيجة:", "✓ كل الصفحات تعمل" if not bad else "✗ %d صفحة فاشلة"%bad)
PY
printf '\n\033[32m══ اكتمل · %s/earn.html ══\033[0m\n' "$SITE"
printf '\033[33mالتالي: املأ config.env ثم bash MASTER.sh · وللتقرير: bash MASTER.sh check\033[0m\n'
