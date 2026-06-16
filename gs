#!/bin/bash
set -e #exit on failed command
set -u #fail on undefined variable

. ~/scripts/git-utils
. ~/scripts/log-utils.sh
#set -x
if [[ -z "$REPO" ]]; then
  err Not in a git repo
  exit 1
fi

files_to_ignore=(extensions/canvas/src/host/a2ui/.bundle.hash pnpm-lock.yaml .pnpm-store)

if (( ${#files_to_ignore[@]} > 0 )); then
    status_output=$(git status --porcelain -- "${files_to_ignore[@]}")

    while IFS= read -r line; do
      [[ -z "$line" ]] && continue

      status="${line:0:2}"
      file="${line:3}"

      # Remove new files in this allowlist (both untracked and staged-added).
      if [[ "$status" == "??" ]]; then
        rm -rf -- "$file"
        continue
      fi
      if [[ "${status:0:1}" == "A" ]]; then
        git rm -rf -- "$file"
        continue
      fi

      # Restore only unstaged working-tree changes.
      if [[ "${status:1:1}" != " " ]]; then
        git restore -- "$file"
      fi
    done <<< "$status_output"
fi

if [[ "$REPO" == "${MONOREPO:-}" ]]; then
  info Not showing uptracked files
  git status -uno
else
  git status
fi
