# High Priority Issues

Review against **grugbrain.dev philosophy** and **OWASP ASVS v5.0.0**.

**Context:** AWS account separation by app/environment (primary privilege boundary), EKS hosts single app/environment, Drupal with S3 files + Aurora Serverless MySQL.

---

## HIGH Priority

### 1. Unpinned Dependency Version

`composer:latest` in railpack.json creates supply chain risk.

**Location:** `railpack.json:18`

**Fix:** Pin to specific version: `"image": "composer:2.8.4"`

**Standard:** ASVS V1.1.1 (Encoding), V10.1.1 (Third-party components)

---

### 2. Missing CI/CD Pipeline

No GitHub Actions workflows. No automated security scanning.

**Location:** Missing `.github/workflows/`

**Fix:** Add workflow with trivy, gitleaks, SBOM generation, cosign signing

**Standard:** ASVS V14.2.1 (Build pipeline security)

---

### 3. Permissive TRUSTED_HOST Pattern

Test config accepts any host with `.*` regex - could propagate to production.

**Location:** `test/docker-compose.yml:11`

**Fix:** `TRUSTED_HOST: ^localhost$|^127\.0\.0\.1$`

**Standard:** ASVS V3.4.2 (CORS), V4.1.3 (Header validation)

---

### 4. Missing Rate Limiting for Drupal Auth

No rate limiting on login endpoints - brute-force vulnerability.

**Location:** `Caddyfile`

**Fix:**
```caddyfile
rate_limit {
    zone drupal_login {
        key {remote_host}
        events 5
        window 1m
    }
}
```

**Standard:** ASVS V2.4.1 (Anti-automation), V6.1.1 (Auth documentation), V6.3.1 (Brute force protection)

---

### 5. Missing Production Logging

No structured logging for EKS/CloudWatch integration.

**Location:** `Caddyfile`

**Fix:**
```caddyfile
log {
    output stdout
    format json
    level INFO
}
```

**Grugbrain:** "grug huge fan of logging and encourage lots of it, especially in cloud deployed"

**Standard:** ASVS V11.2.1 (Security logging)

---

## MEDIUM Priority

| # | Issue | Location | Fix | Standard |
|---|-------|----------|-----|----------|
| 6 | Missing health check for EKS | test/docker-compose.yml | Add healthcheck with `start_period: 60s` for Aurora cold starts | ASVS V14.1.3 (Availability) |
| 7 | Hardcoded PHP config | Caddyfile:11-28 | Use env vars: `{$PHP_MEMORY_LIMIT:256M}` | ASVS V14.1.1 (Configuration) |
| 8 | Aurora connection resilience | - | Add retry logic, consider ProxySQL for cold starts | ASVS V14.1.3 (Availability) |
| 9 | S3 access logging (AWS-level) | AWS config | Enable S3 access logging + CloudTrail data events | ASVS V11.2.2 (Data access logging) |

---

## LOW Priority

| # | Issue | Location | Fix |
|---|-------|----------|-----|
| 10 | Hardcoded test DB credentials | test/docker-compose.yml:9-10 | Document as test-only (production uses Secrets Manager) |
| 11 | Destructive Docker config deletion | justfile:135,181 | Use `docker logout` instead of `rm ~/.docker/config.json` |
| 12 | `mise.toml` uses `latest` | mise.toml | Pin versions for dev reproducibility |
| 13 | Exposed MySQL port in tests | test/docker-compose.yml:33 | Remove unless debugging |

---

## Action Checklist

- [ ] Pin `composer:2.8.4` in railpack.json
- [ ] Add `.github/workflows/` with trivy + gitleaks
- [ ] Fix TRUSTED_HOST in test config
- [ ] Add rate limiting to Caddyfile
- [ ] Add structured logging to Caddyfile
- [ ] Add health check with Aurora-aware timeouts
- [ ] Externalize PHP config via env vars
