#!/bin/bash
set -e

echo "Starting container..."

# FIX PERMISSIONS FIRST (CRITICAL)
chown -R www-data:www-data /var/www/html/var || true
chmod -R 775 /var/www/html/var || true

echo "Starting PHP-FPM..."
php-fpm -D
sleep 2

# Symfony boot safety
if [ -f bin/console ]; then
  echo "Clearing cache..."
  php bin/console cache:clear --env=prod --no-debug || true

  echo "Running migrations..."
  php bin/console doctrine:migrations:migrate --no-interaction --env=prod || true
fi

echo "Starting Nginx..."
exec nginx -g "daemon off;"