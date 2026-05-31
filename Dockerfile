FROM php:8.3-fpm

WORKDIR /var/www/html

RUN apt-get update && apt-get install -y \
    git curl zip unzip \
    libicu-dev libxml2-dev libonig-dev \
    nginx \
    && rm -rf /var/lib/apt/lists/*

RUN docker-php-ext-install intl xml pdo pdo_mysql mbstring opcache

RUN curl -sS https://getcomposer.org/installer | php -- \
    --install-dir=/usr/local/bin \
    --filename=composer

# 1. COPY ONLY composer files FIRST
COPY composer.json composer.lock ./

# 2. INSTALL DEPENDENCIES FIRST
RUN COMPOSER_ALLOW_SUPERUSER=1 composer install \
    --optimize-autoloader \
    --no-interaction

# 3. COPY REST OF APP
COPY . .

# 4. FIX PERMISSIONS
RUN mkdir -p var/cache var/log var/sessions \
    && chmod -R 777 var

COPY nginx.conf /etc/nginx/conf.d/default.conf

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 8080

CMD ["/entrypoint.sh"]
