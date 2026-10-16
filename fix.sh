#!/data/data/com.termux/files/usr/bin/bash
cd "$(dirname "$0")" || exit 1
G(){ printf '\033[32m✓ %s\033[0m\n' "$1"; }; B(){ printf '\033[31m✗ %s\033[0m\n' "$1"; }
H(){ printf '\n\033[36m▶ %s\033[0m\n' "$1"; }

H "0/8 نسخة احتياطية"
mkdir -p backups
tar czf "backups/fix-$(date +%s).tgz" --exclude=node_modules --exclude=backups --exclude=.git . 2>/dev/null && G "محفوظة"

H "1/8 تصحيح publish.py"
python3 - <<'PY'
import re
s = open("publish.py", encoding="utf-8").read()
if "Connection" in s and "http.client" in s:
    print("  مُرقّع مسبقًا"); raise SystemExit
need = ["import json","import time","import http.client","import urllib.request","import urllib.error"]
head = "\n".join(n for n in need if n not in s)
if head: s = head + "\n" + s
new = '''def api(method, path, body=None, tries=6):
    """GitHub API + إعادة محاولة (يحل RemoteDisconnected)."""
    url = "https://api.github.com" + path
    data = json.dumps(body).encode() if body is not None else None
    last = None
    for attempt in range(1, tries + 1):
        req = urllib.request.Request(url, data=data, method=method)
        req.add_header("Authorization", "Bearer " + TOKEN)
        req.add_header("Accept", "application/vnd.github+json")
        req.add_header("User-Agent", "cinehub-publish")
        req.add_header("Content-Type", "application/json")
        req.add_header("Connection", "close")
        try:
            with urllib.request.urlopen(req, timeout=60) as resp:
                raw = resp.read().decode()
                return json.loads(raw) if raw else {}
        except urllib.error.HTTPError as e:
            if e.code in (500, 502, 503, 504):
                last = e; time.sleep(2 * attempt); continue
            raise
        except (http.client.RemoteDisconnected, ConnectionResetError,
                ConnectionAbortedError, TimeoutError, urllib.error.URLError) as e:
            last = e
            if attempt == tries: break
            print("  ... retry %d/%d" % (attempt, tries)); time.sleep(2 * attempt)
    raise RuntimeError("فشل API بعد %d محاولات: %s" % (tries, last))
'''
m = re.search(r"^def api\(.*?(?=^def |^class |\Z)", s, flags=re.S | re.M)
s = (s[:m.start()] + new + s[m.end():]) if m else (s + "\n" + new)
open("publish.py", "w", encoding="utf-8").write(s)
print("  رُقّع api()")
PY
python3 -m py_compile publish.py 2>/dev/null && G "publish.py سليم" || B "publish.py خطأ"

H "2/8 publish.sh (git — بلا API)"
cat > publish.sh <<'PUB'
#!/data/data/com.termux/files/usr/bin/bash
cd "$(dirname "$0")" || exit 1
O="alkazmybwhwr-dot"; R="alkazmybwhwr-dot.github.io"; B="main"
[ -f .gh-token ] || { echo "✗ نفّذ: python3 auth.py"; exit 1; }
T="$(tr -d '\n\r ' < .gh-token)"
printf 'node_modules/\nbackups/\n*.log\n.gh-token\n__pycache__/\n*.tgz\n' > .gitignore
git rev-parse --git-dir >/dev/null 2>&1 || git init -q
git config user.email "cinehub@local"; git config user.name "CineHub"
git branch -M "$B"
git remote remove origin 2>/dev/null
git remote add origin "https://x-access-token:${T}@github.com/${O}/${R}.git"
git add -A; git rm --cached -q --ignore-unmatch .gh-token
git diff --cached --quiet || git commit -q -m "publish $(date -u +%FT%TZ)"
n=0; until git push -q -f origin "$B"; do n=$((n+1)); [ $n -ge 5 ] && { echo "✗ فشل"; exit 1; }; sleep $((n*3)); done
echo "✓ نُشر → https://${O}.github.io"
PUB
chmod +x publish.sh; bash -n publish.sh && G "publish.sh سليم"

H "3/8 wallet (تدوير RPC + تحقق من العنوان)"
cat > wallet.py <<'WPY'
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
json.dump({"address":w},open("wallet.json","w"))
pad=w.lower()[2:].rjust(64,"0")
print("=== محفظة: %s ==="%w)
for s,(a,d) in TOK.items():
    try: print("%-6s: %s"%(s,int(rpc("eth_call",[{"to":a,"data":"0x70a08231"+pad},"latest"]),16)/10**d))
    except Exception as x: print("%-6s: تعذّر (%s)"%(s,str(x)[:40]))
try: print("ETH   : %s"%(int(rpc("eth_getBalance",[w,"latest"]),16)/1e18))
except Exception as x: print("ETH   : تعذّر")
print("المصدر: Base مباشرة — لا تقدير")
WPY
cat > wallet.sh <<'WSH'
#!/data/data/com.termux/files/usr/bin/bash
cd "$(dirname "$0")" || exit 1
W="${1:-}"
[ -z "$W" ] && [ -f wallet.json ] && W=$(python3 -c "import json;print(json.load(open('wallet.json')).get('address',''))" 2>/dev/null)
if ! printf '%s' "$W" | grep -Eq '^0x[0-9a-fA-F]{40}$'; then
  echo "✗ عنوان غير صالح: '$W'"
  echo "  المطلوب: 0x ثم 40 خانة hex"
  echo "  مثال:   bash wallet.sh 0x1111111111111111111111111111111111111111"
  exit 1
fi
python3 wallet.py "$W"
WSH
chmod +x wallet.sh; bash -n wallet.sh && python3 -m py_compile wallet.py && G "wallet جاهز"

H "4/8 activate.sh (يرفض النص العربي)"
cat > activate.sh <<'ACT'
#!/data/data/com.termux/files/usr/bin/bash
cd "$(dirname "$0")" || exit 1
U="${1:-}"
if [ -z "$U" ]; then echo "الاستخدام: bash activate.sh \"//pl12345.profitablecpmrate.com/xx/xx/xx/invoke.js\""; exit 1; fi
case "$U" in
  *[!a-zA-Z0-9/._:\&\?=-]*) echo "✗ الرابط فيه رموز غريبة (نص عربي؟): $U"; exit 1;;
esac
case "$U" in
  *"..."*|*"xxx"*|*"XXX"*) echo "✗ الرابط فيه نقاط نائبة — الصق الرابط الحقيقي من لوحة الشبكة"; exit 1;;
esac
case "$U" in *//*|http*) : ;; *) echo "✗ يجب أن يبدأ بـ // أو http"; exit 1;; esac
python3 - "$U" <<'PY'
import json,sys,os
u=sys.argv[1]; p="ads-config.json"
c=json.load(open(p,encoding="utf-8")) if os.path.exists(p) else {}
c["main"]=u
c.setdefault("adsterra",{})["popunder"]=u
json.dump(c,open(p,"w",encoding="utf-8"),indent=2,ensure_ascii=False)
print("✓ مُفعّل: %s"%u)
PY
ACT
chmod +x activate.sh; bash -n activate.sh && G "activate.sh سليم"

H "5/8 surveys.sh (يرفض TOKEN النصي)"
cat > surveys.sh <<'SUR'
#!/data/data/com.termux/files/usr/bin/bash
cd "$(dirname "$0")" || exit 1
P="${1:-}"; T="${2:-}"
case "$P" in
  bitlabs|cpx|pollfish|adgate|adgem|lootably|timewall) : ;;
  *) echo "الاستخدام: bash surveys.sh <bitlabs|cpx|pollfish|adgate|adgem|lootably|timewall> TOKEN"; exit 1;;
esac
[ -z "$T" ] && { echo "✗ التوكن فارغ"; exit 1; }
[ "$T" = "TOKEN" ] && { echo "✗ لصقت كلمة TOKEN حرفيًا — الصق التوكن الحقيقي من لوحة المزوّد"; exit 1; }
python3 - "$P" "$T" <<'PY'
import json,sys,os
k,t=sys.argv[1],sys.argv[2]; p="surveys-config.json"
c=json.load(open(p,encoding="utf-8")) if os.path.exists(p) else {}
c[k]=t; json.dump(c,open(p,"w",encoding="utf-8"),indent=2,ensure_ascii=False)
print("✓ %s مُفعّل"%k)
PY
SUR
chmod +x surveys.sh; bash -n surveys.sh && G "surveys.sh سليم"

H "6/8 indexnow.sh + ads.js v3"
cat > indexnow.sh <<'IDX'
#!/data/data/com.termux/files/usr/bin/bash
cd "$(dirname "$0")" || exit 1
python3 - <<'PY'
import re,glob,json,urllib.request,os
B="https://alkazmybwhwr-dot.github.io"
if not os.path.exists("sitemap.xml"): print("! لا sitemap.xml"); raise SystemExit
k=[os.path.basename(f)[:-4] for f in glob.glob("*.txt") if re.fullmatch(r"[0-9a-f]{32}\.txt",os.path.basename(f))]
if not k: print("! لا ملف مفتاح"); raise SystemExit
U=re.findall(r"<loc>(.*?)</loc>",open("sitemap.xml").read())[:900]
d=json.dumps({"host":"alkazmybwhwr-dot.github.io","key":k[0],
  "keyLocation":B+"/"+k[0]+".txt","urlList":U}).encode()
r=urllib.request.Request("https://api.indexnow.org/indexnow",data=d,
  headers={"Content-Type":"application/json; charset=utf-8"})
try: print("IndexNow:",urllib.request.urlopen(r,timeout=30).status,"·",len(U),"رابط")
except Exception as e: print("IndexNow:",e)
PY
IDX
chmod +x indexnow.sh
cat > ads.js <<'JS'
/* ads.js v3 — يدعم رابطًا واحدًا (main) أو شبكات متعددة */
(function(){
  var C=window.CH_ADS_CONFIG||{},D={};
  function L(s,p){if(!s||D[s])return;D[s]=1;var e=document.createElement("script");
    e.src=s;e.async=1;e.setAttribute("data-cfasync","false");(p||document.head).appendChild(e);}
  function pool(){return [C.main,C.adsterra&&C.adsterra.popunder,C.monetag&&C.monetag.vignette,
    C.propeller&&C.propeller.push,C.adcash&&C.adcash.popunder,
    C.hilltop&&C.hilltop.popunder,C.clickadu&&C.clickadu.popunder]
    .filter(Boolean).filter(function(v,i,a){return a.indexOf(v)===i});}
  addEventListener("load",function(){
    var p=pool();
    if(!p.length){console.warn("[ads] لا شبكة مُفعّلة — نفّذ: bash activate.sh");return;}
    L(p[0]); if(p[1])L(p[1]);
    if(C.adsterra&&C.adsterra.socialbar)L(C.adsterra.socialbar);
  },{once:1});
  function F(el){var k=el.getAttribute("data-ad"),
    s=(C.slots&&C.slots[k])||C.main||(C.adsterra&&C.adsterra.banner);
    if(!s||el.classList.contains("ad-filled"))return;
    el.classList.add("ad-filled");L(s,el);
    localStorage.setItem("ch_impressions",(+(localStorage.getItem("ch_impressions")||0))+1);}
  var io="IntersectionObserver"in window?new IntersectionObserver(function(es){es.forEach(function(e){
    if(e.isIntersecting){io.unobserve(e.target);F(e.target);}})},{rootMargin:"300px"}):null;
  function S(){var a=document.querySelectorAll("[data-ad]:not(.ad-filled)");
    for(var i=0;i<a.length;i++)io?io.observe(a[i]):F(a[i]);}
  document.readyState==="loading"?addEventListener("DOMContentLoaded",S):S();
  window.CH_rescanAds=S;
})();
JS
bash -n indexnow.sh && G "indexnow + ads.js v3"

H "7/8 تنظيف النصوص العربية من الإعدادات"
python3 - <<'PY'
import json,os,re
def bad(v): return bool(re.search(r"[\u0600-\u06FF]|TOKEN|\.\.\.|xxx|XXX|PUT-|YOUR",str(v)))
def fix(v):
    if isinstance(v,str): return "" if bad(v) else v
    if isinstance(v,dict): return {k:fix(x) for k,x in v.items()}
    if isinstance(v,list): return [fix(x) for x in v]
    return v
for f in ("ads-config.json","surveys-config.json","wallet.json","payouts.json"):
    if not os.path.exists(f): continue
    try: d=json.load(open(f,encoding="utf-8"))
    except Exception: continue
    json.dump(fix(d),open(f,"w",encoding="utf-8"),indent=2,ensure_ascii=False)
    print("  نُظّف",f)
PY
G "نُظّفت"

H "8/8 اختبار ذاتي"
python3 -m py_compile publish.py wallet.py 2>/dev/null && G "python سليم" || B "python خطأ"
for f in publish.sh wallet.sh activate.sh surveys.sh indexnow.sh; do bash -n "$f" 2>/dev/null || B "$f"; done
python3 -c "import json,glob;[json.load(open(f)) for f in glob.glob('*.json')]" 2>/dev/null && G "كل JSON سليم" || B "JSON تالف"
printf '\n\033[32m══ تم الإصلاح. الموقع حيّ: https://alkazmybwhwr-dot.github.io ══\033[0m\n'
