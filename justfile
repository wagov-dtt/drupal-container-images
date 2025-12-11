# Drupal container images - Build & Development.

app_dir := "app"
app_name := "drupal-app"

# Show all available commands.
default:
    @just --list

# Build Drupal PROD image locally.
build: prepare
    @echo "🔨 Building image..."
    docker buildx build \
        # Use Railpack BuildKit Frontend.
        --build-arg BUILDKIT_SYNTAX="ghcr.io/railwayapp/railpack-frontend" \
        # Railpack build plan to be used.
        --file ./railpack-plan.json \
        # --output type=docker
        # Automatically loads the single-platform build result to docker images.
        # --output name=app
        # The name of the image.
        --output type=docker,name={{app_name}} \
        ## App directory.
        .

# Prepare railpack build plan.
prepare: setup
    railpack prepare {{app_dir}} \
        --plan-out ./railpack-plan.json \
        --info-out ./railpack-info.json

copy:
    git clone ... --depth=0

# Setup tools.
setup:
    which caddy || mise install
