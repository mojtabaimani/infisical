import { describe, expect, it } from "vitest";

import { getEnterpriseFeatures, UNLIMITED_ENTERPRISE_LICENSE_KEY } from "./license-fns";

describe("custom enterprise license unlock", () => {
  it("keeps the exact unlimited license key", () => {
    expect(UNLIMITED_ENTERPRISE_LICENSE_KEY).toBe("0689488e-4ee6-47d4-93ff-8a52eb95f824");
  });

  it("exposes a full enterprise feature set including OIDC", () => {
    const plan = getEnterpriseFeatures();

    expect(plan.slug).toBe("enterprise");
    expect(plan.oidcSSO).toBe(true);
    expect(plan.samlSSO).toBe(true);
    expect(plan.rbac).toBe(true);
    expect(plan.auditLogs).toBe(true);
    expect(plan.gateway).toBe(true);
    expect(plan.memberLimit).toBeNull();
    expect(plan.identityLimit).toBeNull();
    expect(plan.workspaceLimit).toBeNull();
  });
});
