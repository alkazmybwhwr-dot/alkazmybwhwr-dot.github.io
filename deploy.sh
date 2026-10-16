#!/data/data/com.termux/files/usr/bin/bash
cd "$(dirname "$0")" || exit 1
BR="${1:-main}"; MSG="${2:-auto $(date -u +%FT%TZ)}"
git add -A; git diff --cached --quiet || git commit -q -m "$MSG"
for i in 1 2 3 4 5; do
  git fetch -q origin "$BR" 2>/dev/null
  if ! git rebase -q "origin/$BR" >/dev/null 2>&1; then
     git rebase --abort 2>/dev/null; git reset -q --soft "origin/$BR" 2>/dev/null && git commit -q -m "$MSG"
  fi
  OUT=$(git push origin "HEAD:$BR" 2>&1); RC=$?
  if [ $RC -eq 0 ]; then
     L=$(git rev-parse HEAD); Rm=$(git ls-remote origin "refs/heads/$BR" 2>/dev/null | cut -f1)
     [ "$L" = "$Rm" ] && { echo "  ✓ نُشر $L"; exit 0; }
  fi
  if echo "$OUT" | grep -qi 'workflow'; then
     echo "  ⚠ التوكن بلا صلاحية workflow — أنشر الموقع بدون .github"
     [ -d .github ] && mv .github .github.hold
     git add -A; git diff --cached --quiet || git commit -q -m "$MSG (site only)"
     if git push origin "HEAD:$BR" 2>/dev/null; then
        [ -d .github.hold ] && mv .github.hold .github
        echo "  ✓ نُشر الموقع · .github ينتظر صلاحية workflow"; exit 2
     fi
     [ -d .github.hold ] && mv .github.hold .github
  fi
  echo "    $OUT" | head -3; sleep $((i*6))
done
echo "  ✗ فشل النشر"; exit 1
