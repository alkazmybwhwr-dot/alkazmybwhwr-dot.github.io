#!/data/data/com.termux/files/usr/bin/bash
# ask <نوع-التحقق> <السؤال> <القيمة-الحالية> <مطلوب؟>  → يطبع القيمة النهائية
T="$1"; Q="$2"; CUR="$3"; REQ="${4:-0}"
while :; do
  if [ -n "$CUR" ]; then printf '  %s [%s] : ' "$Q" "$CUR"; else printf '  %s : ' "$Q"; fi
  read -r IN
  [ -z "$IN" ] && IN="$CUR"
  if [ -z "$IN" ]; then
    if [ "$REQ" = "1" ]; then printf '    ↳ مطلوب — أعد الإدخال\n'; continue; fi
    echo ""; return
  fi
  RES=$(python3 tools/ask_helper.py "$T" "$IN" 2>/dev/null)
  OKV=$(printf '%s' "$RES" | sed -n 's/.*"ok": *\(true\|false\).*/\1/p')
  if [ "$OKV" = "true" ]; then
    printf '    \033[32m✓ صحيح\033[0m %s\n' "$(printf '%s' "$RES" | sed -n 's/.*"extra": *"\([^"]*\)".*/\1/p')"
    echo "$IN"; return
  else
    printf '    \033[31m✗ غير صحيح\033[0m %s\n' "$(printf '%s' "$RES" | sed -n 's/.*"err": *"\([^"]*\)".*/\1/p')"
    [ "$REQ" = "1" ] || { printf '    (Enter = قبوله كما هو)\n'; read -r f; [ -n "$f" ] || { echo "$IN"; return; }; }
  fi
done
