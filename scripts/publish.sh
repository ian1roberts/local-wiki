#!/usr/bin/env bash
set -euo pipefail

# Always run from repo root
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

# git main guard
CURRENT_BRANCH=$(git branch --show-current)
if [[ "$CURRENT_BRANCH" != "main" ]]; then
  echo "Error: Not on main branch in repo root. Aborting."
  exit 1
fi

# Commit/push SOURCES (main) to GitHub
git add -A ./src ./scripts ./.vscode ./README.md ./.gitignore 2>/dev/null || true
# (Adjust what you want tracked on main; src/site should be ignored now)
MSG="${1:-Publish}"

if [[ -n $(git status --porcelain) ]]; then
  git reset -q .deploy 2>/dev/null || true
  git commit -m "$MSG"
fi

git push origin main

# Inject deploy metadata for footer (stored in src/)
COMMIT=$(git rev-parse --short HEAD)
DATE=$(date "+%Y-%m-%d %H:%M:%S")

cat > ./src/_deploy.yml <<EOF
commit: "$COMMIT"
date: "$DATE"
EOF

# Render locally (frozen)
quarto render ./src --no-execute
if [[ ! -f "./src/site/index.html" ]]; then
  echo "Error: Render failed: src/site/index.html not found."
  exit 1
fi

# Update deploy worktree from rendered output
# Ensure worktree exists
if [[ ! -f "./.deploy/.git" ]]; then
  git worktree add -B deploy .deploy
fi

# Safety check
DEPLOY_BRANCH=$(git -C ./.deploy branch --show-current)
if [[ "$DEPLOY_BRANCH" != "deploy" ]]; then
  echo "Error: .deploy is not on deploy branch (got '$DEPLOY_BRANCH'). Aborting."
  exit 1
fi

# Clean deploy folder but NEVER touch .git
find ./.deploy -mindepth 1 -maxdepth 1 ! -name '.git' -exec rm -rf {} +

# Copy rendered site into deploy worktree root
cp -r ./src/site/* ./.deploy/

# Commit + push deploy
git -C ./.deploy add -A
if [[ -n $(git -C ./.deploy status --porcelain) ]]; then
  git -C ./.deploy commit -m "Deploy $MSG"
fi
git -C ./.deploy push pi deploy
