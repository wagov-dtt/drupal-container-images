# Audit — Drupal Container Images

**Date:** 2026-03-17  
**Commit:** `62ebc58` — *Documented new SITE_EMAIL environment variable.*  
**Audited against:** [OWASP ASVS v5.0.0](https://github.com/OWASP/ASVS/tree/master/5.0/en) · [grugbrain.dev](https://grugbrain.dev)

### Codebase Summary

| Language | Files | Code | Blanks | Comments |
|----------|-------|------|--------|----------|
| Markdown | 3 | 214 | 95 | 0 |
| Dockerfile | 1 | 94 | 30 | 42 |
| HCL | 1 | 95 | 20 | 4 |
| YAML | 3 | 59 | 4 | 14 |
| INI | 1 | 18 | 11 | 26 |
| JSON | 1 | 29 | 0 | 0 |
| TOML | 4 | 11 | 0 | 0 |
| **Total** | **15** | **689** | **192** | **86** |

**Context:** AWS account separation by app/environment (primary privilege boundary), EKS hosts single app/environment, Drupal with S3 files + Aurora Serverless MySQL. FrankenPHP + Caddy web server, Composer for PHP dependencies, multi-stage Docker build, `just` command runner, `mise` for dev tools.

---

## Findings

### 1. Missing Security Response Headers

**Category:** Security  
**Priority:** HIGH  
**Status:** Open  
**Location:** `conf/Caddyfile:40-108`  
**Standard:** ASVS V13.6.1 (Response headers), grugbrain ("security = most important thing")

Caddy sends a `Server: Caddy` header by default and FrankenPHP exposes `X-Powered-By: PHP`. Neither `expose_php = Off` nor response header stripping is configured. This reveals technology stack details to attackers.

**Recommendation:** Add security headers to the Caddyfile site block:

```caddyfile
header {
	-Server
	-X-Powered-By
	X-Content-Type-Options "nosniff"
	X-Frame-Options "SAMEORIGIN"
	Referrer-Policy "strict-origin-when-cross-origin"
	Permissions-Policy "camera=(), microphone=(), geolocation=()"
}
```

Also add `expose_php = Off` to `conf/php.ini`.

---

### 2. Missing CI/CD Pipeline

**Category:** Security  
**Priority:** HIGH  
**Status:** Open  
**Location:** Missing `.github/workflows/`  
**Standard:** ASVS V13.3.1 (Build pipeline), V10 (Secure Coding)

No GitHub Actions workflows exist. Trivy, gitleaks, and pre-commit are available locally but nothing enforces their use before merge. Security scanning, linting, and image builds are entirely trust-based.

**Recommendation:** Add a minimal GitHub Actions workflow that runs `just scan` and `just validate` on pull requests, and `just build --push` on merge to main. Keep it simple — one workflow file, not a reusable-workflow empire.

---

### 3. Destructive Docker Config Deletion

**Category:** Security / Complexity  
**Priority:** HIGH  
**Status:** Open  
**Location:** `justfile:120`, `justfile:166`  
**Standard:** grugbrain ("surprises = bad"), ASVS V13.4.1 (Secrets management)

`rm ~/.docker/config.json` deletes the entire Docker credential store, destroying credentials for *all* registries (not just the target). This is a data-loss footgun.

**Recommendation:** Use `docker logout <registry>` for targeted credential removal, or use Docker credential helpers that isolate per-registry auth.

---

### 4. Placeholder Secrets Baked Into Image Layers

**Category:** Security  
**Priority:** HIGH  
**Status:** Open  
**Location:** `Dockerfile:146-156`  
**Standard:** ASVS V13.4.2 (Secrets not in images), V13.5.1 (Secret storage)

ENV directives with placeholder values like `DB_PASSWORD=provide_db_password` and `SMTP_PASSWORD=provide_smtp_password` are baked into the image manifest. While they are placeholders, they establish a pattern where passwords are expected as plain ENV vars rather than mounted secrets. More critically, if anyone mistakenly sets real values here, they persist in image layers.

**Recommendation:** Remove password defaults entirely (leave them unset). Document that secrets must be injected at runtime via Kubernetes Secrets, AWS Secrets Manager, or similar. Consider:

```dockerfile
# No default — must be provided at runtime
ENV DB_PASSWORD= \
    SMTP_PASSWORD=
```

---

### 5. Unused Build Secret Declaration

**Category:** Complexity  
**Priority:** MEDIUM  
**Status:** Open  
**Location:** `docker-bake.hcl:86`  
**Standard:** grugbrain ("complexity = bad"), ASVS V13.4.1

`secret = ["id=GITHUB_TOKEN,env=GITHUB_TOKEN"]` is declared in the bake config but the Dockerfile never mounts or uses this secret (`--mount=type=secret` is absent). This is dead configuration that confuses readers into thinking the token is consumed during builds.

**Recommendation:** Either remove the secret declaration from `docker-bake.hcl`, or add `RUN --mount=type=secret,id=GITHUB_TOKEN ...` in the Dockerfile if private repo access is actually needed during `composer install`.

---

### 6. No HEALTHCHECK in Dockerfile

**Category:** Security / Performance  
**Priority:** MEDIUM  
**Status:** Open  
**Location:** `Dockerfile`  
**Standard:** ASVS V13.6.2 (Availability), Docker best practices

No `HEALTHCHECK` instruction exists. While Kubernetes has its own liveness/readiness probes, a Dockerfile HEALTHCHECK provides a safety net for `docker run` and `docker compose` usage (which this project supports via `test/docker-compose.yml`).

**Recommendation:** Add a minimal health check:

```dockerfile
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD curl -fsS http://localhost:8080/ -o /dev/null || exit 1
```

Note: `curl` is not currently installed in the image. Either install it, or use a PHP-based check: `php -r 'exit(file_get_contents("http://localhost:8080/") === false ? 1 : 0);'`

---

### 7. MySQL SSL Explicitly Disabled

**Category:** Security  
**Priority:** MEDIUM  
**Status:** Open  
**Location:** `conf/mysql_disable_ssl.cnf`, `Dockerfile:24`  
**Standard:** ASVS V13.7.1 (Encrypted connections between components)

`skip-ssl = true` disables TLS for MySQL client connections. The context note says Aurora Serverless is used — AWS Aurora supports (and defaults to) TLS. Disabling it means database credentials and query data traverse the network unencrypted.

**Recommendation:** If Aurora's internal VPC networking is deemed sufficient (defence-in-depth trade-off), document the rationale explicitly in the config file. Otherwise, remove this file and configure the MySQL client to verify the AWS RDS CA bundle. At minimum, rename the file or add a prominent comment explaining *why* SSL is disabled.

---

### 8. `dotenv-load` Risks Leaking Local Secrets Into Builds

**Category:** Security  
**Priority:** MEDIUM  
**Status:** Open  
**Location:** `justfile:3`  
**Standard:** ASVS V13.4.2 (Secrets exposure), grugbrain ("surprises = bad")

`set dotenv-load := true` loads `.env` into every `just` recipe's environment. Since the `.env` file can contain AWS credentials, SSO tokens, and other secrets, these are exposed to every subprocess — including Docker builds that may capture them via build args or ENV leakage.

**Recommendation:** Scope dotenv loading to only the recipes that need it, or ensure `.env` contains only non-sensitive configuration. Add a comment warning developers never to put secrets in `.env`, and reference 1Password/`op run` (already used in the `devcontainer` recipe) as the preferred secrets path.

---

### 9. Floating Base Image Tag

**Category:** Security  
**Priority:** MEDIUM  
**Status:** Open  
**Location:** `Dockerfile:8`  
**Standard:** ASVS V10 (Secure Coding — supply chain), ASVS V13.3.2 (Build reproducibility)

`FROM dunglas/frankenphp:1-php8.4-trixie` uses a floating major-version tag. A compromised or broken upstream push silently changes the base. The `composer` image *is* pinned (`composer:2.9.5` on line 89), showing the team understands this — the base image should follow the same discipline.

**Recommendation:** Pin to a specific digest or full version tag:

```dockerfile
FROM dunglas/frankenphp:1.6.1-php8.4-trixie@sha256:<digest>
```

Update via Dependabot or Renovate.

---

### 10. Dev Tools Unpinned in mise Configs

**Category:** Security  
**Priority:** LOW  
**Status:** Open  
**Location:** `mise.toml`, `mise.dev.toml`  
**Standard:** ASVS V10 (Third-party component management)

All mise-managed tools use `latest` (e.g., `caddy = "latest"`, `trivy = "latest"`, `gh = "latest"`). While these are dev-only tools, an unexpected breaking change or supply-chain compromise could disrupt or subvert the development environment.

**Recommendation:** Pin versions in `mise.toml` and `mise.dev.toml`. Keep a `just update-tools` recipe that bumps versions explicitly.

---

### 11. Docker Socket Bind Mount in Devcontainer

**Category:** Security  
**Priority:** LOW  
**Status:** Open  
**Location:** `.devcontainer/devcontainer.json:5`  
**Standard:** ASVS V13.5.2 (Container isolation)

Mounting `/var/run/docker.sock` gives the devcontainer full root-equivalent access to the host Docker daemon. This is standard practice for Docker-in-Docker dev workflows but should be documented as an accepted risk.

**Recommendation:** Add a comment in `devcontainer.json` acknowledging the risk. For hardened environments, consider using Docker-in-Docker (DinD) sidecar or rootless Docker instead.

---

### 12. README Documents Wrong SERVER_NAME Default

**Category:** Complexity  
**Priority:** LOW  
**Status:** Open  
**Location:** `README.md:57`  
**Standard:** grugbrain ("say thing once and only once")

README says `SERVER_NAME` defaults to `:80`, but the Dockerfile (`line 144`) sets it to `:8080` and the Caddyfile defaults to `localhost`. Three different "defaults" creates confusion.

**Recommendation:** Update README to match the Dockerfile default (`:8080`). Single source of truth.

---

### 13. `--no-depth` Git Clone Flag is Non-obvious

**Category:** Complexity  
**Priority:** LOW  
**Status:** Open  
**Location:** `justfile:86`, `justfile:96`  
**Standard:** grugbrain ("complexity = bad", "surprise = bad")

`git clone --no-depth` is a valid but obscure git negation flag (it means "full clone, don't limit depth"). Since it's the default behaviour of `git clone`, the flag is redundant and confusing — most developers have never seen it.

**Recommendation:** Remove `--no-depth` entirely. A bare `git clone --branch <tag>` already performs a full clone. If the intent is to document "we want a full clone", use a comment instead.

---

## Resolved Issues Log

Issues from the previous audit (pre-`62ebc58`) that have been addressed:

| # | Previous Finding | Resolution | Resolved In |
|---|-----------------|------------|-------------|
| 1 | `composer:latest` unpinned in `railpack.json` | Railpack removed; Dockerfile now uses `COPY --from=composer:2.9.5` (pinned) | Dockerfile rewrite |
| 2 | Missing non-root user (`USER` directive) | `USER www-data` added at `Dockerfile:163` | `a2d7a52` |
| 3 | Missing file permission hardening | `chmod 644/775/750` applied to config files and directories | `56be9b6` |
| 4 | SMTP env vars undocumented | SMTP variables added to Dockerfile and README | `f456751`, `62ebc58` |
| 5 | Running as root by default | Non-root `www-data` user with proper `chown` on `/config`, `/data`, `/app` | Dockerfile rewrite |
