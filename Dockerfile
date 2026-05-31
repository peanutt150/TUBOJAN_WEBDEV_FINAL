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

# REMOVE DOCTRINE CONFIG FILES (Fixes the cache:clear error)
RUN rm -f config/packages/doctrine.yaml config/packages/doctrine_migrations.yaml

# Install dependencies
RUN COMPOSER_ALLOW_SUPERUSER=1 composer install \
    --optimize-autoloader \
    --no-interaction

# Create autoload_runtime.php symlink (Fixes the missing file error)
RUN if [ ! -f vendor/autoload_runtime.php ]; then \
        ln -sf autoload.php vendor/autoload_runtime.php; \
    fi

# Symfony required folders + fix permissions
RUN mkdir -p var/cache var/log var/sessions \
    && chmod -R 777 var

# Nginx config
COPY nginx-main.conf /etc/nginx/nginx.conf
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Entrypoint
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE ${PORT:-8080}

CMD ["/entrypoint.sh"]
