#!/data/data/com.termux/files/usr/bin/bash
cd "$(dirname "$0")" || exit 1
OWNER="alkazmybwhwr-dot"; REPO="alkazmybwhwr-dot.github.io"; BRANCH="main"
SITE="https://${OWNER}.github.io"
say(){ printf '\n\033[36m▶ %s\033[0m\n' "$1"; }
ok(){  printf '\033[32m✓ %s\033[0m\n' "$1"; }
warn(){ printf '\033[33m! %s\033[0m\n' "$1"; }

say "1/10 بيئة"; command -v git >/dev/null || { pkg install -y git; }; command -v python3 >/dev/null || { pkg install -y python; }; ok "جاهز"

say "2/10 .gitignore + publish.sh"
printf 'node_modules/\nbackups/\n*.log\n.gh-token\n__pycache__/\n' > .gitignore
cat > publish.sh <<'PUB'
#!/data/data/com.termux/files/usr/bin/bash
cd "$(dirname "$0")" || exit 1
O="alkazmybwhwr-dot"; R="alkazmybwhwr-dot.github.io"; B="main"
[ -f .gh-token ] || { echo "✗ لا يوجد .gh-token — نفّذ: python3 auth.py"; exit 1; }
T="$(tr -d '\n\r ' < .gh-token)"
git rev-parse --git-dir >/dev/null 2>&1 || git init -q
git config user.email "cinehub@local"; git config user.name "CineHub"
git branch -M "$B"
git remote remove origin 2>/dev/null
git remote add origin "https://x-access-token:${T}@github.com/${O}/${R}.git"
git add -A
git rm --cached -q --ignore-unmatch .gh-token
git diff --cached --quiet || git commit -q -m "publish $(date -u +%FT%TZ)"
n=0; until git push -q -f origin "$B"; do n=$((n+1)); [ $n -ge 5 ] && { echo "✗ فشل"; exit 1; }; sleep $((n*3)); done
echo "✓ نُشر → https://${O}.github.io"
PUB
chmod +x publish.sh; ok "publish.sh"

say "3/10 wallet.py (تدوير 6 RPC)"
cat > wallet.py <<'PY'
import json,sys,os,urllib.request
RPC=["https://base.llamarpc.com","https://base-rpc.publicnode.com","https://1rpc.io/base",
     "https://base.blockpi.network/v1/rpc/public","https://base.drpc.org","https://mainnet.base.org"]
TOK={"USDC":("0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913",6),
     "USDT":("0xfde4C96c8593536E31F229EA8f37b2ADa2699bb2",6),
     "VVV":("0xacfE6019Ed1A7Dc6f7B508C02d1b04ec88cC21bf",18),
     "DIEM":("0xf4d97f2da56e8c3098f3a8d538db630a2606a024",18)}
def rpc(m,p):
    b=json.dumps({"jsonrpc":"2.0","id":1,"method":m,"params":p}).encode(); e=None
    for u in RPC:
        try:
            r=urllib.request.Request(u,data=b,headers={"Content-Type":"application/json","User-Agent":"cinehub"})
            j=json.loads(urllib.request.urlopen(r,timeout=15).read().decode())
            if "result" in j: return j["result"]
            e=j.get("error")
        except Exception as x: e=x
    raise RuntimeError(e)
w=sys.argv[1] if len(sys.argv)>1 else ""
if not w and os.path.exists("wallet.json"):
    w=json.load(open("wallet.json")).get("address","")
if w.startswith("0x") and len(w)==42:
    json.dump({"address":w},open("wallet.json","w")); pad=w.lower()[2:].rjust(64,"0")
    print("═══ محفظة: %s ═══"%w)
    for s,(a,d) in TOK.items():
        try: print("%-6s: %s"%(s,int(rpc("eth_call",[{"to":a,"data":"0x70a08231"+pad},"latest"]),16)/10**d))
        except Exception as x: print("%-6s: —"%s)
    try: print("ETH   : %s"%(int(rpc("eth_getBalance",[w,"latest"]),16)/1e18))
    except Exception: print("ETH   : —")
    print("المصدر: Base مباشرة — لا تقدير")
else: print("! محفظة غير محددة — نفّذ: python3 wallet.py 0xعنوانك")
PY
chmod +x wallet.py; ok "wallet.py"

say "4/10 محرّك الإعلانات (8 شبكات + كبح حصص)"
cat > ads-config.json <<'JSON'
{ "adsterra":{"popunder":"","socialbar":"","banner":""},
  "monetag":{"vignette":"","inpage":""}, "propeller":{"push":""},
  "adcash":{"popunder":""}, "hilltop":{"popunder":""}, "clickadu":{"popunder":""},
  "slots":{"banner":"","300x250":"","728x90":"","300x600":""} }
JSON
cat > ads.js <<'JS'
(function(){var C=window.CH_ADS_CONFIG||{},D={};
function L(s,p){if(!s||D[s])return;D[s]=1;var e=document.createElement("script");
e.src=s;e.async=1;e.setAttribute("data-cfasync","false");(p||document.head).appendChild(e);}
addEventListener("load",function(){var P=[C.adsterra&&C.adsterra.popunder,C.monetag&&C.monetag.vignette,
C.propeller&&C.propeller.push,C.adcash&&C.adcash.popunder,C.hilltop&&C.hilltop.popunder,
C.clickadu&&C.clickadu.popunder].filter(Boolean);P.sort(function(){return Math.random()-.5});
P.slice(0,2).forEach(function(s){L(s)});if(C.adsterra&&C.adsterra.socialbar)L(C.adsterra.socialbar);},{once:1});
function F(el){var k=el.getAttribute("data-ad"),s=(C.slots&&C.slots[k])||(C.adsterra&&C.adsterra.banner);
if(!s||el.classList.contains("ad-filled"))return;el.classList.add("ad-filled");L(s,el);
localStorage.setItem("ch_impressions",(+(localStorage.getItem("ch_impressions")||0))+1);}
var io="IntersectionObserver"in window?new IntersectionObserver(function(es){es.forEach(function(e){
if(e.isIntersecting){io.unobserve(e.target);F(e.target);}})},{rootMargin:"300px"}):null;
function S(){var a=document.querySelectorAll("[data-ad]:not(.ad-filled)");for(var i=0;i<a.length;i++)io?io.observe(a[i]):F(a[i]);}
document.readyState==="loading"?addEventListener("DOMContentLoaded",S):S();window.CH_rescanAds=S;})();
JS
ok "ads.js"

say "5/10 push.js + engage.js + live-earnings.js"
cat > push.js <<'JS'
(function(){window.OneSignalDeferred=window.OneSignalDeferred||[];var A="PUT-ONESIGNAL-APP-ID";
if(A.indexOf("PUT")===0)return;var s=document.createElement("script");
s.src="https://cdn.onesignal.com/sdks/web/v16/OneSignalSDK.page.js";s.defer=1;document.head.appendChild(s);
OneSignalDeferred.push(function(O){O.init({appId:A})});})();
JS
cat > engage.js <<'ENG'
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
ENG
cat > live-earnings.js <<'LE'
(function(){var RPM=1.2,e=document.getElementById("ch-live");
if(!e){e=document.createElement("div");e.id="ch-live";
e.style.cssText="position:fixed;top:10px;left:10px;z-index:9997;background:#0b1020ee;border:1px solid #1e2a44;color:#9fe8ff;font:11px/1.6 system-ui;padding:6px 10px;border-radius:10px";
addEventListener("DOMContentLoaded",function(){document.body.appendChild(e)});}
function t(){var v=+(localStorage.getItem("ch_visits")||0),i=+(localStorage.getItem("ch_impressions")||0);
e.innerHTML="زيارات <b>"+v+"</b> · ظهور <b>"+i+"</b> · RPM <b>$"+RPM.toFixed(2)+"</b> · تقدير <b>$"+((i/1000)*RPM).toFixed(4)+"</b>";}
setInterval(t,2000);t();})();
LE
ok "3 ملفات تفاعل"

say "6/10 أدوات SEO"
mkdir -p tools
cat > tools/seo.py <<'SEO'
import os,re
BASE="https://alkazmybwhwr-dot.github.io"
SC=["/push.js","/ads.js","/engage.js","/live-earnings.js"]
LG=[d for d in ("en","es","fr","id","pt","tr","ar") if os.path.isdir(d)]
hl="<!--hreflang-->"+"".join('\n<link rel="alternate" hreflang="%s" href="%s/%s/">'%(l,BASE,l) for l in LG)
hl+='\n<link rel="alternate" hreflang="x-default" href="%s/">'%BASE+"\n<!--/hreflang-->"
F=[]
for r,d,f in os.walk("."):
    d[:]=[x for x in d if x not in ("node_modules","backups",".git")]
    F+=[os.path.join(r,x) for x in f if x.endswith(".html")]
n=0
for p in F:
    s=o=open(p,encoding="utf-8").read()
    s=re.sub(r"<!--hreflang-->.*?<!--/hreflang-->","",s,flags=re.S)
    if "<head>" in s: s=s.replace("<head>","<head>\n"+hl,1)
    for sc in SC:
        if os.path.basename(sc) in s: continue
        t='<script src="%s" defer></script>'%sc
        s=s.replace("</body>",t+"\n</body>",1) if "</body>" in s else s+"\n"+t
    if s!=o: open(p,"w",encoding="utf-8").write(s); n+=1
print("SEO: %d ملف"%n)
SEO
cat > tools/sitemap.py <<'SM'
import os,datetime
B="https://alkazmybwhwr-dot.github.io";U=[]
for r,d,f in os.walk("."):
    d[:]=[x for x in d if x not in ("node_modules","backups",".git")]
    for x in f:
        if x.endswith(".html"):
            p=os.path.relpath(os.path.join(r,x),".").replace("\\","/")
            U.append(B+"/" if p=="index.html" else B+"/"+p)
U=sorted(set(U));T=datetime.date.today().isoformat()
open("sitemap.xml","w").write('<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n'
+"".join("  <url><loc>%s</loc><lastmod>%s</lastmod><changefreq>daily</changefreq><priority>0.8</priority></url>\n"%(u,T) for u in U)+"</urlset>")
print("sitemap: %d رابط"%len(U))
SM
cat > tools/indexnow.py <<'IN'
import os,re,glob,json,urllib.request
B="https://alkazmybwhwr-dot.github.io";H="alkazmybwhwr-dot.github.io"
k=[os.path.basename(f)[:-4] for f in glob.glob("*.txt") if re.fullmatch(r"[0-9a-f]{32}\.txt",os.path.basename(f))]
if not k: print("! لا ملف مفتاح IndexNow"); raise SystemExit
U=re.findall(r"<loc>(.*?)</loc>",open("sitemap.xml").read())[:900]
d=json.dumps({"host":H,"key":k[0],"keyLocation":B+"/"+k[0]+".txt","urlList":U}).encode()
r=urllib.request.Request("https://api.indexnow.org/indexnow",data=d,headers={"Content-Type":"application/json; charset=utf-8"})
try: print("IndexNow:",urllib.request.urlopen(r,timeout=30).status,"·",len(U),"رابط")
except Exception as e: print("IndexNow:",e)
IN
ok "أدوات جاهزة"

say "7/10 صفحة عربية /ar/"
if [ ! -d ar ]; then mkdir -p ar; cp en/index.html ar/index.html 2>/dev/null && \
python3 -c "import re;p='ar/index.html';s=open(p,encoding='utf-8').read();s=re.sub(r'<html[^>]*>','<html lang=\"ar\" dir=\"rtl\">',s,1);open(p,'w',encoding='utf-8').write(s)" && ok "أُنشئت ar/"; fi

say "8/10 تشغيل الأدوات"
python3 wallet.py
python3 tools/seo.py
python3 tools/sitemap.py

say "9/10 نشر"
bash publish.sh || exit 1

say "10/10 تحقق حيّ (بعد 75 ثانية من بناء Pages)"
sleep 75
python3 - <<'VF'
import urllib.request
B="https://alkazmybwhwr-dot.github.io"
for u in ["/","/ads.js","/engage.js","/push.js","/sitemap.xml","/robots.txt","/wallet.json","/earn.html","/b/movies-2025.html","/ar/"]:
    try:
        r=urllib.request.urlopen(B+u,timeout=20); print(" %s  %s"%(r.status,u))
    except Exception as e: print(" ERR  %s  (%s)"%(u,getattr(e,'code',e)))
VF
python3 tools/indexnow.py
printf '\n\033[32m══ تم. الموقع حيّ: %s ══\033[0m\n' "$SITE"
