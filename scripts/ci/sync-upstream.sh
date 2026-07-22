#!/usr/bin/env bash
# Merge Infisical upstream/main into the current branch.
# - Fails on any merge conflict (manual resolution required)
# - Re-verifies fork customizations after a clean merge
# - Does NOT push; the CI job pushes only after tests pass
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

UPSTREAM_URL="${UPSTREAM_URL:-https://github.com/Infisical/infisical.git}"
UPSTREAM_REF="${UPSTREAM_REF:-main}"

echo "==> Configuring git"
git config user.email "${GIT_AUTHOR_EMAIL:-ci-sync@gitlab.paziresh24.com}"
git config user.name "${GIT_AUTHOR_NAME:-Infisical Upstream Sync}"

# Detached CI checkouts need a real branch for merge commits / push.
DEFAULT_BRANCH="${CI_DEFAULT_BRANCH:-main}"
git checkout -B "$DEFAULT_BRANCH" "origin/${DEFAULT_BRANCH}" 2>/dev/null \
  || git checkout -B "$DEFAULT_BRANCH"

echo "==> Adding upstream remote (${UPSTREAM_URL})"
if git remote get-url upstream >/dev/null 2>&1; then
  git remote set-url upstream "$UPSTREAM_URL"
else
  git remote add upstream "$UPSTREAM_URL"
fi

echo "==> Fetching upstream/${UPSTREAM_REF}"
git fetch --no-tags upstream "$UPSTREAM_REF"

BEFORE_SHA="$(git rev-parse HEAD)"
UPSTREAM_SHA="$(git rev-parse "upstream/${UPSTREAM_REF}")"
echo "local=${BEFORE_SHA}"
echo "upstream=${UPSTREAM_SHA}"

if git merge-base --is-ancestor "$UPSTREAM_SHA" HEAD; then
  echo "==> Already up to date with upstream/${UPSTREAM_REF}; nothing to merge"
  echo "SYNCED=0" > .ci-sync-state
  echo "BEFORE_SHA=${BEFORE_SHA}" >> .ci-sync-state
  echo "AFTER_SHA=${BEFORE_SHA}" >> .ci-sync-state
  exit 0
fi

echo "==> Merging upstream/${UPSTREAM_REF}"
if ! git merge --no-ff --no-edit "upstream/${UPSTREAM_REF}"; then
  echo
  echo "============================================================"
  echo "ERROR: Merge conflict while syncing upstream/${UPSTREAM_REF}"
  echo "Custom fork changes must be preserved — refusing to auto-resolve."
  echo "Conflicted files:"
  git diff --name-only --diff-filter=U || true
  echo "============================================================"
  git merge --abort || true
  exit 1
fi

AFTER_SHA="$(git rev-parse HEAD)"
echo "==> Merge succeeded: ${BEFORE_SHA} -> ${AFTER_SHA}"

echo "==> Re-checking custom patches after merge"
bash "${ROOT}/scripts/ci/verify-custom-patches.sh"

echo "SYNCED=1" > .ci-sync-state
echo "BEFORE_SHA=${BEFORE_SHA}" >> .ci-sync-state
echo "AFTER_SHA=${AFTER_SHA}" >> .ci-sync-state
echo "==> Sync merge complete (not pushed yet; waiting for tests)"
