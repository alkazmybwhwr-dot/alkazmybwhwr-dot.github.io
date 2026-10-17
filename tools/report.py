#!/usr/bin/env python3
import json,os,datetime
ROOT=os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
def L(f,d):
    try: return json.load(open(os.path.join(ROOT,f),encoding="utf-8"))
    except Exception: return d
t=L("treasury.json",{}); p=L("pulse.json",{}); led=L("ledger.json",{})
rows=["# تقرير CineHub 3099 — "+datetime.date.today().isoformat(),"",
      "الرصيد: $%.6f"%(t.get("balance") or 0),"", "## الفروع"]
for k,v in (t.get("buckets") or {}).items(): rows.append("- %s: $%.6f"%(k,v))
rows+=["","الدورات: %s"%(p.get("cycle",0)),"القيود: %s"%(len(led.get("entries",[])) if isinstance(led,dict) else 0)]
open(os.path.join(ROOT,"report.md"),"w",encoding="utf-8").write("\n".join(rows))
print("report ok")
