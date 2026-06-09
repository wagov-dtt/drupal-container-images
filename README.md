# Drupal Container Images

Building process for **production-ready** container images for **Drupal** applications using [FrankenPHP](https://frankenphp.dev/) and [Caddy](https://caddyserver.com/).

For development/contributing to this repo, see [CONTRIBUTING.md](./CONTRIBUTING.md).

## Quick Start

```bash
just build [repository] [tag]

# Using named parameters.
just build --repository=[repository] --tag=[tag]

# Example.
just build wagov-dtt/myapp v1.0.0

# Example with named parameters
just build --repository="wagov-dtt/myapp" --tag="v1.0.0"
```

## Requirements

- [Docker](https://docs.docker.com/get-docker/) with BuildKit
- [just](https://just.systems/) command runner
- [mise](https://mise.jdx.dev/) (optional, for dev tools)

## Commands

| Command | Description |
|---------|-------------|
| `just build [repo] [tag]` | Build container image for an app |
| `just test [repo] [tag]` | Test image with docker-compose |
| `just test-simple-db [repo] [tag]` | Test with fresh Drupal install |
| `just test-import-db [repo] [tag] [db.sql]` | Test with database import |
| `just scan` | Security scan with Trivy + gitleaks |
| `just validate` | Run lint and format checks |
| `just clean` | Remove build artifacts and images |
| `just --list` | Show all available commands |

## Actions

### Push container image to ECR manually

This process requires couple of **environment variables** (as explained in the first step below).

1. Copy the `.env.example` file to `.env` file and fill in the required **environment variable values**.
	1. **Required** environment variables:
		1. `AWS_PROFILE`
		2. `AWS_REGION`
		3. `ECR_REPOSITORY`
	2. All the other environment variables are **optional** as they are only being used by `just aws-sso-login` recipe (which can be skipped if you are using different **AWS authentication process**):
		1. `SSO_SESSION`
		2. `SSO_START_URL`
		3. `SSO_REGION`
		4. `SSO_REGISTRATION_SCOPE`
		5. `SSO_ACCOUNT`
		6. `SSO_ROLE`
2. **Authenticate** with **AWS** using the appropriate `AWS_PROFILE` and `AWS_REGION`.
	1. You can use the `just aws-sso-login` recipe if you filled in all the environment variables it requires (marked as optional above, but required by this recipe)
3. **Push** the **container image** to **ECR** running the `just push-ecr` recipe.
	1. Recipe template: `just push-ecr --repository=[repository] --tag=[tag]`
	2. Example with values: `just push-ecr --repository="some/drupal-application" --tag="v1.0.0"`

### Scan container image for vulnerabilities

To scan the built container image with [Trivy](https://trivy.dev/) (security scanner) run either:

- `just scan-image --repository="[repository]" --tag="[tag]"`
- `trivy image [image-identifier]`

Examples:

- `just scan-image --repository="some/drupal-application" --tag="v1.0.0"
- `trivy image docker.io/some/drupal-application:v1.0.0`

The repository contains **Trivy config file**: `trivy.yaml` that is automatically picked up by the `trivy` command mentioned above (when run from root folder of this repository). The configuration includes instructions like `ignore-unfixed: true` (show only vulnerabilities with fixes available).

## What's Included

- **FrankenPHP** - Modern PHP application server with worker mode
- **Caddy** - Automatic HTTPS, sane defaults
- **PHP 8.4** - With OPcache, JIT, and common Drupal extensions
- **Composer** - Dependency management
- **MySQL client** - For `drush sql:*` commands
- **Git** - Often required by Composer
- **Caching extensions** - APCu, Redis, Memcached

## Configuration

### Environment Variables

| Variable                   | Default                         | Description                                                               |
| -------------------------- | ------------------------------- | ------------------------------------------------------------------------- |
| `SERVER_NAME`              | `:80`                           | Server hostname                                                           |
| `SERVER_ROOT`              | `/app/web`                      | Document root                                                             |
| `DB_HOST`                  | -                               | MySQL hostname                                                            |
| `DB_PORT`                  | `3306`                          | MySQL port                                                                |
| `DB_DATABASE`              | -                               | Database name                                                             |
| `DB_USERNAME`              | -                               | Database user                                                             |
| `DB_PASSWORD`              | -                               | Database password                                                         |
| `TRUSTED_HOST`             | -                               | Trusted host pattern                                                      |
| `DRUSH_OPTIONS_URI`        | -                               | Drupal site URI for Drush CLI commands (required for `uli`, `cron`, etc.) |
| `APP_ENV`                  | `production`                    | Application environment                                                   |
| `APP_DEBUG`                | `false`                         | Enable debug mode                                                         |
| `SMTP_USERNAME`            | -                               | SMTP user                                                                 |
| `SMTP_PASSWORD`            | -                               | SMTP password                                                             |
| `SMTP_HOST`                | -                               | SMTP hostname                                                             |
| `SMTP_PORT`                | -                               | SMTP port                                                                 |
| `SITE_EMAIL`               | `noreply-wa-jobs@www.wa.gov.au` | Drupal website email used as the from email address.                      |
| `TRUSTED_REVERSE_PROXY_IP` | -                               | Trusted reverse proxy IP(s), example: `a.b.c.d,e.f.g.h/24`                |

### Custom Config

Place custom files in `conf/`:
- `Caddyfile` - Web server configuration
- `php.ini` - PHP settings
- `mysql_disable_ssl.cnf` - MySQL SSL config

## Testing Locally

```bash
just build myorg/myapp main
just test myorg/myapp main
```

Access at http://localhost:3000

## Security

See [ISSUES.md](./ISSUES.md) for security checklist before production deployment.

## Publishing

```bash
just push-ghcr myorg/myapp v1.0.0
```

## License

Apache-2.0 - See [LICENSE](./LICENSE)
