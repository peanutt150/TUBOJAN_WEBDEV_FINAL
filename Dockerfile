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

# Copy ONLY composer files first (for layer caching)
COPY composer.json composer.lock* ./

# Install dependencies BEFORE copying full app
RUN COMPOSER_ALLOW_SUPERUSER=1 composer install \
    --optimize-autoloader \
    --no-interaction \
    --no-dev \
    --no-scripts

# Now copy the rest of the app
COPY . .

# Verify vendor exists
RUN ls -la vendor/autoload_runtime.php

RUN php bin/console cache:clear --env=prod || true

# Symfony required folders
RUN mkdir -p var/cache var/log var/sessions \
    && chmod -R 777 var

# Nginx config
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Entrypoint
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 8080

CMD ["/entrypoint.sh"]
