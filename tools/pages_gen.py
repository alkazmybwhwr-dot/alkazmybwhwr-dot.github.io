#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""يولّد صفحات ثابتة long-tail لكل فيلم/عنصر + sitemap + robots + IndexNow"""
import os, re, json, random, string, urllib.request, html as H

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT  = os.path.join(ROOT, "p")
SITE = os.environ.get("SITE_URL", "https://alkazmybwhwr-dot.github.io")
LIMIT = int(os.environ.get("PAGES_LIMIT", "300"))
KINDS = ["فيلم كلاسيكي","فيلم قصير","وثائقي","رسوم متحركة","فيلم نوار","تحفة صامتة","فيلم مغامرات","دراما"]
NETS = ["Adsterra","Monetag","PropellerAds","PopAds","AdMaven","HilltopAds","Evadav","Clickadu",
        "Linkvertise","ShrinkMe","CPAGrip","OGAds","BitLabs","CPX Research","AdGate","Lootably"]

def slug(s):
    s = re.sub(r"[^\w\s-]", "", s, flags=re.U).strip().lower()
    return (re.sub(r"[\s_]+", "-", s)[:60] or "item")

def load():
    items = []
    for f in ("films.json","catalog.json","library.json","platforms.json","entities.json"):
        p = os.path.join(ROOT, f)
        if not os.path.exists(p): continue
        try: d = json.load(open(p, encoding="utf-8"))
        except Exception: continue
        bag = d if isinstance(d, list) else []
        if isinstance(d, dict):
            for k in ("items","films","list","networks","entities","results","data"):
                if isinstance(d.get(k), list): bag += d[k]
        items += [x for x in bag if isinstance(x, dict)]
    seen, out = set(), []
    for x in items:
        t = (x.get("title") or x.get("name") or "").strip()
        if not t: continue
        s = slug(t)
        if s in seen: continue
        seen.add(s); out.append((s, t, x))
    return out

TPL = """<!doctype html><html lang="ar" dir="rtl"><head>
<meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>{t} — مشاهدة مجانية وربح | CineHub 3099</title>
<meta name="description" content="{d}">
<link rel="canonical" href="{site}/p/{s}.html">
<meta property="og:title" content="{t} — CineHub 3099"><meta property="og:type" content="video.movie">
<meta property="og:description" content="{d}">
<script type="application/ld+json">{{"@context":"https://schema.org","@type":"Movie","name":{tj},"genre":{kj},"inLanguage":"ar","url":"{site}/p/{s}.html"}}</script>
<style>body{{font-family:system-ui,Tahoma,sans-serif;background:#0b0f14;color:#e8eef6;margin:0;padding:16px;line-height:1.7}}
a{{color:#5cc8ff}}.box{{background:#111a24;border:1px solid #1e2937;border-radius:10px;padding:12px;margin:12px 0}}
.ad{{background:#0e1620;border:1px dashed #2a3a4d;border-radius:8px;padding:10px;text-align:center;font-size:13px;color:#8aa}}
.btn{{display:inline-block;background:#134;color:#9fe;border:1px solid #2a6;border-radius:8px;padding:9px 14px;text-decoration:none;margin:4px}}</style>
</head><body>
<h1>{t}</h1>
<p>{d}</p>
<div class="ad" data-net="{n1}">إعلان — {n1}</div>
<p><a class="btn" href="../auto.html">▶ شاهد واقبض</a><a class="btn" href="../play.html?t={sj}">صفحة الفيلم</a><a class="btn" href="../index.html">الرئيسية</a></p>
<div class="box"><h3>تفاصيل</h3><p>النوع: {k}<br>اللغة: العربية/الأصلية<br>الحقوق: ملك عام / مرخّص<br>المصدر: {src}</p></div>
<div class="ad" data-net="{n2}">إعلان — {n2}</div>
<h3>مشاهدات مقترحة</h3><ul>{rel}</ul>
<div class="box"><h3>اربح من نفس الصفحة</h3><p>كل مشاهدة إعلان 15 ثانية = ربح مباشر لرصيدك، وسحب من $5 إلى بنك الكريمي (KBMFYESAXXX).</p></div>
<script>(function(){{try{{fetch('https://abacus.jasoncameron.dev/hit/ch3099-{s}').catch(function(){{}});}}catch(e){{}}}})();</script>
</body></html>"""

def main():
    items = load()
    if not items:
        print("لا عناصر — شغّل SCALE.sh أولًا"); return
    os.makedirs(OUT, exist_ok=True)
    take = items[:LIMIT]
    urls = []
    for i, (s, t, x) in enumerate(take):
        kind = KINDS[i % len(KINDS)]
        desc = ("مشاهدة %s مجانًا داخل CineHub 3099 — %s قانوني بجودة عالية، مع أرباح مباشرة لكل مشاهدة "
                "وسحب إلى بنك الكريمي. تصنيف: %s.") % (t, kind, kind)
        src = x.get("source") or x.get("provider") or "Archive / Public Domain"
        rel = ""
        for j in range(1, 9):
            ss, tt, _ = take[(i + j * 7) % len(take)]
            rel += '<li><a href="%s.html">%s</a></li>' % (ss, H.escape(tt))
        page = TPL.format(t=H.escape(t), s=s, d=H.escape(desc), k=kind, kj=json.dumps(kind, ensure_ascii=False),
                          tj=json.dumps(t, ensure_ascii=False), sj=urllib.parse.quote(t), site=SITE,
                          n1=NETS[i % len(NETS)], n2=NETS[(i + 5) % len(NETS)], src=H.escape(str(src)), rel=rel)
        open(os.path.join(OUT, s + ".html"), "w", encoding="utf-8").write(page)
        urls.append("%s/p/%s.html" % (SITE, s))
    open(os.path.join(ROOT, "sitemap.xml"), "w", encoding="utf-8").write(
        '<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n'
        + "".join("  <url><loc>%s</loc></url>\n" % u for u in [SITE + "/"] + urls)
        + "</urlset>\n")
    open(os.path.join(ROOT, "robots.txt"), "w", encoding="utf-8").write(
        "User-agent: *\nAllow: /\nSitemap: %s/sitemap.xml\n" % SITE)
    # IndexNow (يُبلّغ محركات البحث فورًا)
    kp = os.path.join(ROOT, "indexnow-key.txt")
    key = open(kp).read().strip() if os.path.exists(kp) else "".join(random.choice("0123456789abcdef") for _ in range(32))
    open(kp, "w").write(key); open(os.path.join(ROOT, key + ".txt"), "w").write(key)
    try:
        req = urllib.request.Request("https://api.indexnow.org/indexnow",
            data=json.dumps({"host": SITE.replace("https://", ""), "key": key,
                             "keyLocation": SITE + "/" + key + ".txt", "urlList": urls[:10000]}).encode(),
            headers={"Content-Type": "application/json; charset=utf-8"})
        print("indexnow:", urllib.request.urlopen(req, timeout=30).status)
    except Exception as e:
        print("indexnow skip:", e)
    print("pages:", len(urls))

import urllib.parse
if __name__ == "__main__": main()
