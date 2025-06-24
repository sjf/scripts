#!/usr/bin/env bash

unstaged_files=$(git diff --name-only)
new_files=$(git ls-files --others --exclude-standard)
unstashed_files=()

for file in $new_files; do
    file_in_stash=false
    
    # Check if this file is in any stash
    for stash in $(git stash list --format="%gd"); do
        if git stash show --name-only -u "$stash" 2>/dev/null | grep -Fxq "$file"; then
            date=$(git show --format="%cd" --no-patch stash@{0})
            file_in_stash=true
            echo \'$file\' was stashed on $date in $stash
            break
        fi
    done
    
    if [ "$file_in_stash" = false ]; then
        unstashed_files+=("$file")
    fi
done
if [ ${#unstashed_files[@]} -gt 0 ]; then
    warn "WARNING: These untracked files are not stashed:"
    warn $(printf '%s\n' "${unstashed_files[@]}")
    exit 1
fi
