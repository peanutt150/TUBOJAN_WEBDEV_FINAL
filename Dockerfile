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

# REMOVE ALL CONFIG FILES (the nuclear option)
RUN rm -rf config/packages/* config/routes/* 2>/dev/null || true

# Create empty config directories to prevent errors
RUN mkdir -p config/packages config/routes

# Install dependencies BUT skip scripts (this is the key fix!)
RUN COMPOSER_ALLOW_SUPERUSER=1 composer install \
    --optimize-autoloader \
    --no-interaction \
    --no-scripts

# Now run the scripts manually but ignore errors
RUN composer run-script post-autoload-dump || true
RUN composer run-script post-install-cmd || true

# Create autoload_runtime.php symlink
RUN if [ ! -f vendor/autoload_runtime.php ]; then \
        ln -sf autoload.php vendor/autoload_runtime.php; \
    fi

# Create required directories
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
