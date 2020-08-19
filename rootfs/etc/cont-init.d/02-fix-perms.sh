#!/usr/bin/with-contenv sh

echo "Fixing perms..."
mkdir -p /data \
  /var/run/nginx \
  /var/run/php-fpm
chown anonaddy. /data
chown -R anonaddy. \
  /tpls \
  /var/lib/nginx \
  /var/log/nginx \
  /var/log/php7 \
  /var/run/nginx \
  /var/run/php-fpm
