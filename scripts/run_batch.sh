#!/usr/bin/env bash
set -euo pipefail

BATCH_SIZE="${BATCH_SIZE:-10}"
DELAY_SECONDS="${DELAY_SECONDS:-8}"
MAX_REPO_PRS="${MAX_REPO_PRS:-1005}"
COAUTHOR_TRAILER="${COAUTHOR_TRAILER:-}"

if ! [[ "$BATCH_SIZE" =~ ^[0-9]+$ ]] || [ "$BATCH_SIZE" -lt 1 ] || [ "$BATCH_SIZE" -gt 30 ]; then
  echo "::error::BATCH_SIZE phải nằm trong khoảng 1..30 (hiện tại: $BATCH_SIZE) để tránh GitHub Secondary Rate Limit."
  exit 1
fi

git config user.name "William Cachamwri"
git config user.email "2741582+williamcachamwri@users.noreply.github.com"

mkdir -p data
touch data/counter.txt data/changelog.log

completed=0

for ((i = 1; i <= BATCH_SIZE; i++)); do
  git checkout main
  git pull --ff-only origin main

  current=$(tr -d '[:space:]' < data/counter.txt)
  current="${current:-0}"

  if [ "$current" -ge "$MAX_REPO_PRS" ]; then
    echo "🎉 Đã đạt mục tiêu ${current}/${MAX_REPO_PRS} PR trên repo này (đủ 1,024+ tổng PR cho Pull Shark Gold). Dừng tự động."
    break
  fi

  next=$((current + 1))
  ts=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  branch="chore/sync-${next}-$(date +%s)"

  git checkout -b "$branch"

  echo "$next" > data/counter.txt
  echo "[${ts}] sync #${next}" >> data/changelog.log
  tail -n 100 data/changelog.log > data/changelog.tmp && mv data/changelog.tmp data/changelog.log

  git add data/counter.txt data/changelog.log

  commit_msg="chore(sync): update checkpoint #${next}"
  if [ -n "$COAUTHOR_TRAILER" ]; then
    git commit -m "$commit_msg" -m "Co-authored-by: ${COAUTHOR_TRAILER}"
  else
    git commit -m "$commit_msg"
  fi

  git push -u origin "$branch"
  sleep 3

  pr_url=$(gh pr create \
    --base main \
    --head "$branch" \
    --title "chore(sync): checkpoint #${next}" \
    --body "Automated checkpoint sync #${next} (${ts}).")

  echo "Created PR: $pr_url"

  merged=false
  for attempt in 1 2 3 4; do
    sleep $((attempt * 3))
    if gh pr merge "$pr_url" --merge --delete-branch; then
      merged=true
      break
    fi
    echo "Merge attempt ${attempt} chưa sẵn sàng, thử lại..."
  done

  if [ "$merged" != "true" ]; then
    echo "::error::Không thể merge PR ${pr_url} sau 4 lần thử."
    exit 1
  fi

  completed=$((completed + 1))
  echo "✅ Merged PR #${next} (${i}/${BATCH_SIZE})"

  if [ "$i" -lt "$BATCH_SIZE" ]; then
    sleep "$DELAY_SECONDS"
  fi
done

final_count=$(tr -d '[:space:]' < data/counter.txt || echo "0")
{
  echo "### 🦈 Pull Shark CI Summary"
  echo "- **PR vừa merge trong phiên này:** \`${completed}\`"
  echo "- **Tổng PR tích luỹ tại repo này:** \`${final_count} / ${MAX_REPO_PRS}\`"
} >> "${GITHUB_STEP_SUMMARY:-/dev/null}"
