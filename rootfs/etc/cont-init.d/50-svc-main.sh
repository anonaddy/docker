#!/usr/bin/with-contenv bash
# shellcheck shell=bash
set -e

echo "DB migration"
anonaddy migrate --no-interaction --force

echo "Clear cache"
anonaddy cache:clear --no-interaction
anonaddy config:cache --no-interaction
anonaddy view:cache --no-interaction
anonaddy route:cache --no-interaction
anonaddy queue:restart --no-interaction

mkdir -p /etc/services.d/nginx
cat > /etc/services.d/nginx/run <<EOL
#!/usr/bin/execlineb -P
with-contenv
s6-setuidgid ${PUID}:${PGID}
nginx -g "daemon off;"
EOL
chmod +x /etc/services.d/nginx/run

mkdir -p /etc/services.d/php-fpm
cat > /etc/services.d/php-fpm/run <<EOL
#!/usr/bin/execlineb -P
with-contenv
s6-setuidgid ${PUID}:${PGID}
php-fpm84 -F
EOL
chmod +x /etc/services.d/php-fpm/run

# Read the cached configuration after /data/.env overrides have been applied.
queue_connection=$(php -r '$config = require "/var/www/anonaddy/bootstrap/cache/config.php"; echo $config["queue"]["default"];')

# Remove a previously generated service when restarting with another connection.
rm -rf /etc/services.d/queue
if [ "$queue_connection" = "redis" ]; then
  echo "Creating Redis queue worker"
  mkdir -p /etc/services.d/queue
  cat > /etc/services.d/queue/run <<EOL
#!/usr/bin/execlineb -P
with-contenv
s6-setuidgid ${PUID}:${PGID}
php /var/www/anonaddy/artisan queue:work redis --sleep=3 --tries=3 --backoff=5 --timeout=60 --no-interaction --no-ansi
EOL
  chmod +x /etc/services.d/queue/run
else
  echo "INFO: Redis queue worker disabled (connection: ${queue_connection})."
fi
