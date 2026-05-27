#!/bin/bash
set -e

echo "Starting container..."

# Fix permissions
if [ -d /var/www/html/var ]; then
  chmod -R 777 /var/www/html/var || true
  chown -R www-data:www-data /var/www/html/var || true
fi

echo "Starting PHP-FPM..."
php-fpm -D
sleep 2

# Symfony setup
if [ -f bin/console ]; then
  echo "Running Symfony setup..."

  php bin/console cache:clear --env=prod --no-debug || true
  php bin/console doctrine:migrations:migrate --no-interaction --env=prod || true
fi

echo "Starting Nginx..."
exec nginx -g "daemon off;"