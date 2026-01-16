# Drupal container images - Build & Development.

set dotenv-load := true
set shell := ["bash", "-lc"]
set ignore-comments := true

organisation := "wagov-dtt"
app_dir := "app"
repository_default := "wagov-dtt/jobswa-clone"
code_dir := "code"
config_dir := "config"
tag_default := ''
build_target_default := 'test'
ghcr := "ghcr.io"
namespace := "wagov-dtt"

# Show all available commands.
default:
    @just --list

# Publish to registry (build + push + sign).
publish repository=repository_default tag=tag_default: (build repository tag)
    @echo "🚀 Publishing release image..."
    docker push {{ ghcr }}/{{ repository }}:{{ tag }}
    @echo "Signing with cosign..."
    cosign sign --yes {{ ghcr }}/{{ repository }}:{{ tag }}

# Authenticate docker with GHRC.
auth:
    @echo "🔒 Authenticating with GHCR..."
    # Before removing docker config file there was an error:
    # Error saving credentials: error storing credentials.
    # @see https://stackoverflow.com/questions/42787779/docker-login-error-storing-credentials-write-permissions-error
    -@rm ~/.docker/config.json
    echo $GITHUB_TOKEN | docker login {{ ghcr }} --username $GITHUB_USER --password-stdin

# Authenticate docker with GHRC using $GITHUB_TOKEN from 1Password. The command should be run from outside of devcontainer on HOST.
auth-1password:
    @echo "🔒 Authenticating with GHCR using 1password..."
    op run --env-file=".env.local" --no-masking -- just auth-devcontainer

# Inject docker authentication into Dev Container.
auth-devcontainer:
    devcontainer exec \
      --workspace-folder . \
      --remote-env GITHUB_TOKEN=$GITHUB_TOKEN \
      --remote-env GITHUB_USER=$(gh api user --jq .login) \
      -- just auth

# Build Drupal PROD image locally.
build repository=repository_default tag=tag_default target=build_target_default: (prepare repository tag)
    @echo "🔨 Building image with `docker buildx bake`..."
    docker buildx bake {{ target }} \
        --progress=plain \
        --set="{{ target }}.tags={{ tag }}"

# Prepare railpack build plan.
prepare repository=repository_default tag=tag_default: setup (copy repository tag)
    railpack prepare "{{ app_dir }}/{{ repository }}/{{ code_dir }}" \
        --plan-out {{ app_dir }}/{{ repository }}/{{ config_dir }}/railpack-plan.json \
        --info-out {{ app_dir }}/{{ repository }}/{{ config_dir }}/railpack-info.json

# Copy app codebase if not coppied already.
copy repository=repository_default tag=tag_default:
    @echo "⬇️ Pulling down git repository..."
    @git pull
    @echo "❌ Removing app data, but only if present and the tag has changed..."
    @-tag_previous=$(head -n 1 "{{ app_dir }}/{{ repository }}/{{ config_dir }}/tag.txt") && \
        echo "Previous tag: '$tag_previous', new tag: '{{ tag }}'." && \
        [ $tag_previous != "{{ tag }}" ] && \
        rm --recursive --force -- {{ app_dir }}/{{ repository }}
    @echo "📁 Preparing directories..."
    @-mkdir {{ app_dir }}/{{ repository }}
    @-mkdir {{ app_dir }}/{{ repository }}/{{ config_dir }}
    @echo "📝 Writing down tag to file..."
    echo "{{ tag }}" > {{ app_dir }}/{{ repository }}/{{ config_dir }}/tag.txt
    @echo "📋 Copying app code..."
    @[ -d "{{ app_dir }}/{{ repository }}/{{ code_dir }}" ] || \
        git clone \
            --no-depth \
            --branch {{ tag }} \
            git@github.com:{{ repository }}.git \
            "{{ app_dir }}/{{ repository }}/{{ code_dir }}"
    @-rm --recursive --force "{{ app_dir }}/{{ repository }}/{{ code_dir }}"/.git
    @echo "📋 Copying Caddyfile to app code..."
    cp Caddyfile {{ app_dir }}/{{ repository }}/{{ code_dir }}
    @echo "📋 Copying railpack.json to app code..."
    cp railpack.json {{ app_dir }}/{{ repository }}/{{ code_dir }}
    @echo "📋 Copying docker-bake.hcl to app code..."
    REPOSITORY={{ repository }} envsubst < docker-bake-template.hcl > {{ app_dir }}/{{ repository }}/{{ code_dir }}/docker-bake.hcl

# Setup tools.
setup:
    @echo "🧰 Setting up Tools..."
    # Installation alone does not activated the tools in this just recipe sessions.
    # To activate the newly installed Tools, `just setup` has to be run first as a workaround.
    mise install

# Clean up coppied codebases and built images.
clean:
    @echo "🧹 Cleaning up..."
    # Remove containers.
    # Check first if there are any app subdirectories.
    @-find "{{ app_dir }}"/*/ -maxdepth 0 -empty -type d && \
        for entry in "{{ app_dir }}"/*/; do docker container remove --force `basename "$entry"`; done
    # Remove images.
    # Check first if there are any app subdirectories.
    @-find "{{ app_dir }}"/*/ -maxdepth 0 -empty -type d && \
        for entry in "{{ app_dir }}"/*/; do docker image rm --force `basename "$entry"`; done
    # Remove unused Docker data.
    docker system prune -f
    # Remove all app artifacts (sub-direcitories) in app directory.
    rm --recursive --force -- {{ app_dir }}/*/

# Run container of the built Drupal PROD image.
run repository=repository_default tag="tag_default":
    @echo "🐋 Running image container in Docker..."
    docker run \
        --detach \
        --publish 8080:80 \
        --name {{ repository }} \
        {{ repository }}:{{ tag }}

# Validate Caddyfile.
validate:
    @echo "🔍 Validate justfile..."
    just --fmt --check --unstable
    @echo "🔍 Validate Caddyfile..."
    @echo "Run \`caddy fmt --help\` to understand the validation output and options."
    caddy fmt --diff Caddyfile

# Run in devcontainer with 1Password secrets.
devcontainer:
    op run --env-file=".env.local" -- devcontainer up
