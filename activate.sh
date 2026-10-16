#!/data/data/com.termux/files/usr/bin/bash
cd "$(dirname "$0")" || exit 1
U="${1:-}"
if [ -z "$U" ]; then echo "الاستخدام: bash activate.sh \"//pl12345.profitablecpmrate.com/xx/xx/xx/invoke.js\""; exit 1; fi
case "$U" in
  *[!a-zA-Z0-9/._:\&\?=-]*) echo "✗ الرابط فيه رموز غريبة (نص عربي؟): $U"; exit 1;;
esac
case "$U" in
  *"..."*|*"xxx"*|*"XXX"*) echo "✗ الرابط فيه نقاط نائبة — الصق الرابط الحقيقي من لوحة الشبكة"; exit 1;;
esac
case "$U" in *//*|http*) : ;; *) echo "✗ يجب أن يبدأ بـ // أو http"; exit 1;; esac
python3 - "$U" <<'PY'
import json,sys,os
u=sys.argv[1]; p="ads-config.json"
c=json.load(open(p,encoding="utf-8")) if os.path.exists(p) else {}
c["main"]=u
c.setdefault("adsterra",{})["popunder"]=u
json.dump(c,open(p,"w",encoding="utf-8"),indent=2,ensure_ascii=False)
print("✓ مُفعّل: %s"%u)
PY
