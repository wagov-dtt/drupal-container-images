# syntax=docker/dockerfile:1.7
# Drupal container image using FrankenPHP on Debian Trixie
# Replaces Railpack with standard Dockerfile for full control over base image

# ===========================================
# Base stage - FrankenPHP on Debian Trixie
# ===========================================
FROM dunglas/frankenphp:1-php8.4-trixie AS base

# Patch OS and install common packages
RUN rm -f /etc/apt/apt.conf.d/docker-clean && \
    apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        git \
        zip \
        unzip \
        ca-certificates \
        default-mysql-client \
    && apt-get upgrade -yq \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Copy custom configuration file into the MySQL configuration directory
COPY conf/mysql_disable_ssl.cnf /etc/mysql/conf.d/mysql_disable_ssl.cnf

# Ensure correct file permissions (e.g., 644) if necessary; world-writable files may be ignored
RUN chmod 644 /etc/mysql/conf.d/mysql_disable_ssl.cnf

# Copy default production php.ini file
RUN cp $PHP_INI_DIR/php.ini-production $PHP_INI_DIR/php.ini

# Ensure correct file permissions (e.g., 644) if necessary; world-writable files may be ignored
RUN chmod 644 $PHP_INI_DIR/php.ini

# Copy our custom php.ini overrides to conf.d folder
ADD conf/php.ini $PHP_INI_DIR/conf.d/php.ini

# Ensure correct file permissions (e.g., 644) if necessary; world-writable files may be ignored
RUN chmod 644 $PHP_INI_DIR/conf.d/php.ini

# ===========================================
# PHP extensions stage
# ===========================================
FROM base AS php-extensions

# Install PHP extensions commonly needed by Drupal
# Drupal core requirements: ctype, dom, fileinfo, filter, hash, mbstring, openssl, pcre, pdo, session, tokenizer, xml
# Additional common extensions for Drupal
RUN install-php-extensions \
    apcu \
    bcmath \
    ctype \
    curl \
    dom \
    exif \
    fileinfo \
    filter \
    gd \
    hash \
    intl \
    mbstring \
    memcached \
    mysqli \
    opcache \
    openssl \
    pcntl \
    pcre \
    pdo \
    pdo_mysql \
    pdo_pgsql \
    redis \
    session \
    simplexml \
    soap \
    tokenizer \
    xml \
    xmlreader \
    xmlwriter \
    zip

# ===========================================
# Build stage - Composer and dependencies
# ===========================================
FROM php-extensions AS build

WORKDIR /app

# Copy composer from official image
COPY --from=composer:2.9.5 /usr/bin/composer /usr/bin/composer

# Set composer environment
ENV COMPOSER_MEMORY_LIMIT=-1 \
    COMPOSER_FUND=0 \
    COMPOSER_CACHE_DIR=/opt/cache/composer

# Create composer cache directory
RUN mkdir -p ${COMPOSER_CACHE_DIR}

# Copy composer files first for better caching
COPY composer.json composer.lock* ./

# Install dependencies (without scripts - they may need full app)
RUN composer install --no-dev --no-scripts --optimize-autoloader --prefer-dist --ansi --no-interaction

# Copy application code
COPY . .

# Create empty Files folder (which will be overriden by mounted files from S3)
RUN mkdir /app/web/sites/default/files

# Ensure correct file permissions (e.g., 0775, a+w) if necessary
# https://www.drupal.org/docs/administering-a-drupal-site/security-in-drupal/securing-file-permissions-and-ownership
RUN chmod 775 /app/web/sites/default/files

# ===========================================
# Runtime stage - Final production image
# ===========================================
FROM php-extensions AS runtime

WORKDIR /app

# Copy Caddyfile (contains PHP config via php_ini directives)
COPY conf/Caddyfile /Caddyfile

# Copy built application from build stage
COPY --from=build /app /app

# Ensure vendor bin is in PATH for drush
ENV PATH="/app/vendor/bin:${PATH}"

# Environment variables
ENV APP_ENV=production \
    APP_DEBUG=false \
    LOG_CHANNEL=stderr \
    SERVER_NAME=:80 \
    SERVER_ROOT=/app/web

# FrankenPHP's entrypoint already handles starting the server with the Caddyfile
CMD ["docker-php-entrypoint", "--config", "/Caddyfile", "--adapter", "caddyfile"]
