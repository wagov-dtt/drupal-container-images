# Drupal container images - Build & Development.

set dotenv-load := true
set shell := ["bash", "-lc"]
set ignore-comments := true

organisation := "wagov-dtt"

app_dir := "app"
app_name_default := "jobswa-clone"

code_dir := "code"
config_dir := "config"

tag_default := ''

ghcr := "ghcr.io"
namespace:= "wagov-dtt"

# Show all available commands.
default:
    @just --list

# Publish to registry (build + push + sign).
publish app_name=app_name_default tag=tag_default: (build app_name tag)
    @echo "🚀 Publishing release image..."
    docker push {{ghcr}}/{{namespace}}/{{app_name}}:{{tag}}
    @echo "Signing with cosign..."
    cosign sign --yes {{ghcr}}/{{namespace}}/{{app_name}}:{{tag}}

# Authenticate docker with GHRC.
auth:
    @echo "🔒 Authenticating with GHCR..."
    # Before removing docker config file there was an error:
    # Error saving credentials: error storing credentials.
    # @see https://stackoverflow.com/questions/42787779/docker-login-error-storing-credentials-write-permissions-error
    -@rm ~/.docker/config.json
    echo $GITHUB_TOKEN | docker login {{ghcr}} --username $GITHUB_USER --password-stdin

# Authenticate docker with GHRC using $GITHUB_TOKEN from 1Password.
# The command should be run from outside of devcontainer on HOST.
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
build app_name=app_name_default tag=tag_default: (prepare app_name tag)
    @echo "🔨 Building image..."
    # Use Railpack BuildKit Frontend.
    # Use the specified Railpack build plan.
    # --output type=docker
    # Automatically loads the single-platform build result to docker images.
    # --output name=app
    # The name of the image.
    docker buildx build \
        --build-arg BUILDKIT_SYNTAX="ghcr.io/railwayapp/railpack-frontend" \
        --file {{app_dir}}/{{app_name}}/{{config_dir}}/railpack-plan.json \
        --tag {{ghcr}}/{{namespace}}/{{app_name}}:{{tag}} \
        --output type=docker,name={{app_name}} \
        {{app_dir}}/{{app_name}}/{{code_dir}}

# Prepare railpack build plan.
prepare app_name=app_name_default tag=tag_default: setup (copy app_name tag)
    railpack prepare "{{app_dir}}/{{app_name}}/{{code_dir}}" \
        --plan-out {{app_dir}}/{{app_name}}/{{config_dir}}/railpack-plan.json \
        --info-out {{app_dir}}/{{app_name}}/{{config_dir}}/railpack-info.json

# Copy app codebase if not coppied already.
copy app_name=app_name_default tag=tag_default:
    @echo "⬇️ Pulling down git repository..."
    @git pull
    @echo "❌ Removing app data, but only if present and the tag has changed..."
    @-tag_previous=$(head -n 1 "{{app_dir}}/{{app_name}}/{{config_dir}}/tag.txt") && \
        echo "Previous tag: '$tag_previous', new tag: '{{tag}}'." && \
        [ $tag_previous != "{{tag}}" ] && \
        rm --recursive --force -- {{app_dir}}/{{app_name}}
    @echo "📁 Preparing directories..."
    @-mkdir {{app_dir}}/{{app_name}}
    @-mkdir {{app_dir}}/{{app_name}}/{{config_dir}}
    @echo "📝 Writing down tag to file..."
    echo "{{tag}}" > {{app_dir}}/{{app_name}}/{{config_dir}}/tag.txt
    @echo "📋 Copying app code..."
    @[ -d "{{app_dir}}/{{app_name}}/{{code_dir}}" ] || \
        git clone \
            --no-depth \
            --branch {{tag}} \
            git@github.com:{{organisation}}/{{app_name}}.git \
            "{{app_dir}}/{{app_name}}/{{code_dir}}"
    @-rm --recursive --force "{{app_dir}}/{{app_name}}/{{code_dir}}"/.git
    @echo "📋 Copying Caddyfile to app code..."
    cp Caddyfile {{app_dir}}/{{app_name}}/{{code_dir}}
    @echo "📋 Copying railpack.json to app code..."
    cp railpack.json {{app_dir}}/{{app_name}}/{{code_dir}}

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
    @-find "{{app_dir}}"/*/ -maxdepth 0 -empty -type d && \
        for entry in "{{app_dir}}"/*/; do docker container remove --force `basename "$entry"`; done
    # Remove images.
    # Check first if there are any app subdirectories.
    @-find "{{app_dir}}"/*/ -maxdepth 0 -empty -type d && \
        for entry in "{{app_dir}}"/*/; do docker image rm --force `basename "$entry"`; done
    # Remove unused Docker data.
    docker system prune -f
    # Remove all app artifacts (sub-direcitories) in app directory.
    rm --recursive --force -- {{app_dir}}/*/

# Run container of the built Drupal PROD image.
run app_name=app_name_default tag="tag_default":
    @echo "🐋 Running image container in Docker..."
    docker run \
        --detach \
        --publish 8080:80 \
        --name {{app_name}} \
        docker/{{app_name}}:{{tag}}

# Validate Caddyfile.
validate:
    @echo "🔍 Validate Caddyfile..."
    @echo "Run \`caddy fmt --help\` to understand the validation output and options."
    caddy fmt --diff Caddyfile

# Run in devcontainer with 1Password secrets.
devcontainer:
    op run --env-file=".env.local" -- devcontainer up
