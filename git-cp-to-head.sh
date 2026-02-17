#!/usr/bin/env bash
set -euo pipefail

REMOTE="origin"
MAIN="master"
UPSTREAM="$REMOTE/$MAIN"

usage() {
  cat <<EOF
Usage:
  $(basename "$0") N [-a]

Arguments:
  N         REQUIRED: number of most-recent commits to keep (positive integer)

Options:
  -a        Actually rewrite the current branch and force-push.
            If omitted, runs in DRY RUN mode (default).

Behavior:
  - DRY RUN (default): prints which commits would be kept; makes no changes.
  - APPLY: creates a backup branch, resets current branch to $UPSTREAM,
          cherry-picks the top N commits from the original branch (oldest->newest),
          then pushes with --force-with-lease back to the same branch.

Examples:
  $(basename "$0") 1
  $(basename "$0") 1 -a
  $(basename "$0") 3
EOF
}

if [[ $# -lt 1 || $# -gt 2 ]]; then
  usage
  exit 2
fi

N="$1"
APPLY=0
if [[ $# -eq 2 ]]; then
  if [[ "$2" == "-a" ]]; then
    APPLY=1
  else
    echo "ERROR: Unknown option: $2"
    usage
    exit 2
  fi
fi

if ! [[ "$N" =~ ^[0-9]+$ ]] || [[ "$N" -le 0 ]]; then
  echo "ERROR: N must be a positive integer"
  exit 2
fi

BRANCH="$(git rev-parse --abbrev-ref HEAD)"
if [[ "$BRANCH" == "HEAD" ]]; then
  echo "ERROR: Detached HEAD. Checkout a branch first."
  exit 1
fi

# Require clean working tree (both dry-run and apply; avoids surprises)
if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "ERROR: Working tree not clean. Commit or stash your changes first."
  exit 1
fi

git fetch "$REMOTE" "$MAIN" >/dev/null

AHEAD_COUNT="$(git rev-list --count "$UPSTREAM..HEAD")"
if [[ "$AHEAD_COUNT" -eq 0 ]]; then
  echo "[info] Branch is not ahead of $UPSTREAM. Nothing to do."
  exit 0
fi
if [[ "$N" -gt "$AHEAD_COUNT" ]]; then
  echo "ERROR: N=$N but branch is only $AHEAD_COUNT commit(s) ahead of $UPSTREAM."
  echo "Pick N <= $AHEAD_COUNT."
  exit 2
fi

# Capture the top N commits from the *current branch* (oldest -> newest).
mapfile -t COMMITS < <(git rev-list --reverse --max-count="$N" HEAD)

MODE="DRY RUN"
if [[ "$APPLY" -eq 1 ]]; then MODE="APPLY"; fi

echo "[info] Branch: $BRANCH"
# echo "[info] Base:   $UPSTREAM"
# echo "[info] Mode:   $MODE"
echo "[plan] Would keep top $N commit(s) (oldest -> newest):"
for sha in "${COMMITS[@]}"; do
  git show -s --oneline "$sha" | sed 's/^/  /'
done

if [[ "$APPLY" -eq 0 ]]; then
  echo "[dry-run] No changes made. Re-run with '-a' to execute."
  exit 0
fi

TS="$(date +%Y%m%d-%H%M%S)"
BACKUP="backup/${BRANCH}-${TS}"
git branch "$BACKUP" "$BRANCH"
echo "[info] Created backup branch: $BACKUP"

git reset --hard "$UPSTREAM" >/dev/null

for sha in "${COMMITS[@]}"; do
  echo "[info] cherry-pick $sha"
  git cherry-pick "$sha"
done

echo "[info] Pushing with --force-with-lease..."
git push --force-with-lease "$REMOTE" "$BRANCH"

echo "[ok] Restacked $BRANCH onto $UPSTREAM keeping top $N commit(s)."
