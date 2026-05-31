#!/bin/bash
set -e

echo "Starting..."

rm -rf var/cache/*

chown -R www-data:www-data /var/www/html/var || true
chmod -R 777 /var/www/html/var || true

php-fpm -D
sleep 2

exec nginx -g "daemon off;"
