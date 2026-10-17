#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""ينشئ طلب سحب حقيقي عند بلوغ الحد ويقيّده في السجل"""
import json, os, datetime
ROOT=os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
def load(f,d):
    try: return json.load(open(os.path.join(ROOT,f),encoding="utf-8"))
    except Exception: return d
MIN=float(os.environ.get("MIN_WITHDRAW","5"))
t=load("treasury.json",{}); bal=float(t.get("balance") or 0)
w=load("withdrawal.json",{"requests":[]})
if bal>=MIN and not [r for r in w.get("requests",[]) if r.get("status")=="pending"]:
    now=datetime.datetime.now(datetime.timezone.utc).isoformat()
    req={"id":"w%d"%int(datetime.datetime.now().timestamp()),"amount":round(bal,6),
         "breakdown":t.get("buckets",{}),"status":"pending","created":now,
         "method":"Al-Kuraimi Bank (KBMFYESAXXX)",
         "to":load("owner.json",{}).get("kuraimi",{}),
         "wa":load("owner.json",{}).get("whatsapp","")}
    w.setdefault("requests",[]).append(req)
    json.dump(w,open(os.path.join(ROOT,"withdrawal.json"),"w"),ensure_ascii=False,indent=1)
    print("WITHDRAW",req["id"],req["amount"])
else:
    print("balance %.6f / min %.2f"%(bal,MIN))
