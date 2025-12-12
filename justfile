# Drupal container images - Build & Development.

organisation := "wagov-dtt"

app_dir := "app"
app_name_default := "jobswa-clone"

code_dir := "code"
config_dir := "config"

# Show all available commands.
default:
    @just --list

# Build Drupal PROD image locally.
build app_name=app_name_default: (prepare app_name)
    @echo "🔨 Building image..."
    # Use Railpack BuildKit Frontend.
    # Use the specified Railpack build plan.
    # --output type=docker
    # Automatically loads the single-platform build result to docker images.
    # --output name=app
    # The name of the image.
    docker buildx build \
        --build-arg BUILDKIT_SYNTAX="ghcr.io/railwayapp/railpack-frontend" \
        --file ./railpack-plan.json \
        --output type=docker,name={{app_name}} \
        .

# Prepare railpack build plan.
prepare app_name=app_name_default: setup (copy app_name)
    @-mkdir {{app_dir}}/{{app_name}}/{{config_dir}}
    railpack prepare "{{app_dir}}/{{app_name}}/{{code_dir}}" \
        --config-file railpack.json \
        --plan-out {{app_dir}}/{{app_name}}/{{config_dir}}/railpack-plan.json \
        --info-out {{app_dir}}/{{app_name}}/{{config_dir}}/railpack-info.json

# Copy app codebase if not coppied already.
copy app_name=app_name_default:
    @echo "📋 Copying app code..."
    @-mkdir {{app_dir}}/{{app_name}}
    [ -d "{{app_dir}}/{{app_name}}/{{code_dir}}" ] || \
        git clone git@github.com:{{organisation}}/{{app_name}}.git \
            --no-depth \
            "{{app_dir}}/{{app_name}}/{{code_dir}}"
    -rm --recursive --force "{{app_dir}}/{{app_name}}/{{code_dir}}"/.git
    # Copy Caddyfile to codebase be applied.
    cp Caddyfile {{app_dir}}/{{app_name}}/{{code_dir}}
    # Copy railpack config file to codebase be applied.
    cp railpack.json {{app_dir}}/{{app_name}}/{{code_dir}}

# Setup tools.
setup:
    mise install

# Clean up coppied codebases and built images.
clean:
    @echo "🧹 Cleaning up..."
    # Remove images.
    -for entry in "{{app_dir}}"/*/; do docker rmi `basename "$entry"`; done
    # Remove unused Docker data.
    docker system prune -f
    # Remove all app artifacts (sub-direcitories) in app directory.
    rm --recursive --force -- {{app_dir}}/*/
