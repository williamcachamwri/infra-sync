#!/usr/bin/env bash
set -euo pipefail

BATCH_SIZE="${BATCH_SIZE:-115}"
DELAY_SECONDS="${DELAY_SECONDS:-5}"
MAX_REPO_PRS="${MAX_REPO_PRS:-1010}"
COAUTHOR_TRAILER="${COAUTHOR_TRAILER:-}"

if ! [[ "$BATCH_SIZE" =~ ^[0-9]+$ ]] || [ "$BATCH_SIZE" -lt 1 ] || [ "$BATCH_SIZE" -gt 150 ]; then
  echo "::error::BATCH_SIZE must be between 1 and 150 (got: $BATCH_SIZE)."
  exit 1
fi

git config user.name "William Cachamwri"
git config user.email "2741582+williamcachamwri@users.noreply.github.com"

mkdir -p data
touch data/counter.txt data/changelog.log

completed=0

for ((i = 1; i <= BATCH_SIZE; i++)); do
  git checkout main
  for pull_try in 1 2 3; do
    if git pull --ff-only origin main; then
      break
    fi
    sleep $((pull_try * 5))
  done

  current=$(tr -d '[:space:]' < data/counter.txt)
  current="${current:-0}"

  if [ "$current" -ge "$MAX_REPO_PRS" ]; then
    echo "Target checkpoint ${current}/${MAX_REPO_PRS} reached (Gold unlocked). Exiting."
    gh workflow disable pull-shark.yml 2>/dev/null || true
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

  pushed=false
  for push_try in 1 2 3 4; do
    if git push -u origin "$branch"; then
      pushed=true
      break
    fi
    sleep $((push_try * 10))
  done

  if [ "$pushed" != "true" ]; then
    echo "::error::Failed to push branch ${branch}."
    exit 1
  fi

  sleep 2

  pr_url=""
  for create_attempt in 1 2 3 4; do
    if pr_url=$(gh pr create \
      --base main \
      --head "$branch" \
      --title "chore(sync): checkpoint #${next}" \
      --body "Automated checkpoint sync #${next} (${ts})."); then
      break
    fi
    sleep $((create_attempt * 20))
  done

  if [ -z "$pr_url" ]; then
    echo "::error::Failed to open PR for ${branch}."
    exit 1
  fi

  merged=false
  for attempt in 1 2 3 4 5 6; do
    sleep $((attempt * 3))
    if gh pr merge "$pr_url" --merge --delete-branch; then
      merged=true
      break
    fi
  done

  if [ "$merged" != "true" ]; then
    echo "::error::Failed to merge ${pr_url}."
    exit 1
  fi

  completed=$((completed + 1))
  echo "Merged checkpoint #${next} (${i}/${BATCH_SIZE})"

  if [ "$i" -lt "$BATCH_SIZE" ]; then
    sleep "$DELAY_SECONDS"
  fi
done

final_count=$(tr -d '[:space:]' < data/counter.txt || echo "0")
{
  echo "### Sync Summary"
  echo "- **Checkpoints merged:** \`${completed}\`"
  echo "- **Current sequence:** \`${final_count} / ${MAX_REPO_PRS}\`"
} >> "${GITHUB_STEP_SUMMARY:-/dev/null}"
