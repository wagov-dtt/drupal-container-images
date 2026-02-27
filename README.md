# Drupal Container Images

Production-ready container images for Drupal applications using [FrankenPHP](https://frankenphp.dev/) and [Caddy](https://caddyserver.com/).

For development/contributing to this repo, see [CONTRIBUTING.md](./CONTRIBUTING.md).

## Quick Start

```bash
just build [repository] [tag]
```

**Example:**
```bash
just build wagov-dtt/myapp v1.0.0
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
| `just test-import-db [repo] [tag] [db.sql]` | Test with database import |
| `just clean` | Remove build artifacts and images |
| `just --list` | Show all available commands |

## What's Included

- **FrankenPHP** - Modern PHP application server with worker mode
- **Caddy** - Automatic HTTPS, sane defaults
- **PHP 8.4** - With OPcache, JIT, and common Drupal extensions
- **Composer** - Dependency management

## Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `SERVER_NAME` | `:80` | Server hostname |
| `SERVER_ROOT` | `/app/web` | Document root |
| `DB_HOST` | - | MySQL hostname |
| `DB_PORT` | `3306` | MySQL port |
| `DB_DATABASE` | - | Database name |
| `DB_USERNAME` | - | Database user |
| `DB_PASSWORD` | - | Database password |
| `TRUSTED_HOST` | - | Trusted host pattern |

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

MIT - See [LICENSE](./LICENSE)
