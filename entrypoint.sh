#!/bin/bash
set -e

echo "Starting container..."

# Fix permissions
chown -R www-data:www-data /var/www/html/var || true
chmod -R 777 /var/www/html/var || true

echo "Starting PHP-FPM..."
php-fpm -D
sleep 2

# Symfony safety
if [ -f bin/console ]; then
  echo "Running migrations..."
  php bin/console doctrine:migrations:migrate --no-interaction --env=prod || true
fi

echo "Starting Nginx..."
exec nginx -g "daemon off;"
