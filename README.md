# Drupal container images

**Drupal container images** to be used for **PROD** and **NPE** environments as well as **local dev** environment.

## Architecture

**Base**: Dev container: [devcontainer-base](https://github.com/wagov-dtt/devcontainer-base)

**Package Management**: Hybrid approach - official Debian packages from Dev container + [mise](https://mise.jdx.dev/) for specialized tools.

**Build System**: [Railpack](https://railpack.com/), Docker [BuildKit](https://github.com/moby/buildkit) with docker [buildx](https://github.com/docker/buildx).

**Automation**: [just](https://just.systems/) recipes + GitHub Actions.

### 🔨 Building container images

#### Architecture of PROD container image

[Caddy](https://caddyserver.com/) **web server** running [FrankenPHP](https://frankenphp.dev/), **Modern PHP App Server**, written in **Go**.

#### Build Drupal container images for specified app (project)

```bash
just build
```

#### Prepare 

```bash
just prepare
```

The `app` directory is populated with **build artifacts**, so everything in the `app` directory with an exception to `.gitkeep` is **gitingored**.

Subdirectories like `app/jobswa` represents built artifacts for specific app (project).

- The code of the project is copied into `code` directory (shallow clone of the git repository).
- Configuration files are placed into `config` directory (e.g. `railpack-info.json`, `railpack-plan.json`).

`railpack.json` file is copied from root to `app/{project}/code` to be picked up by `railpack prepare` command.

- Using the **command option** with the path to the **config file**: `--config-file railpack.json` does **NOT** work properly.

`Caddyfile` file is copied from root to `app/{project}/code` to be picked up by [Caddy](https://caddyserver.com/) **web server**.

- `Caddyfile` is  [Caddy](https://caddyserver.com/) **configuration format** used by **Caddy web server**.
- The configuration defined in `Caddyfile` is used by [FrankenPHP](https://frankenphp.dev/) app server running on **Caddy web server**.
- The `Caddyfile` in use is based on the [Drupal on FrankenPHP](https://github.com/dunglas/frankenphp-drupal) example, link to the `Caddyfile` itself [Port the Apache config to Caddyfile](https://github.com/dunglas/frankenphp-drupal/blob/main/Caddyfile).
- Read more about: [Caddy](https://wagov-dtt.github.io/dalibor-matura/docs/server/Caddy/]), [Caddyfile](https://wagov-dtt.github.io/dalibor-matura/docs/server/Caddyfile/]) or [FrankenPHP](https://wagov-dtt.github.io/dalibor-matura/docs/language/php/FrankenPHP/).  

#### Clean build artifacts

```bash
just clean
```



### Use in CI/CD

Use [devcontainers/ci](https://github.com/devcontainers/ci) to run `mise` tasks and `just` recipes in your devcontainer for guaranteed environment consistency (example [`test-devcontainer.yml`](.github/workflows/test-devcontainer.yml)):

```yaml
- name: Configure AWS credentials
  uses: aws-actions/configure-aws-credentials@v4
  with:
    role-to-assume: arn:aws:iam::123456789012:role/GitHubActions
    aws-region: ap-southeast-2

- name: Run tests in devcontainer
  uses: devcontainers/ci@v0.3
  env:
    GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
  with:
    imageName: local/devcontainer
    push: never
    env: |
      GITHUB_TOKEN
    runCmd: |
      just test
      mise run lint
```

**Alternative**: Use [mise GitHub Action](https://github.com/jdx/mise-action) for simple tool management without containers

## 📦 Included Tools

**Cloud**: Docker  
**Development**: Git, [just](https://just.systems/), [mise](https://mise.jdx.dev/)  
**Security**: Trivy

## 🔧 Configuration

### Commands

```bash
just build
just clean
```

### Customization

...

## Features

**Security**: SBOM generation, signed packages, Trivy scanning, minimal attack surface

### Troubleshooting

- **Tool conflicts**: Run `mise install` to refresh tool installations
- **Build cache**: Use `just clean` to reset Docker build cache if needed

## Acknowledgments

- [Debian](https://www.debian.org/) - Stable base operating system
- [Devcontainers](https://containers.dev/) - Development container specification
- [Docker](https://www.docker.com/) - Container platform and BuildKit
- [just](https://just.systems/) - Command runner
- [mise](https://mise.jdx.dev/) - Polyglot tool version manager
- [Railpack](https://railpack.com/)

