#!/usr/bin/env bash
set -euo pipefail

REMOTE="origin"
MAIN="master"
UPSTREAM="$REMOTE/$MAIN"

. ~/scripts/log-utils.sh

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
          pauses for conflict resolution if needed,
          then pushes with --force-with-lease back to the same branch.

Examples:
  $(basename "$0") 1
  $(basename "$0") 1 -a
  $(basename "$0") 3
EOF
}

continue_cherry_pick_sequence() {
  local backup_branch="$1"
  local cherry_pick_head
  cherry_pick_head="$(git rev-parse --git-path CHERRY_PICK_HEAD)"

  while [[ -f "$cherry_pick_head" ]]; do
    echo
    err "Cherry-pick paused due to conflicts."
    printf "%sResolve the conflicts, stage the files, then press Enter to continue.%s\n" "$YELLOW" "$RESET"
    printf "%sType 'abort' to stop here and keep your original branch state in %s.%s\n" "$YELLOW" "$backup_branch" "$RESET"

    read -r -p "> " response
    if [[ "$response" == "abort" ]]; then
      git cherry-pick --abort
      err "Aborted cherry-pick sequence. Original branch state is preserved in $backup_branch"
      exit 1
    fi

    if git cherry-pick --continue; then
      :
    else
      err "git cherry-pick --continue failed. Resolve remaining conflicts and try again."
    fi
  done
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
    err "Unknown option: $2"
    usage
    exit 2
  fi
fi

if ! [[ "$N" =~ ^[0-9]+$ ]] || [[ "$N" -le 0 ]]; then
  err "N must be a positive integer"
  exit 2
fi

BRANCH="$(git rev-parse --abbrev-ref HEAD)"
if [[ "$BRANCH" == "HEAD" ]]; then
  err "Detached HEAD. Checkout a branch first."
  exit 1
fi

# Require clean working tree (both dry-run and apply; avoids surprises)
if ! git diff --quiet || ! git diff --cached --quiet; then
  err "Working tree not clean. Commit or stash your changes first."
  exit 1
fi

git fetch "$REMOTE" "$MAIN" >/dev/null

AHEAD_COUNT="$(git rev-list --count "$UPSTREAM..HEAD")"
if [[ "$AHEAD_COUNT" -eq 0 ]]; then
  info "Branch is not ahead of $UPSTREAM. Nothing to do."
  exit 0
fi
if [[ "$N" -gt "$AHEAD_COUNT" ]]; then
  err "N=$N but branch is only $AHEAD_COUNT commit(s) ahead of $UPSTREAM."
  printf "%sPick N <= %s.%s\n" "$YELLOW" "$AHEAD_COUNT" "$RESET"
  exit 2
fi

# Capture the top N commits from the *current branch* (oldest -> newest).
mapfile -t COMMITS < <(git rev-list --reverse --max-count="$N" HEAD)

MODE="DRY RUN"
if [[ "$APPLY" -eq 1 ]]; then MODE="APPLY"; fi

info "Branch: $BRANCH"
# echo "[info] Base:   $UPSTREAM"
# echo "[info] Mode:   $MODE"
plan "Would keep top $N commit(s) (oldest -> newest):"
for sha in "${COMMITS[@]}"; do
  git show -s --oneline "$sha" | sed 's/^/  /'
done

if [[ "$APPLY" -eq 0 ]]; then
  dry "No changes made. Re-run with '-a' to execute."
  exit 0
fi

TS="$(date +%Y%m%d-%H%M%S)"
BACKUP="backup/${BRANCH}-${TS}"
git branch "$BACKUP" "$BRANCH"
info "Created backup branch: $BACKUP"

git reset --hard "$UPSTREAM" >/dev/null

plan "Cherry-picking ${#COMMITS[@]} commit(s) as a single sequence..."
if ! git cherry-pick "${COMMITS[@]}"; then
  if [[ -f "$(git rev-parse --git-path CHERRY_PICK_HEAD)" ]]; then
    continue_cherry_pick_sequence "$BACKUP"
  else
    err "Cherry-pick failed before entering conflict resolution. Original branch state is preserved in $BACKUP"
    exit 1
  fi
fi

info "Pushing with --force-with-lease..."
git push --force-with-lease "$REMOTE" "$BRANCH"

ok "Restacked $BRANCH onto $UPSTREAM keeping top $N commit(s)."
