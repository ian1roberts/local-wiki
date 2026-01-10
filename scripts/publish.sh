#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "$ROOT/src"

rm -rf ../site
mkdir -p ../site

# Render without executing anything
quarto render . --no-execute

cd "$ROOT"

git add -A

# Prompt for a commit message
read -r -p "Commit message: " MSG
if [[ -z "${MSG}" ]]; then
  MSG="publish"
fi

git commit -m "$MSG" || echo "No changes to commit"
git push pi main
