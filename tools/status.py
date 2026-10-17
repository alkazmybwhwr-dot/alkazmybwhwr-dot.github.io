#!/usr/bin/env python3
import json, os, datetime
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
st = {"engine": "live", "updated": datetime.datetime.now(datetime.timezone.utc).isoformat()}
for f, k in (("revenue.json","revenue"), ("ledger.json","ledger"), ("platforms.json","platforms")):
    try: st[k] = json.load(open(os.path.join(ROOT, f), encoding="utf-8"))
    except Exception: pass
json.dump(st, open(os.path.join(ROOT, "status.json"), "w"), ensure_ascii=False, indent=1)
print("status ok")
