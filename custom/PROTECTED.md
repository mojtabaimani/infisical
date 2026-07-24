# Protected fork customizations
#
# These must survive every upstream sync. The CI job `verify-custom-patches`
# fails the pipeline if any marker below is missing after merge.
#
# 1. Enterprise license unlock (online UUID bypass)
#    - backend/src/ee/services/license/license-fns.ts
#      UNLIMITED_ENTERPRISE_LICENSE_KEY = 0689488e-4ee6-47d4-93ff-8a52eb95f824
#      getEnterpriseFeatures() with oidcSSO/saml/rbac/... enabled
#    - backend/src/ee/services/license/license-service.ts
#      init() bypass when LICENSE_KEY matches the unlock key
#
# 2. Offline license (preferred for air-gapped / no portal checks)
#    - custom/license/LICENSE_KEY_OFFLINE.b64
#    - custom/license/offline_license_public_key.pem
#    - backend/src/lib/crypto/license_public_key.pem (must match)
#    Deploy with LICENSE_KEY_OFFLINE only — do NOT set LICENSE_KEY (online UUID).
#
# 3. OIDC SSO must not force re-login
#    - backend/src/ee/services/oidc/oidc-config-service.ts
#      must NOT set prompt: "login" (keep PKCE S256)
#
# 4. Runner network workarounds
#    - Dockerfile.standalone-infisical GOPROXY mirrors
#    - Optional Infisical CLI apt install
#
# 5. GitLab sync pipeline
#    - .gitlab-ci.yml sync-upstream + verify-custom-patches
#
# If a sync merge conflicts in these areas, CI fails on purpose.
# Resolve manually, keep the custom behavior, then re-run the pipeline.
