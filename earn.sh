#!/data/data/com.termux/files/usr/bin/bash
cd "$HOME/cinehub3099" || exit 1
CPM="${CPM:-1.0}"
while :; do
  python3 - "$CPM" <<'PY'
import json,sys,time
rate=float(sys.argv[1])/1000*0.70
p="wallet.json"
try: w=json.load(open(p))
except: w={}
w.setdefault("address","0x7AcC22Ed0d07dd775D4456a29011Ff1440945CbB")
for k in ("balance","pending","views"): w.setdefault(k,0.0)
w["views"]=w["views"]+1
inc=round(rate,6)
w["pending"]=round(w["pending"]+inc,6); w["balance"]=round(w["balance"]+inc,6)
w["lastTick"]=int(time.time()); w["updated"]=time.strftime("%Y-%m-%d %H:%M:%S")
w.setdefault("history",[]).append({"t":w["updated"],"d":inc}); w["history"]=w["history"][-720:]
json.dump(w,open(p,"w"),ensure_ascii=False,indent=2)
print(w["updated"],"+%.6f"%inc,"=> %.6f"%(w["balance"]))
PY
  git add wallet.json >/dev/null 2>&1
  git commit -qm "earn $(date +%H:%M)" >/dev/null 2>&1
  git push -q origin main >/dev/null 2>&1 || true
  sleep 3600
done
