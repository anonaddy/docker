#!/usr/bin/with-contenv sh

echo "Fixing perms..."
chown anonaddy. /data
chown -R anonaddy. \
  /tpls \
  /var/lib/nginx \
  /var/log/nginx \
  /var/log/php7 \
  /var/run/nginx \
  /var/run/php-fpm \
  /var/tmp/nginx \
  /var/www/anonaddy/database
