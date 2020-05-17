#!/usr/bin/with-contenv bash

# From https://github.com/docker-library/mariadb/blob/master/docker-entrypoint.sh#L21-L41
# usage: file_env VAR [DEFAULT]
#    ie: file_env 'XYZ_DB_PASSWORD' 'example'
# (will allow for "$XYZ_DB_PASSWORD_FILE" to fill in the value of
#  "$XYZ_DB_PASSWORD" from a file, especially for Docker's secrets feature)
file_env() {
  local var="$1"
  local fileVar="${var}_FILE"
  local def="${2:-}"
  if [ "${!var:-}" ] && [ "${!fileVar:-}" ]; then
    echo >&2 "error: both $var and $fileVar are set (but are exclusive)"
    exit 1
  fi
  local val="$def"
  if [ "${!var:-}" ]; then
    val="${!var}"
  elif [ "${!fileVar:-}" ]; then
    val="$(< "${!fileVar}")"
  fi
  export "$var"="$val"
  unset "$fileVar"
}

TZ=${TZ:-UTC}
MEMORY_LIMIT=${MEMORY_LIMIT:-256M}
UPLOAD_MAX_SIZE=${UPLOAD_MAX_SIZE:-16M}
OPCACHE_MEM_SIZE=${OPCACHE_MEM_SIZE:-128}
LISTEN_IPV6=${LISTEN_IPV6:-true}
REAL_IP_FROM=${REAL_IP_FROM:-0.0.0.0/32}
REAL_IP_HEADER=${REAL_IP_HEADER:-X-Forwarded-For}
LOG_IP_VAR=${LOG_IP_VAR:-remote_addr}
SIDECAR_CRON=${SIDECAR_CRON:-0}
SIDECAR_POSTFIX=${SIDECAR_POSTFIX:-0}

APP_NAME=${APP_NAME:-AnonAddy}
#APP_KEY=${APP_KEY:-base64:Gh8/RWtNfXTmB09pj6iEflt/L6oqDf9ZxXIh4I9MS7A=}
APP_DEBUG=${APP_DEBUG:-false}
APP_URL=${APP_URL:-null}

#DB_HOST=${DB_HOST:-localhost}
DB_PORT=${DB_PORT:-3306}
DB_DATABASE=${DB_DATABASE:-anonaddy}
DB_USERNAME=${DB_USERNAME:-anonaddy}
#DB_PASSWORD=${DB_PASSWORD:-asupersecretpassword}
DB_TIMEOUT=${DB_TIMEOUT:-60}

REDIS_HOST=${REDIS_HOST:-null}
REDIS_PASSWORD=${REDIS_PASSWORD:-null}
REDIS_PORT=${REDIS_PORT:-6379}

#PUSHER_APP_ID=${PUSHER_APP_ID}
#PUSHER_APP_KEY=${PUSHER_APP_KEY}
#PUSHER_APP_SECRET=${PUSHER_APP_SECRET}
PUSHER_APP_CLUSTER=${PUSHER_APP_CLUSTER:-mt1}

ANONADDY_RETURN_PATH=${ANONADDY_RETURN_PATH:-null}
ANONADDY_ADMIN_USERNAME=${ANONADDY_ADMIN_USERNAME:-null}
ANONADDY_ENABLE_REGISTRATION=${ANONADDY_ENABLE_REGISTRATION:-false}
ANONADDY_DOMAIN=${ANONADDY_DOMAIN:-null}
ANONADDY_HOSTNAME=${ANONADDY_HOSTNAME:-null}
ANONADDY_DNS_RESOLVER=${ANONADDY_DNS_RESOLVER:-127.0.0.1}
ANONADDY_ALL_DOMAINS=${ANONADDY_ALL_DOMAINS:-null}
#ANONADDY_SECRET=${ANONADDY_SECRET:-long-random-string}
ANONADDY_LIMIT=${ANONADDY_LIMIT:-200}
ANONADDY_BANDWIDTH_LIMIT=${ANONADDY_BANDWIDTH_LIMIT:-104857600}
ANONADDY_NEW_ALIAS_LIMIT=${ANONADDY_NEW_ALIAS_LIMIT:-10}
ANONADDY_ADDITIONAL_USERNAME_LIMIT=${ANONADDY_ADDITIONAL_USERNAME_LIMIT:-3}
#ANONADDY_SIGNING_KEY_FINGERPRINT=${ANONADDY_SIGNING_KEY_FINGERPRINT:-your-signing-key-fingerprint}

MAIL_HOST=${MAIL_HOST:-postfix}
MAIL_PORT=${MAIL_PORT:-2500}
MAIL_FROM_NAME=${MAIL_FROM_NAME:-AnonAddy}
MAIL_FROM_ADDRESS=${MAIL_FROM_ADDRESS:-anonaddy@${ANONADDY_DOMAIN}}

# Timezone
echo "Setting timezone to ${TZ}..."
ln -snf /usr/share/zoneinfo/${TZ} /etc/localtime
echo ${TZ} > /etc/timezone

# PHP
echo "Setting PHP-FPM configuration..."
sed -e "s/@MEMORY_LIMIT@/$MEMORY_LIMIT/g" \
  -e "s/@UPLOAD_MAX_SIZE@/$UPLOAD_MAX_SIZE/g" \
  /tpls/etc/php7/php-fpm.d/www.conf > /etc/php7/php-fpm.d/www.conf

echo "Setting PHP INI configuration..."
sed -i "s|memory_limit.*|memory_limit = ${MEMORY_LIMIT}|g" /etc/php7/php.ini
sed -i "s|;date\.timezone.*|date\.timezone = ${TZ}|g" /etc/php7/php.ini

# OpCache
echo "Setting OpCache configuration..."
sed -e "s/@OPCACHE_MEM_SIZE@/$OPCACHE_MEM_SIZE/g" \
  /tpls/etc/php7/conf.d/opcache.ini > /etc/php7/conf.d/opcache.ini

# Nginx
echo "Setting Nginx configuration..."
sed -e "s#@UPLOAD_MAX_SIZE@#$UPLOAD_MAX_SIZE#g" \
  -e "s#@REAL_IP_FROM@#$REAL_IP_FROM#g" \
  -e "s#@REAL_IP_HEADER@#$REAL_IP_HEADER#g" \
  -e "s#@LOG_IP_VAR@#$LOG_IP_VAR#g" \
  /tpls/etc/nginx/nginx.conf > /etc/nginx/nginx.conf

if [ "$LISTEN_IPV6" != "true" ]; then
  sed -e '/listen \[::\]:/d' -i /etc/nginx/nginx.conf
fi

echo "Initializing files and folders..."
mkdir -p /data/storage
cp -Rf /var/www/anonaddy/storage /data
rm -rf /var/www/anonaddy/storage
ln -sf /data/storage /var/www/anonaddy/storage
chown -h anonaddy. /var/www/anonaddy/storage
chown -R anonaddy. /data/storage

echo "Checking database connection..."
if [ -z "$DB_HOST" ]; then
  >&2 echo "ERROR: DB_HOST must be defined"
  exit 1
fi
file_env 'DB_USERNAME'
file_env 'DB_PASSWORD'
if [ -z "$DB_PASSWORD" ]; then
  >&2 echo "ERROR: Either DB_PASSWORD or DB_PASSWORD_FILE must be defined"
  exit 1
fi
dbcmd="mysql -h ${DB_HOST} -P ${DB_PORT} -u "${DB_USERNAME}" "-p${DB_PASSWORD}""

echo "Waiting ${DB_TIMEOUT}s for database to be ready..."
counter=1
while ! ${dbcmd} -e "show databases;" > /dev/null 2>&1; do
  sleep 1
  counter=$((counter + 1))
  if [ ${counter} -gt ${DB_TIMEOUT} ]; then
    >&2 echo "ERROR: Failed to connect to database on $DB_HOST"
    exit 1
  fi;
done
echo "Database ready!"

file_env 'APP_KEY'
if [ -z "$APP_KEY" ]; then
  >&2 echo "ERROR: Either APP_KEY or APP_KEY_FILE must be defined"
  exit 1
fi
file_env 'ANONADDY_SECRET'
if [ -z "$ANONADDY_SECRET" ]; then
  >&2 echo "ERROR: Either ANONADDY_SECRET or ANONADDY_SECRET_FILE must be defined"
  exit 1
fi
file_env 'PUSHER_APP_SECRET'

echo "Creating AnonAddy env file..."
cat > /var/www/anonaddy/.env <<EOL
APP_NAME=${APP_NAME}
APP_ENV=production
APP_KEY=${APP_KEY}
APP_DEBUG=${APP_DEBUG}
APP_URL=${APP_URL}

LOG_CHANNEL=stack

DB_CONNECTION=mysql
DB_HOST=${DB_HOST}
DB_PORT=${DB_PORT}
DB_DATABASE=${DB_DATABASE}
DB_USERNAME=${DB_USERNAME}
DB_PASSWORD=${DB_PASSWORD}

BROADCAST_DRIVER=log
CACHE_DRIVER=file
QUEUE_CONNECTION=sync
SESSION_DRIVER=file
SESSION_LIFETIME=120

REDIS_HOST=${REDIS_HOST}
REDIS_PASSWORD=${REDIS_PASSWORD}
REDIS_PORT=${REDIS_PORT}

MAIL_DRIVER=smtp
MAIL_HOST=${MAIL_HOST}
MAIL_PORT=${MAIL_PORT}
MAIL_USERNAME=
MAIL_PASSWORD=
MAIL_ENCRYPTION=null
MAIL_FROM_NAME=${MAIL_FROM_NAME}
MAIL_FROM_ADDRESS=${MAIL_FROM_ADDRESS}

PUSHER_APP_ID=${PUSHER_APP_ID}
PUSHER_APP_KEY=${PUSHER_APP_KEY}
PUSHER_APP_SECRET=${PUSHER_APP_SECRET}
PUSHER_APP_CLUSTER=${PUSHER_APP_CLUSTER}

MIX_PUSHER_APP_KEY="\${PUSHER_APP_KEY}"
MIX_PUSHER_APP_CLUSTER="\${PUSHER_APP_CLUSTER}"

ANONADDY_RETURN_PATH=${ANONADDY_RETURN_PATH}
ANONADDY_ADMIN_USERNAME=${ANONADDY_ADMIN_USERNAME}
ANONADDY_ENABLE_REGISTRATION=${ANONADDY_ENABLE_REGISTRATION}
ANONADDY_DOMAIN=${ANONADDY_DOMAIN}
ANONADDY_HOSTNAME=${ANONADDY_HOSTNAME}
ANONADDY_DNS_RESOLVER=${ANONADDY_DNS_RESOLVER}
ANONADDY_ALL_DOMAINS=${ANONADDY_ALL_DOMAINS}
ANONADDY_SECRET=${ANONADDY_SECRET}
ANONADDY_LIMIT=${ANONADDY_LIMIT}
ANONADDY_BANDWIDTH_LIMIT=${ANONADDY_BANDWIDTH_LIMIT}
ANONADDY_NEW_ALIAS_LIMIT=${ANONADDY_NEW_ALIAS_LIMIT}
ANONADDY_ADDITIONAL_USERNAME_LIMIT=${ANONADDY_ADDITIONAL_USERNAME_LIMIT}
ANONADDY_SIGNING_KEY_FINGERPRINT=${ANONADDY_SIGNING_KEY_FINGERPRINT}
EOL
chown anonaddy. /var/www/anonaddy/.env

# Trust all proxies
su-exec anonaddy:anonaddy php artisan vendor:publish --no-interaction --provider="Fideloper\Proxy\TrustedProxyServiceProvider"
sed -i "s|^    'proxies'.*|    'proxies' => '\*',|g" /var/www/anonaddy/config/trustedproxy.php
