#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""يجمع كل مصادر الدخل في خزينة واحدة بفروع صريحة"""
import json, os, datetime
ROOT=os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
def load(f,d):
    try: return json.load(open(os.path.join(ROOT,f),encoding="utf-8"))
    except Exception: return d
def pick(d):
    if not isinstance(d,dict): return 0.0
    for k in ("total","amount","balance","usd","earnings","revenue","pending"):
        if d.get(k) is not None:
            try: return round(float(d[k]),6)
            except Exception: pass
    return 0.0
SRC={"ads":"revenue.json","rewards":"rewards.json","commissions":"commissions.json",
     "gifts":"gifts.json","surveys":"surveys.json","links":"links.json","referral":"refs.json"}
b={k:pick(load(f,{})) for k,f in SRC.items()}
tot=round(sum(b.values()),6)
out={"buckets":b,"balance":tot,"withdrawable":tot,"min":5.0,
     "updated":datetime.datetime.now(datetime.timezone.utc).isoformat(),
     "note":"كل رقم مقروء من ملف مصدره — لا تقدير"}
json.dump(out,open(os.path.join(ROOT,"treasury.json"),"w"),ensure_ascii=False,indent=1)
print("treasury",tot,b)
