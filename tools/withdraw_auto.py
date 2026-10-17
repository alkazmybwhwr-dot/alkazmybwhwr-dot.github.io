#!/usr/bin/env python3
"""ينشئ طلب سحب تلقائي عند بلوغ الحد ويكتبه في السجل"""
import json, os, datetime
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
def load(f, d):
    try: return json.load(open(os.path.join(ROOT, f), encoding="utf-8"))
    except Exception: return d
MIN = float(os.environ.get("MIN_WITHDRAW", "5"))
tre = load("treasury.json", {}); bal = float(tre.get("balance") or tre.get("withdrawable") or 0)
w = load("withdrawal.json", {"requests": []})
pend = [r for r in w.get("requests", []) if r.get("status") == "pending"]
if bal >= MIN and not pend:
    now = datetime.datetime.now(datetime.timezone.utc).isoformat()
    req = {"id": "w%d" % int(datetime.datetime.now().timestamp()), "amount": round(bal, 6),
           "status": "pending", "created": now, "method": "Al-Kuraimi Bank (KBMFYESAXXX)",
           "to": load("owner.json", {}).get("kuraimi", {})}
    w.setdefault("requests", []).append(req)
    json.dump(w, open(os.path.join(ROOT, "withdrawal.json"), "w"), ensure_ascii=False, indent=1)
    print("WITHDRAW REQUEST", req["id"], req["amount"])
else:
    print("balance %.6f / min %.2f / pending %d" % (bal, MIN, len(pend)))
