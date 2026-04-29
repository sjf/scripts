#!/usr/bin/env bash

# tput-based colors with safe fallback (works when sourced)
if command -v tput >/dev/null 2>&1; then
  BOLD="$(tput bold)"
  RED="$(tput setaf 1)"
  GREEN="$(tput setaf 2)"
  YELLOW="$(tput setaf 3)"
  CYAN="$(tput setaf 6)"
  RESET="$(tput sgr0)"
else
  BOLD=""
  RED=""
  GREEN=""
  YELLOW=""
  CYAN=""
  RESET=""
fi

info() { printf "%s[INFO] %s%s\n" "$CYAN" "$*" "$RESET"; }
plan() { printf "%s[PLAN] %s%s\n" "$YELLOW" "$*" "$RESET"; }
ok()   { printf "%s[OK] %s%s\n" "$YELLOW" "$*" "$RESET"; }
err()  { printf "%sERROR: %s%s\n" "$RED$BOLD" "$*" "$RESET" >&2; }
dry()  { printf "%s[DRY-RUN] %s%s\n" "$YELLOW" "$*" "$RESET"; }
