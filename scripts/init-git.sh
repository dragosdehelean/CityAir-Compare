#!/usr/bin/env bash
set -euo pipefail

REMOTE_URL="${1:-https://github.com/dragosdehelean/CityAir-Compare.git}"
BRANCH="${2:-main}"

if ! command -v git >/dev/null 2>&1; then
  echo "Git is not installed. Please install Git and retry." >&2
  exit 1
fi

if [ ! -d .git ]; then
  git init >/dev/null
fi

# set branch name
if git branch -M "$BRANCH" 2>/dev/null; then :; else
  git checkout -b "$BRANCH" >/dev/null 2>&1 || true
fi

# ensure identity (local-only)
if ! git config user.name >/dev/null; then
  git config user.name "CityAir Local"
fi
if ! git config user.email >/dev/null; then
  git config user.email "local@example.com"
fi

git add -A

if git rev-parse --verify HEAD >/dev/null 2>&1; then
  if ! git diff --cached --quiet; then
    git commit -m "chore: add/updated docs" >/dev/null
  fi
else
  if ! git diff --cached --quiet; then
    git commit -m "chore: initial docs (SPECS, AGENTS, PLAN)" >/dev/null
  fi
fi

if git remote get-url origin >/dev/null 2>&1; then
  git remote set-url origin "$REMOTE_URL"
else
  git remote add origin "$REMOTE_URL"
fi

set +e
git push -u origin "$BRANCH"
rc=$?
set -e
if [ $rc -ne 0 ]; then
  echo "Push failed. Authenticate (e.g., 'gh auth login' or PAT) then rerun: git push -u origin $BRANCH" >&2
  exit 0
fi

echo "Repository initialized and linked to $REMOTE_URL on branch $BRANCH."

