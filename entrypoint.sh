#!/bin/bash
set -e

echo "Starting container..."

# Get Railway's PORT
PORT="${PORT:-8080}"
echo "Using port: $PORT"

# Update Nginx to use Railway's PORT
if [ -f /etc/nginx/conf.d/default.conf ]; then
    echo "Updating Nginx to listen on port $PORT..."
    sed -i "s/listen 8080/listen $PORT/g" /etc/nginx/conf.d/default.conf
fi

# FIX PERMISSIONS
chown -R www-data:www-data /var/www/html/var || true
chmod -R 777 /var/www/html/var || true

# ==============================================
# CRITICAL FIX: Create autoload_runtime.php at runtime
# ==============================================
echo "Checking for autoload_runtime.php..."
if [ ! -f /var/www/html/vendor/autoload_runtime.php ]; then
    echo "Creating autoload_runtime.php symlink at runtime..."
    # Try absolute path first
    if [ -f /var/www/html/vendor/autoload.php ]; then
        ln -sf /var/www/html/vendor/autoload.php /var/www/html/vendor/autoload_runtime.php
        echo "Symlink created successfully"
    else
        echo "ERROR: vendor/autoload.php not found either!"
        ls -la /var/www/html/vendor/ | head -20
    fi
fi

# Verify it exists now
if [ -f /var/www/html/vendor/autoload_runtime.php ]; then
    echo "✓ autoload_runtime.php exists"
else
    echo "✗ autoload_runtime.php still missing - creating empty file as last resort"
    echo "<?php return require __DIR__.'/autoload.php'; ?>" > /var/www/html/vendor/autoload_runtime.php
fi

echo "Starting PHP-FPM..."
php-fpm -D
sleep 2

echo "Starting Nginx on port $PORT..."
exec nginx -g "daemon off;"
