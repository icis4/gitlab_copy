#!/usr/bin/env sh
set -eu

# Creates/updates a local branch whose root contains ONLY the contents of html/.
# Optionally pushes that branch to a GitHub remote.
#
# Usage:
#   scripts/github-sync-html-root.sh
#   scripts/github-sync-html-root.sh --push --remote github --branch main

branch_local="github-html-root"
remote_name=""
remote_branch="main"
do_push=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    --push)
      do_push=1
      ;;
    --remote)
      shift
      remote_name="${1:-}"
      ;;
    --branch)
      shift
      remote_branch="${1:-main}"
      ;;
    -h|--help)
      echo "Usage: $0 [--push --remote <name> --branch <branch>]" >&2
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 2
      ;;
  esac
  shift
done

if [ ! -d "html" ]; then
  echo "ERROR: html/ folder not found in repo root." >&2
  exit 1
fi

if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "ERROR: working tree not clean. Commit or stash changes first." >&2
  exit 1
fi

# Ensure git-subtree is available
if ! git subtree --help >/dev/null 2>&1; then
  echo "ERROR: 'git subtree' not available. Install git-subtree (or use a git version that includes it)." >&2
  exit 1
fi

split_commit="$(git subtree split --prefix html HEAD)"
git branch -f "$branch_local" "$split_commit" >/dev/null

echo "Updated branch '$branch_local' at $split_commit"

if [ "$do_push" -eq 1 ]; then
  if [ -z "$remote_name" ]; then
    echo "ERROR: --remote is required with --push" >&2
    exit 2
  fi
  git push "$remote_name" "$branch_local:$remote_branch" --force
fi