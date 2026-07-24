const crypto = require("crypto");
const fs = require("fs");
const path = require("path");

const dir = path.join("custom", "license");
fs.mkdirSync(dir, { recursive: true });

const { privateKey, publicKey } = crypto.generateKeyPairSync("rsa", {
  modulusLength: 2048,
  publicKeyEncoding: { type: "pkcs1", format: "pem" },
  privateKeyEncoding: { type: "pkcs1", format: "pem" }
});

fs.writeFileSync(path.join(dir, "offline_license_private_key.pem"), privateKey);
fs.writeFileSync(path.join(dir, "offline_license_public_key.pem"), publicKey);
fs.copyFileSync(
  path.join(dir, "offline_license_public_key.pem"),
  path.join("backend", "src", "lib", "crypto", "license_public_key.pem")
);

const features = {
  _id: null,
  slug: "enterprise",
  tier: -1,
  workspaceLimit: null,
  workspacesUsed: 0,
  secretSyncLimit: null,
  maxInternalCas: null,
  maxPamAccounts: null,
  memberLimit: null,
  membersUsed: 0,
  environmentLimit: null,
  environmentsUsed: 0,
  identityLimit: null,
  identitiesUsed: 0,
  dynamicSecret: true,
  secretVersioning: true,
  pitRecovery: true,
  ipAllowlisting: true,
  rbac: true,
  githubOrgSync: true,
  customRateLimits: true,
  subOrganization: true,
  customAlerts: true,
  secretAccessInsights: true,
  auditLogs: true,
  auditLogsRetentionDays: 3650,
  auditLogStreams: true,
  auditLogStreamLimit: 100,
  samlSSO: true,
  enforceGoogleSSO: true,
  hsm: true,
  oidcSSO: true,
  scim: true,
  ldap: true,
  groups: true,
  status: null,
  trial_end: null,
  has_used_trial: true,
  secretApproval: true,
  secretRotation: true,
  caCrl: true,
  instanceUserManagement: true,
  externalKms: true,
  rateLimits: { readLimit: 10000, writeLimit: 10000, secretsLimit: 10000 },
  pkiEst: true,
  pkiAcme: true,
  pkiScep: true,
  pkiPqc: true,
  pkiCodeSigning: true,
  kmsPqc: true,
  enforceMfa: true,
  projectTemplates: true,
  kmip: true,
  gateway: true,
  gatewayPool: true,
  pamSlackNotifications: true,
  sshHostGroups: true,
  secretScanning: true,
  enterpriseSecretSyncs: true,
  enterpriseCertificateSyncs: true,
  enterpriseAppConnections: true,
  fips: true,
  eventSubscriptions: true,
  machineIdentityAuthTemplates: true,
  pkiLegacyTemplates: true,
  secretShareExternalBranding: true,
  honeyTokens: true,
  honeyTokenLimit: null,
  secretsBrokering: true,
  pam: true,
  certManager: true,
  secretsTemporaryAccess: true,
  enterprisePamAccount: true
};

const license = {
  issuedTo: "Paziresh24 Self-Hosted",
  licenseId: "0689488e-4ee6-47d4-93ff-8a52eb95f824",
  customerId: null,
  issuedAt: new Date().toISOString(),
  expiresAt: null,
  terminatesAt: null,
  features
};

const licenseJson = JSON.stringify(license);
const sign = crypto.createSign("SHA256");
sign.update(licenseJson);
sign.end();
const signature = sign.sign(privateKey).toString("base64");

const contents = { license, signature };
const blob = Buffer.from(JSON.stringify(contents), "utf8").toString("base64");
fs.writeFileSync(path.join(dir, "LICENSE_KEY_OFFLINE.b64"), blob);
fs.writeFileSync(
  path.join(dir, "README.md"),
  `# Offline license (fork)

Do **not** set \`LICENSE_KEY\` (online UUID) — that contacts portal.infisical.com and fails.

Set instead:

\`\`\`
LICENSE_KEY_OFFLINE=<paste contents of LICENSE_KEY_OFFLINE.b64>
\`\`\`

Or remove LICENSE_KEY entirely and keep only LICENSE_KEY_OFFLINE.

This blob is signed with \`offline_license_private_key.pem\`.
The matching public key is installed at \`backend/src/lib/crypto/license_public_key.pem\`
so verification never needs Infisical's license server.
`
);

// self-check verify
const pub = crypto.createPublicKey({ key: publicKey, format: "pem", type: "pkcs1" });
const ok = crypto.verify(
  "SHA256",
  Buffer.from(licenseJson),
  pub,
  Buffer.from(signature, "base64")
);
console.log(JSON.stringify({ blobLength: blob.length, verifyOk: ok, licenseId: license.licenseId }));
