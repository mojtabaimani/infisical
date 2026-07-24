# Offline license (fork)

Do **not** set `LICENSE_KEY` (online UUID) — that contacts portal.infisical.com and fails.

Set instead:

```
LICENSE_KEY_OFFLINE=<paste contents of LICENSE_KEY_OFFLINE.b64>
```

Or remove LICENSE_KEY entirely and keep only LICENSE_KEY_OFFLINE.

This blob is signed with `offline_license_private_key.pem`.
The matching public key is installed at `backend/src/lib/crypto/license_public_key.pem`
so verification never needs Infisical's license server.
