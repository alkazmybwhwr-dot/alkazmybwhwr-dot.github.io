#!/usr/bin/env python3
# CineHub 3099 — نشر تلقائي على GitHub Pages عبر مصادقة رمز الجهاز (Device Flow)
# بلا npm · بلا git · بلا بناء على الجهاز
import os, sys, json, time, base64
from urllib.request import Request, urlopen
from urllib.error import HTTPError

CLIENT_ID = "178c6fc778ccc68e1d6a"          # تطبيق GitHub CLI العام (جهاز عام، بلا سر)
SCOPE     = "repo"
HERE = os.path.dirname(os.path.abspath(__file__))
ENVF = os.path.expanduser("~/.ghenv")
SKIP = {"deploy.py", "deploy.sh", "gh.py", "fix-npm.sh", "README.md",
        "supabase.sql", "mkog.py", ".cfenv", ".ghenv"}

def post_form(url, fields):
    data = "&".join(f"{k}={v}" for k, v in fields.items()).encode()
    h = {"Accept": "application/json", "User-Agent": "cinehub",
         "Content-Type": "application/x-www-form-urlencoded"}
    with urlopen(Request(url, data=data, headers=h, method="POST")) as r:
        return json.loads(r.read())

def api(method, path, token, body=None, soft=False):
    h = {"Accept": "application/vnd.github+json", "User-Agent": "cinehub",
         "Authorization": f"Bearer {token}", "X-GitHub-Api-Version": "2022-11-28"}
    data = json.dumps(body).encode() if body is not None else None
    if data: h["Content-Type"] = "application/json"
    req = Request("https://api.github.com" + path, data=data, headers=h, method=method)
    try:
        with urlopen(req) as r:
            raw = r.read()
            return json.loads(raw) if raw else {}
    except HTTPError as e:
        raw = e.read()
        if soft: return {"_status": e.code, "_body": raw}
        try: msg = json.loads(raw).get("message", raw[:200])
        except Exception: msg = raw[:200]
        print(f"✗ {method} {path} → {e.code}: {msg}"); raise SystemExit(1)

def do_login():
    if os.path.exists(ENVF):
        tok = open(ENVF).read().strip()
        if tok:
            who = api("GET", "/user", tok, soft=True)
            if who.get("login"):
                print(f"✓ مصادق سابقًا: @{who['login']}"); return tok, who["login"]
    d = post_form("https://github.com/login/device/code",
                  {"client_id": CLIENT_ID, "scope": SCOPE})
    print()
    print("  ╔═══════════════════════════════════════════════╗")
    print(f"  ║   الرمز:   {d['user_code']:<34}║")
    print("  ╚═══════════════════════════════════════════════╝")
    print(f"\n  1) افتح: {d['verification_uri']}")
    print("  2) الصق الرمز  →  Authorize  (أكمل الكابتشا لو طلبتها)")
    print("  3) السكربت ينتظرك هنا…\n")
    interval = d.get("interval", 5); deadline = time.time() + d.get("expires_in", 900)
    while time.time() < deadline:
        time.sleep(interval)
        try:
            t = post_form("https://github.com/login/oauth/access_token",
                          {"client_id": CLIENT_ID, "device_code": d["device_code"],
                           "grant_type": "urn:ietf:params:oauth:grant-type:device_code"})
        except HTTPError:
            continue
        if t.get("access_token"):
            tok = t["access_token"]
            who = api("GET", "/user", tok)
            with open(ENVF, "w") as f: f.write(tok)
            os.chmod(ENVF, 0o600)
            print(f"✓ تمت المصادقة: @{who['login']}")
            return tok, who["login"]
        err = t.get("error")
        if err == "slow_down": interval += 5
        elif err == "access_denied": print("✗ رفضت التصريح."); raise SystemExit(1)
        elif err == "expired_token": print("✗ انتهت صلاحية الرمز، أعد التشغيل."); raise SystemExit(1)
    print("✗ انتهى الوقت."); raise SystemExit(1)

def main():
    token, login = do_login()
    repo = os.environ.get("REPO", f"{login}.github.io")
    r = api("GET", f"/repos/{login}/{repo}", token, soft=True)
    if r.get("_status") == 404:
        print(f"→ إنشاء المستودع العام: {repo} …")
        r = api("POST", "/user/repos", token,
                {"name": repo, "private": False, "auto_init": True,
                 "description": "CineHub 3099"})
    branch = r.get("default_branch", "main")

    files = []
    for root, _, names in os.walk(HERE):
        for n in names:
            if n in SKIP or n.startswith("."): continue
            p = os.path.join(root, n)
            files.append((os.path.relpath(p, HERE).replace(os.sep, "/"), open(p, "rb").read()))
    files.append((".nojekyll", b""))
    if not files: print("✗ لا ملفات للنشر"); raise SystemExit(1)

    print(f"→ رفع {len(files)} ملف إلى {branch} …")
    for rel, data in files:
        cur = api("GET", f"/repos/{login}/{repo}/contents/{rel}", token, soft=True)
        body = {"message": f"deploy {rel}",
                "content": base64.b64encode(data).decode(), "branch": branch}
        if cur.get("sha"): body["sha"] = cur["sha"]
        api("PUT", f"/repos/{login}/{repo}/contents/{rel}", token, body)
        print("   ✓", rel)

    src = {"source": {"branch": branch, "path": "/"}}
    st = api("POST", f"/repos/{login}/{repo}/pages", token, src, soft=True)
    if st.get("_status") in (409, 422):
        api("PUT", f"/repos/{login}/{repo}/pages", token, src, soft=True)

    url = f"https://{login}.github.io" + ("" if repo == f"{login}.github.io" else f"/{repo}")
    print("\n→ GitHub يبني الموقع…")
    for _ in range(45):
        time.sleep(6)
        b = api("GET", f"/repos/{login}/{repo}/pages/builds/latest", token, soft=True)
        if b.get("status") == "built": break
        if b.get("status") == "errored":
            print("⚠ فشل البناء — راجع تبويب Actions في المستودع."); break
        print("   … بناء")
    print("\n✅ تم كل شيء.")
    print("   الموقع:", url)
    print("   المستودع: https://github.com/%s/%s" % (login, repo))

if __name__ == "__main__":
    main()
