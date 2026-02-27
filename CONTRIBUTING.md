# Contributing

Development guide for working on this repository.

## Setup

1. Install [mise](https://mise.jdx.dev/)
2. Run setup:
   ```bash
   just setup
   ```

Tools are separated by environment:

| Environment | Tools |
|-------------|-------|
| **Base** (all) | caddy, cosign |
| **Dev** (`mise.dev.toml`) | gh, gitleaks, devcontainers/cli, pre-commit, trivy |
| **Prod** (`mise.prod.toml`) | (none) |

CI/CD uses `just install-prod` for production builds.

## Architecture

### Build System

- **Dockerfile** - Multi-stage build with FrankenPHP base
- **docker-bake.hcl** - Build configurations for different targets
- **justfile** - Command orchestration

### Dockerfile Stages

1. `base` - FrankenPHP + OS packages + config files
2. `php-extensions` - Install PHP extensions for Drupal
3. `build` - Composer install
4. `runtime` - Final production image

### Key Files

| File | Purpose |
|------|---------|
| `Dockerfile` | Multi-stage container build |
| `docker-bake.hcl` | Build targets and caching |
| `conf/Caddyfile` | Web server + PHP config |
| `conf/php.ini` | Additional PHP settings |
| `test/docker-compose.yml` | Local testing with MySQL |

## Commands

```bash
just --list          # Show all commands
just validate        # Run all validations
just scan            # Security scan with trivy + gitleaks
just test [repo] [tag]  # Test an image
```

## Development Workflow

1. Make changes
2. Run `just validate` to check justfile, Caddyfile, mise
3. Run `just scan` for security issues
4. Test with `just test [repo] [tag]`
5. Commit (pre-commit hooks run automatically)

## Code Style

- Pre-commit hooks enforce:
  - Secret detection (gitleaks)
  - Vulnerability scanning (trivy)

## CI/CD

- GitHub Actions for automated builds
- Build targets defined in `docker-bake.hcl`:
  - `test` - Local development
  - `build-test` - CI matrix builds
  - `release` - Production release

## Testing

The test setup uses docker-compose with MySQL:

```bash
just build myorg/myapp test
just test myorg/myapp test
```

Environment is configured via `test/docker-compose.yml`.
