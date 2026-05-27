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

# Copy project
COPY . .

# Install PHP dependencies
RUN COMPOSER_ALLOW_SUPERUSER=1 composer install \
    --no-dev \
    --optimize-autoloader \
    --no-interaction \
    --no-scripts

# Writable Symfony folders
RUN mkdir -p var/cache var/log var/sessions \
    && chmod -R 777 var

# Nginx config
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Entrypoint
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 8080

CMD ["/entrypoint.sh"]