#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""سجل موقّع بسلسلة SHA-256: أي تعديل يدوي يكسر السلسلة"""
import json, os, hashlib, datetime
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__))); os.chdir(ROOT)
def L(f, d):
    try: return json.load(open(f, encoding="utf-8"))
    except Exception: return d
led = L("ledger.json", {"entries": [], "last": "GENESIS"})
snap = {"t": datetime.datetime.now(datetime.timezone.utc).isoformat(),
        "counts": L("counts.json", {}), "revenue": L("revenue.json", {}), "treasury": L("treasury.json", {})}
prev = led.get("last", "GENESIS")
h = hashlib.sha256((prev + json.dumps(snap, sort_keys=True, ensure_ascii=False)).encode("utf-8")).hexdigest()
led["entries"].append({"i": len(led["entries"]) + 1, "t": snap["t"], "prev": prev, "h": h, "snap": snap})
led["entries"] = led["entries"][-3000:]
led["last"] = h
json.dump(led, open("ledger.json", "w"), ensure_ascii=False, indent=1)
print("ledger", len(led["entries"]), h[:12])
