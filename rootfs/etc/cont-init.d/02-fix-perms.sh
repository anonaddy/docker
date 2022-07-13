#!/usr/bin/with-contenv sh
# shellcheck shell=sh
set -e

echo "Fixing perms..."
mkdir -p /data \
  /data/dkim \
  /var/run/nginx \
  /var/run/php-fpm
chown anonaddy. /data
chown -R anonaddy. \
  /data/dkim \
  /tpls \
  /var/lib/nginx \
  /var/log/nginx \
  /var/log/php81 \
  /var/run/nginx \
  /var/run/php-fpm \
  /var/www/anonaddy/bootstrap/cache \
  /var/www/anonaddy/config \
  /var/www/anonaddy/storage
