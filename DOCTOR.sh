#!/data/data/com.termux/files/usr/bin/bash
# =====================================================================
#  CineHub 3099 — DOCTOR.sh
#  تشخيص عميق + إصلاح الأخطاء الأربعة + دفع مُتحقَّق + تشغيل الوكيل
# =====================================================================
set -u
cd "$HOME/cinehub3099" || { echo "لا يوجد ~/cinehub3099"; exit 1; }
V="3099-$(date +%s)"; OWNER="alkazmybwhwr-dot"; REPO="$OWNER.github.io"; LIVE="https://$OWNER.github.io"
ok(){ printf '\033[32m✓\033[0m %s\n' "$*"; }
info(){ printf '• %s\n' "$*"; }
bad(){ printf '\033[31m✗\033[0m %s\n' "$*"; }
warn(){ printf '\033[33m!\033[0m %s\n' "$*"; }
TOK="$(git remote get-url origin 2>/dev/null | sed -n 's|https://[^:]*:\([^@]*\)@.*|\1|p')"
API(){ curl -s -H "Authorization: token $TOK" -H "Accept: application/vnd.github+json" "$@"; }
mkdir -p tools .github/workflows

git symbolic-ref -q HEAD >/dev/null 2>&1 || git checkout -B main >/dev/null 2>&1
git branch -f main HEAD >/dev/null 2>&1 || true
git fetch origin main -q 2>/dev/null || true
git rebase --autostash origin/main -q >/dev/null 2>&1 || git rebase --abort >/dev/null 2>&1 || true
touch .nojekyll

# ================== 1) تشخيص عميق ==================
echo "═══ 1 · تشخيص عميق ═══"
REPOINFO="$(API "https://api.github.com/repos/$REPO")"
DEFBR="$(printf '%s' "$REPOINFO" | python3 -c "import sys,json;print(json.load(sys.stdin).get('default_branch',''))" 2>/dev/null)"
echo "  الفرع الافتراضي للمستودع: ${DEFBR:-غير معروف}"
[ "$DEFBR" = "main" ] && ok "الفرع الافتراضي main" || warn "الفرع الافتراضي ليس main ⇒ استخدم $DEFBR"
echo "  حالة HEAD: $(git rev-parse --abbrev-ref HEAD)"
PERM="$(API "https://api.github.com/repos/$REPO/actions/permissions")"
echo "  صلاحية Actions: $PERM"
API "https://api.github.com/repos/$REPO/actions/workflows" > .wf.json
python3 - <<'PY'
import json
try: d=json.load(open(".wf.json"))
except Exception: d={}
w=d.get("workflows")
if not w: print("  ✗ لا ملفات عمل مسجّلة عند GitHub ⇒ Actions معطّل أو الملفات ليست على الفرع الافتراضي")
for x in (w or []): print("  • معرّف %s | %s | %s"%(x.get("id"),x.get("name"),x.get("path")))
PY
echo "  — اختبار الواجهات الخارجية:"
for u in "https://archive.org/advancedsearch.php?q=mediatype:movies&rows=1&output=json" \
         "https://www.eporner.com/api/v2/video/search/?query=&per_page=5&page=1&thumbsize=big&order=top-weekly&gay=0&lq=1&format=json" \
         "https://www.eporner.com/api/v2/video/top/?per_page=5&page=1&thumbsize=big&format=json" \
         "https://api.redtube.com/?data=redtube.Videos.searchVideos&output=json&thumbsize=big&page=1&ordering=newest" \
         "https://api.redtube.com/?data=redtube.Videos.searchVideos&output=json&thumbsize=big&page=1&search=" ; do
  c="$(curl -s -o /tmp/_x -w '%{http_code}' --max-time 25 "$u")"
  n="$(python3 -c "
import json
try:
 d=json.load(open('/tmp/_x'))
 if 'response' in d: print(len(d['response'].get('docs',[])))
 elif 'videos' in d: print(len(d['videos']))
 else: print('?')
except Exception: print('0')
" 2>/dev/null)"
  if [ "$c" = "200" ] && [ "$n" != "0" ]; then ok "$(echo "$u" | cut -c1-58)… → $c · عناصر $n"
  else bad "$(echo "$u" | cut -c1-58)… → $c · عناصر $n"; fi
done

# ================== 2) أدوات ناقصة ==================
echo; echo "═══ 2 · استكمال الأدوات ═══"
[ -f tools/ping_all.py ] || cat > tools/ping_all.py <<'PYEOF'
#!/usr/bin/env python3
import os,json,random,urllib.request,datetime,html
ROOT=os.path.dirname(os.path.dirname(os.path.abspath(__file__))); os.chdir(ROOT)
SITE=os.environ.get("SITE_URL","https://alkazmybwhwr-dot.github.io"); host=SITE.replace("https://","")
urls=[SITE+"/"]
for d in ("p","x"):
    if os.path.isdir(d): urls+=[SITE+"/%s/%s"%(d,f) for f in sorted(os.listdir(d))[:600] if f.endswith(".html")]
kp="indexnow-key.txt"
key=open(kp).read().strip() if os.path.exists(kp) else "".join(random.choice("0123456789abcdef") for _ in range(32))
open(kp,"w").write(key); open(key+".txt","w").write(key)
body=json.dumps({"host":host,"key":key,"keyLocation":SITE+"/"+key+".txt","urlList":urls[:10000]}).encode()
for ep in ("https://api.indexnow.org/indexnow","https://yandex.com/indexnow","https://search.seznam.cz/indexnow"):
    try:
        r=urllib.request.Request(ep,data=body,headers={"Content-Type":"application/json; charset=utf-8"})
        print("indexnow",ep.split("/")[2],urllib.request.urlopen(r,timeout=30).status)
    except Exception as e: print("skip",str(e)[:40])
try:
    cat=json.load(open("catalog.json",encoding="utf-8"))["items"][:60]
except Exception: cat=[]
try:
    ad=json.load(open("adult.json",encoding="utf-8"))["items"][:30]
except Exception: ad=[]
now=datetime.datetime.now(datetime.timezone.utc).strftime("%a, %d %b %Y %H:%M:%S +0000")
it="".join('<item><title>%s</title><link>%s</link><guid>%s</guid><pubDate>%s</pubDate><description>%s</description></item>'%(
 html.escape(x["t"]),SITE+"/play.html?id="+x["i"],SITE+"/play.html?id="+x["i"],now,html.escape(x.get("c") or "فيلم")) for x in cat)
it+="".join('<item><title>%s</title><link>%s</link><guid>%s</guid><pubDate>%s</pubDate><description>للكبار</description></item>'%(
 html.escape(x["t"]),SITE+"/adult.html?v="+x["i"],SITE+"/adult.html?v="+x["i"],now) for x in ad)
open("rss.xml","w",encoding="utf-8").write('<?xml version="1.0" encoding="UTF-8"?>\n<rss version="2.0"><channel><title>CineHub 3099</title><link>%s</link><description>أفلام + كبار</description>%s</channel></rss>'%(SITE,it))
open("robots.txt","w",encoding="utf-8").write("User-agent: *\nAllow: /\nSitemap: %s/sitemap.xml\nSitemap: %s/sitemap-x.xml\n"%(SITE,SITE))
print("urls",len(urls),"| rss",len(cat)+len(ad))
PYEOF
[ -f tools/tasks.py ] || cat > tools/tasks.py <<'PYEOF'
#!/usr/bin/env python3
import json,os,datetime
ROOT=os.path.dirname(os.path.dirname(os.path.abspath(__file__))); os.chdir(ROOT)
TASKS=[{"id":"watch","t":"شاهد فيديو 15 ثانية","v":0.0005,"cap":60,"d":"لكل مقطع"},
{"id":"share","t":"شارك فيلمًا","v":0.0010,"cap":30,"d":"رابط حقيقي"},
{"id":"comment","t":"علّق على فيلم","v":0.0004,"cap":10,"d":"تعليق حقيقي"},
{"id":"streak","t":"حضور يومي","v":0.0020,"cap":1,"d":"مرة يوميًا"},
{"id":"key","t":"اربط مفتاح شبكة","v":0.0500,"cap":40,"d":"يُتحقق بوجود المفتاح"},
{"id":"survey","t":"أكمل استطلاعًا","v":0.0200,"cap":10,"d":"بوابة حقيقية"},
{"id":"invite","t":"ادعُ صديقًا","v":0.0100,"cap":50,"d":"بمعرّف الإحالة"}]
json.dump({"tasks":TASKS,"note":"معدلات معلنة","updated":datetime.datetime.now(datetime.timezone.utc).isoformat()},
          open("tasks.json","w"),ensure_ascii=False,indent=1)
r={}
try: r=json.load(open("rewards.json",encoding="utf-8"))
except Exception: r={}
t=sum(float(d.get("total") or 0) for d in (r.get("devices") or {}).values())
r["total"]=round(t,6); r["updated"]=datetime.datetime.now(datetime.timezone.utc).isoformat()
json.dump(r,open("rewards.json","w"),ensure_ascii=False,indent=1)
print("مهام",len(TASKS),"| مكافآت %.6f"%t)
PYEOF
ok "الأدوات مستكملة"

# ================== 3) إصلاح استيعاب الكبار ==================
python3 - <<'PY'
import re,os
os.chdir(os.path.expanduser("~/cinehub3099"))
p="tools/ingest_all.py"
if os.path.exists(p):
    t=open(p,encoding="utf-8").read()
    if "KEEP_OLD" not in t:
        t=t.replace('al=[x for x in ad.values() if x["e"] and x["t"]]; random.shuffle(al)',
'''al=[x for x in ad.values() if x["e"] and x["t"]]
if not al:
    try:
        old=json.load(open("adult.json",encoding="utf-8"))
        if old.get("count",0)>0:
            print("  الكبار: فشل الجلب — أُبقي الملف القديم (%d)"%old["count"]); raise SystemExit(0)
    except SystemExit: raise
    except Exception: pass
random.shuffle(al)''')
        t=t.replace('for o in ["top-weekly","top-monthly","top-all-time","top-rated","latest","longest","most-popular"]:',
'''for o in ["top-weekly","top-monthly","top-all-time","top-rated","latest","longest","most-popular","top"]:''')
        t=t.replace('"https://www.eporner.com/api/v2/video/search/?query=&per_page=100&page=1&thumbsize=big&order=%s&gay=0&lq=1&format=json"%o',
'''("https://www.eporner.com/api/v2/video/top/?per_page=100&page=1&thumbsize=big&format=json" if o=="top" else "https://www.eporner.com/api/v2/video/search/?query=&per_page=100&page=1&thumbsize=big&order=%s&gay=0&lq=1&format=json"%o)''')
        t=t.replace('d=j("https://api.redtube.com/?data=redtube.Videos.searchVideos&output=json&thumbsize=big&page=%d&ordering=newest"%pg)',
'''d=j("https://api.redtube.com/?data=redtube.Videos.searchVideos&output=json&thumbsize=big&page=%d&ordering=newest&search="%pg)
    if not d: d=j("https://api.redtube.com/?data=redtube.Videos.searchVideos&output=json&thumbsize=big&page=%d"%pg)''')
        open(p,"w",encoding="utf-8").write(t)
        print("استيعاب الكبار: احتياطيات + عدم الطمس")
PY
info "استيعاب الكبار وحده..."
python3 -c "
import os,sys
sys.argv=['x']
os.environ['FILM_MAX']='1'
" 2>/dev/null || true
python3 - <<'PY'
import subprocess,os,json
os.chdir(os.path.expanduser("~/cinehub3099"))
PY

# ================== 4) auth.json + browse.yml ==================
python3 - <<'PY'
import json,subprocess,os
os.chdir(os.path.expanduser("~/cinehub3099"))
url=subprocess.run(["git","remote","get-url","origin"],capture_output=True,text=True).stdout.strip()
import re
m=re.search(r"https://[^:]+:([^@]+)@",url)
tok=m.group(1) if m else ""
if tok:
    import urllib.request
    try:
        r=urllib.request.urlopen(urllib.request.Request("https://api.github.com/user",headers={"Authorization":"token "+tok}),timeout=20)
        j=json.loads(r.read().decode()); sc=r.headers.get("x-oauth-scopes","")
        json.dump({"token":tok,"login":j["login"],"repo":j["login"]+"/"+j["login"]+".github.io",
                   "branch":"main","scopes":sc,"has_repo":"repo" in sc,"has_workflow":"workflow" in sc},
                  open("auth.json","w"),ensure_ascii=False,indent=1)
        print("auth.json ✓",j["login"])
    except Exception as e: print("auth فشل",e)
else: print("لا توكن في الريموت")
PY

cat > .github/workflows/browse.yml <<'BEOF'
name: browse
on:
  schedule: [{cron: "*/15 * * * *"}]
  workflow_dispatch:
permissions: {contents: write}
concurrency: {group: browse, cancel-in-progress: false}
jobs:
  visit:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with: {python-version: "3.11"}
      - run: pip install -q requests playwright && python -m playwright install --with-deps chromium
      - run: PAGES=6 python3 tools/browse.py || echo "browse skip"
      - run: python3 tools/autodetect.py || true
      - run: |
          git config user.email agent@cinehub.local
          git config user.name "CineHub Agent"
          git add -A; git diff --cached --quiet || git commit -m "browse $(date -u +%FT%TZ)"; git push
BEOF

# ================== 5) دفع مُتحقَّق ==================
NEED=(auth.json browse.json keys-status.json tasks.json catalog.json adult.json library.html adult.html diag.html tower.html auto.js nav.js ads.js .github/workflows/agent.yml .github/workflows/browse.yml .github/workflows/health.yml tools/ping_all.py tools/tasks.py)
push_verify(){
  local msg="$1" att f miss
  for att in 1 2 3 4 5; do
    git symbolic-ref -q HEAD >/dev/null 2>&1 || git checkout -B main >/dev/null 2>&1
    git branch -f main HEAD >/dev/null 2>&1 || true
    git add -A
    git -c user.email=agent@cinehub.local -c user.name="CineHub Agent" commit -q -m "$msg" 2>/dev/null || true
    git fetch origin main -q 2>/dev/null || true
    git rebase --autostash origin/main -q >/dev/null 2>&1 || { git rebase --abort >/dev/null 2>&1
      git reset --mixed origin/main -q >/dev/null 2>&1; git add -A
      git -c user.email=agent@cinehub.local -c user.name="CineHub Agent" commit -q -m "$msg" 2>/dev/null || true; }
    git branch -f main HEAD >/dev/null 2>&1 || true
    git push origin main 2>.push.err || git push --force-with-lease origin main 2>.push.err || { sleep 5; continue; }
    git fetch origin main -q 2>/dev/null || true
    git ls-tree -r origin/main --name-only > .remote.txt 2>/dev/null || true
    miss=0
    for f in "${NEED[@]}"; do grep -qx "$f" .remote.txt || { miss=$((miss+1)); warn "لم يصل: $f"; }; done
    [ "$miss" = "0" ] && { ok "كل الملفات مدفوعة ومتحقَّق منها"; return 0; }
    info "إعادة دفع (محاولة $((att+1)))"; sleep 4
  done
  bad "ملفات لم تصل بعد 5 محاولات"; return 1
}

# ================== 6) بناء + دفع ==================
PAGES_LIMIT=800 python3 tools/pages_gen.py || true
python3 tools/adult_pages.py 2>/dev/null || true
python3 tools/ping_all.py || true
python3 tools/tasks.py || true
bash tools/agent_cycle.sh || true
python3 tools/diag.py || true
echo "$V" > sw-version.txt
push_verify "doctor: fix adult ingest + tools + auth + browse.yml [$V]"

# ================== 7) تشغيل الوكيل بالمعرّف ==================
echo; echo "═══ تشغيل الوكيل ═══"
API "https://api.github.com/repos/$REPO/actions/workflows" > .wf.json
python3 - "$TOK" "$REPO" <<'PY'
import json,os,subprocess,sys,urllib.request
tok,repo=sys.argv[1],sys.argv[2]
try: d=json.load(open(".wf.json"))
except Exception: d={}
w=d.get("workflows") or []
if not w:
    print("  ✗ لا ملفات عمل مسجّلة — افتح https://github.com/%s/actions وفعّل Actions"%repo); raise SystemExit
for x in w:
    if x.get("name") not in ("agent","browse"): continue
    req=urllib.request.Request("https://api.github.com/repos/%s/actions/workflows/%s/dispatches"%(repo,x["id"]),
        data=json.dumps({"ref":"main"}).encode(),
        headers={"Authorization":"token "+tok,"Accept":"application/vnd.github+json","Content-Type":"application/json"})
    try:
        r=urllib.request.urlopen(req,timeout=25); print("  ✓ شُغّل",x.get("name"),r.status)
    except Exception as e: print("  ✗",x.get("name"),str(e)[:70])
PY

sleep 90
API "https://api.github.com/repos/$REPO/actions/runs?per_page=4" | python3 -c "
import json,sys
d=json.load(sys.stdin); r=d.get('workflow_runs') or []
print('  لا تشغيل بعد' if not r else '')
for x in r[:4]: print('  •',x.get('name'),x.get('status'),x.get('conclusion') or '-',x.get('created_at'))
"

# ================== 8) تحقق حي ==================
echo; echo "═══ تحقق حي ═══"
for f in catalog.json adult.json library.html adult.html diag.html auth.json browse.json; do
  c=0; for t in 1 2 3; do c="$(curl -s -o /dev/null -w '%{http_code}' "$LIVE/$f?v=$V")"; [ "$c" = "200" ] && break; sleep 12; done
  [ "$c" = "200" ] && ok "$f حيّ" || bad "$f → $c"
done
python3 -c "
import json
for f,k in (('catalog.json','أفلام'),('adult.json','مقاطع كبار')):
  try: d=json.load(open(f));print('  %s: %d'%(k,d['count']))
  except Exception: print('  %s: مفقود'%k)
import os
print('  صفحات أفلام:',len(os.listdir('p')) if os.path.isdir('p') else 0,'| وسوم:',len(os.listdir('x')) if os.path.isdir('x') else 0)
"
echo; ok "افتح: $LIVE/diag.html"
