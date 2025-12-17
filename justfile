# Drupal container images - Build & Development.

organisation := "wagov-dtt"

app_dir := "app"
app_name_default := "jobswa-clone"

code_dir := "code"
config_dir := "config"

tag_default := ''

# Show all available commands.
default:
    @just --list

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
        --output type=docker,name={{app_name}} \
        {{app_dir}}/{{app_name}}/{{code_dir}}

# Prepare railpack build plan.
prepare app_name=app_name_default tag=tag_default: setup (copy app_name tag)
    railpack prepare "{{app_dir}}/{{app_name}}/{{code_dir}}" \
        --plan-out {{app_dir}}/{{app_name}}/{{config_dir}}/railpack-plan.json \
        --info-out {{app_dir}}/{{app_name}}/{{config_dir}}/railpack-info.json

# Copy app codebase if not coppied already.
copy app_name=app_name_default tag=tag_default:
    @echo "❌ Removing app data, but only if present and the tag has changed..."
    @-tag_previous=$(head -n 1 "{{app_dir}}/{{app_name}}/{{config_dir}}/tag.txt") && \
        echo $tag_previous && \
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
