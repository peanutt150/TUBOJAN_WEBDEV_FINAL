FROM php:8.3-fpm

WORKDIR /var/www/html

# System dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    git curl zip unzip \
    libicu-dev libxml2-dev libonig-dev \
    nginx \
    && rm -rf /var/lib/apt/lists/*

# PHP extensions
RUN docker-php-ext-install \
    intl xml pdo pdo_mysql mbstring opcache

# Composer
RUN curl -sS https://getcomposer.org/installer | php -- \
    --install-dir=/usr/local/bin \
    --filename=composer

# Copy app
COPY . .

# Install dependencies (FIXED: removed trailing backslash)
RUN COMPOSER_ALLOW_SUPERUSER=1 composer install \
    --optimize-autoloader \
    --no-interaction

# FIX: Create autoload_runtime.php symlink if missing (critical for Railway)
RUN if [ ! -f vendor/autoload_runtime.php ]; then \
        echo "Creating symlink for autoload_runtime.php"; \
        ln -sf autoload.php vendor/autoload_runtime.php; \
    fi

# Debug: verify files exist
RUN ls -la vendor/ | head -20

# Clear cache
RUN php bin/console cache:clear --env=prod || true

# Symfony required folders + FIX PERMISSIONS
RUN mkdir -p var/cache var/log var/sessions \
    && chmod -R 777 var

# Nginx config (main and site config)
COPY nginx-main.conf /etc/nginx/nginx.conf
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Entrypoint
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Use Railway's PORT environment variable
EXPOSE ${PORT:-8080}

CMD ["/entrypoint.sh"]
