#!/bin/bash
set -e

echo "Starting container..."

# Get Railway's PORT (critical for Railway)
PORT="${PORT:-8080}"
echo "Using port: $PORT"

# Update Nginx to use Railway's PORT
if [ -f /etc/nginx/conf.d/default.conf ]; then
    echo "Updating Nginx to listen on port $PORT..."
    sed -i "s/listen 8080/listen $PORT/g" /etc/nginx/conf.d/default.conf
fi

# FIX PERMISSIONS FIRST (CRITICAL)
chown -R www-data:www-data /var/www/html/var || true
chmod -R 777 /var/www/html/var || true

# Ensure vendor directory permissions
chown -R www-data:www-data /var/www/html/vendor || true

echo "Starting PHP-FPM..."
php-fpm -D
sleep 2

# Verify PHP-FPM is running
if ! pgrep php-fpm > /dev/null; then
    echo "ERROR: PHP-FPM failed to start"
    exit 1
fi

# Symfony boot safety
if [ -f bin/console ]; then
    echo "Clearing cache..."
    php bin/console cache:clear --env=prod --no-debug || true
    
    # Only run migrations if Doctrine is installed
    if composer show | grep -q "doctrine/migrations"; then
        echo "Running migrations..."
        php bin/console doctrine:migrations:migrate --no-interaction --env=prod || true
    fi
fi

# Debug: verify critical files exist
echo "Verifying critical files:"
ls -la /var/www/html/public/index.php || echo "ERROR: index.php not found!"
ls -la /var/www/html/vendor/autoload_runtime.php || echo "ERROR: autoload_runtime.php not found!"

echo "Starting Nginx on port $PORT..."
exec nginx -g "daemon off;"
