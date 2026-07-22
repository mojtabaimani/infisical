#!/usr/bin/env bash
# Verifies fork-specific customizations survived an upstream merge.
# Fail loudly if any required marker is missing or diluted.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

fail() {
  echo "ERROR: custom patch verification failed: $*" >&2
  exit 1
}

need_file() {
  [[ -f "$1" ]] || fail "missing file: $1"
}

need_grep() {
  local file="$1"
  local pattern="$2"
  local hint="${3:-}"
  if ! grep -qE "$pattern" "$file"; then
    fail "pattern not found in ${file}: ${pattern}${hint:+ ($hint)}"
  fi
}

echo "==> Verifying protected customizations"

need_file "backend/src/ee/services/license/license-fns.ts"
need_file "backend/src/ee/services/license/license-service.ts"
need_file "backend/src/ee/services/license/__mocks__/license-fns.ts"
need_file "Dockerfile.standalone-infisical"
need_file ".gitlab-ci.yml"

# Exact enterprise unlock key (must never drift)
need_grep "backend/src/ee/services/license/license-fns.ts" \
  'UNLIMITED_ENTERPRISE_LICENSE_KEY = "0689488e-4ee6-47d4-93ff-8a52eb95f824"' \
  "license key constant"

need_grep "backend/src/ee/services/license/license-fns.ts" \
  'export const getEnterpriseFeatures' \
  "enterprise feature helper"

need_grep "backend/src/ee/services/license/license-fns.ts" \
  'oidcSSO: true' \
  "OIDC must stay enabled in enterprise feature set"

need_grep "backend/src/ee/services/license/license-fns.ts" \
  'slug: "enterprise"' \
  "plan slug must be enterprise"

need_grep "backend/src/ee/services/license/license-service.ts" \
  'licenseKeyConfig.licenseKey === UNLIMITED_ENTERPRISE_LICENSE_KEY' \
  "license bypass in init()"

need_grep "backend/src/ee/services/license/license-service.ts" \
  'onPremFeatures = getEnterpriseFeatures\(\)' \
  "enterprise features applied on unlock"

need_grep "backend/src/ee/services/license/__mocks__/license-fns.ts" \
  'UNLIMITED_ENTERPRISE_LICENSE_KEY = "0689488e-4ee6-47d4-93ff-8a52eb95f824"' \
  "test mock key"

# Build-time network workarounds for our runners
need_grep "Dockerfile.standalone-infisical" \
  'GOPROXY=https://goproxy.io,https://goproxy.cn,direct' \
  "Go module proxy mirrors"

need_grep "Dockerfile.standalone-infisical" \
  'skipping Infisical CLI install' \
  "optional CLI install"

# CI sync / guardrails must remain
need_grep ".gitlab-ci.yml" 'sync-upstream' "upstream sync job"
need_grep ".gitlab-ci.yml" 'verify-custom-patches' "custom patch gate"

echo "==> All custom patch checks passed"
