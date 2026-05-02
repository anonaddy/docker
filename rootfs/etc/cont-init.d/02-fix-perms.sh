#!/usr/bin/with-contenv sh
# shellcheck shell=sh
set -e

echo "Fixing perms..."
mkdir -p /data \
  /data/dkim \
  /data/postfix/queue \
  /var/run/nginx \
  /var/run/php-fpm
chown anonaddy:anonaddy /data
touch /data/postfix/mail.log
chown anonaddy:anonaddy /data/postfix/mail.log
chown -R anonaddy:anonaddy \
  /data/dkim \
  /tpls \
  /var/lib/nginx \
  /var/log/nginx \
  /var/log/php84 \
  /var/run/nginx \
  /var/run/php-fpm \
  /var/www/anonaddy/bootstrap/cache \
  /var/www/anonaddy/config \
  /var/www/anonaddy/storage
