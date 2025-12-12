# Drupal container images

**Drupal container images** to be used for **PROD** and **NPE** environments as well as **local dev** environment.

## Architecture

**Base**: Dev container: [devcontainer-base](https://github.com/wagov-dtt/devcontainer-base)

**Package Management**: Hybrid approach - official Debian packages from Dev container + [mise](https://mise.jdx.dev/) for specialized tools.

**Build System**: [Railpack](https://railpack.com/), Docker [BuildKit](https://github.com/moby/buildkit) with docker [buildx](https://github.com/docker/buildx).

**Automation**: [just](https://just.systems/) recipes + GitHub Actions.

### 🔨 Building container images

```bash
# Core workflow (works locally or in Codespaces)
just build          # Build Drupal container images for specified app (project).
just clean          # Clean build artifacts.
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

