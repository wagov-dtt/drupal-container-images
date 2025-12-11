# Drupal container images - Build & Development.

organisation := "wagov-dtt"

app_dir := "app"
app_name_default := "jobswa-clone"

code_dir := "code"

# Show all available commands.
default:
    @just --list

# Build Drupal PROD image locally.
build app_name=app_name_default: prepare
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
prepare: setup
    railpack prepare {{app_dir}} \
        --plan-out ./railpack-plan.json \
        --info-out ./railpack-info.json

# 
copy app_name=app_name_default:
    -mkdir {{app_dir}}/{{app_name}}
    -git clone git@github.com:{{organisation}}/{{app_name}}.git \
        --no-depth \
        "{{app_dir}}/{{app_name}}/{{code_dir}}"
    -rm --recursive --force "{{app_dir}}/{{app_name}}/{{code_dir}}"/.git

# Setup tools.
setup:
    which caddy || mise install

clean:
    # Remove all sub-direcitories in app directory.
    rm --recursive --force -- {{app_dir}}/*/
