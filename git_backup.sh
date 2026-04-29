#!/usr/bin/env bash

set -euo pipefail

if ! git rev-parse --git-dir >/dev/null 2>&1; then
  echo "Not inside a Git repository." >&2
  exit 1
fi

current_branch="$(git rev-parse --abbrev-ref HEAD)"

if [[ "$current_branch" == "HEAD" ]]; then
  echo "Detached HEAD detected. Check out a branch or pass an explicit backup name." >&2
  exit 1
fi

timestamp="$(date +%Y%m%d-%H%M%S)"
default_backup_branch="backup/${current_branch}-${timestamp}"
backup_branch="${1:-$default_backup_branch}"

git branch "$backup_branch"

printf 'Created backup branch: %s\n' "$backup_branch"
printf 'Commit: %s\n' "$(git rev-parse --short "$backup_branch")"
