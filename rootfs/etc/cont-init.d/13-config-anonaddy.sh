#!/usr/bin/with-contenv bash
# shellcheck shell=bash
set -e

. $(dirname $0)/00-env

if [ -z "$APP_KEY" ]; then
  echo >&2 "ERROR: Either APP_KEY or APP_KEY_FILE must be defined"
  exit 1
fi
if [ -z "$ANONADDY_DOMAIN" ]; then
  echo >&2 "ERROR: ANONADDY_DOMAIN must be defined"
  exit 1
fi

if [ -z "$ANONADDY_SECRET" ]; then
  echo >&2 "ERROR: Either ANONADDY_SECRET or ANONADDY_SECRET_FILE must be defined"
  exit 1
fi

dotenv_entry() {
  local name="$1"
  local value="${2-}"

  value=${value//\\/\\\\}
  value=${value//\"/\\\"}
  value=${value//\$/\\$}
  value=${value//$'\n'/\\n}
  value=${value//$'\r'/\\r}

  printf '%s="%s"\n' "$name" "$value"
}

echo "Creating env file"
{
  dotenv_entry "APP_NAME" "$APP_NAME"
  dotenv_entry "APP_ENV" "production"
  dotenv_entry "APP_KEY" "$APP_KEY"
  dotenv_entry "APP_DEBUG" "$APP_DEBUG"
  dotenv_entry "APP_URL" "$APP_URL"

  printf '\n'
  dotenv_entry "LOG_CHANNEL" "stack"

  printf '\n'
  dotenv_entry "DB_CONNECTION" "mysql"
  dotenv_entry "DB_HOST" "$DB_HOST"
  dotenv_entry "DB_PORT" "$DB_PORT"
  dotenv_entry "DB_DATABASE" "$DB_DATABASE"
  dotenv_entry "DB_USERNAME" "$DB_USERNAME"
  dotenv_entry "DB_PASSWORD" "$DB_PASSWORD"

  printf '\n'
  dotenv_entry "BROADCAST_DRIVER" "log"
  dotenv_entry "CACHE_DRIVER" "file"
  dotenv_entry "QUEUE_CONNECTION" "sync"
  dotenv_entry "SESSION_DRIVER" "file"
  dotenv_entry "SESSION_LIFETIME" "120"

  printf '\n'
  dotenv_entry "REDIS_CLIENT" "phpredis"
  dotenv_entry "REDIS_HOST" "$REDIS_HOST"
  dotenv_entry "REDIS_PASSWORD" "$REDIS_PASSWORD"
  dotenv_entry "REDIS_PORT" "$REDIS_PORT"

  printf '\n'
  dotenv_entry "MAIL_FROM_NAME" "$MAIL_FROM_NAME"
  dotenv_entry "MAIL_FROM_ADDRESS" "$MAIL_FROM_ADDRESS"
  dotenv_entry "MAIL_DRIVER" "smtp"
  dotenv_entry "MAIL_HOST" "127.0.0.1"
  dotenv_entry "MAIL_PORT" "25"
  dotenv_entry "MAIL_ENCRYPTION" "$MAIL_ENCRYPTION"

  printf '\n'
  dotenv_entry "PUSHER_APP_ID" "$PUSHER_APP_ID"
  dotenv_entry "PUSHER_APP_KEY" "$PUSHER_APP_KEY"
  dotenv_entry "PUSHER_APP_SECRET" "$PUSHER_APP_SECRET"
  dotenv_entry "PUSHER_APP_CLUSTER" "$PUSHER_APP_CLUSTER"

  printf '\n'
  dotenv_entry "MIX_PUSHER_APP_KEY" "$PUSHER_APP_KEY"
  dotenv_entry "MIX_PUSHER_APP_CLUSTER" "$PUSHER_APP_CLUSTER"

  printf '\n'
  dotenv_entry "SANCTUM_STATEFUL_DOMAINS" "$(echo "$APP_URL" | awk -F/ '{print $3}')"

  printf '\n'
  dotenv_entry "ANONADDY_RETURN_PATH" "$ANONADDY_RETURN_PATH"
  dotenv_entry "ANONADDY_ADMIN_USERNAME" "$ANONADDY_ADMIN_USERNAME"
  dotenv_entry "ANONADDY_ENABLE_REGISTRATION" "$ANONADDY_ENABLE_REGISTRATION"
  dotenv_entry "ANONADDY_DOMAIN" "$ANONADDY_DOMAIN"
  dotenv_entry "ANONADDY_HOSTNAME" "$ANONADDY_HOSTNAME"
  dotenv_entry "ANONADDY_DNS_RESOLVER" "$ANONADDY_DNS_RESOLVER"
  dotenv_entry "ANONADDY_ALL_DOMAINS" "$ANONADDY_ALL_DOMAINS"
  dotenv_entry "ANONADDY_NON_ADMIN_SHARED_DOMAINS" "$ANONADDY_NON_ADMIN_SHARED_DOMAINS"
  dotenv_entry "ANONADDY_SECRET" "$ANONADDY_SECRET"
  dotenv_entry "ANONADDY_LIMIT" "$ANONADDY_LIMIT"
  dotenv_entry "ANONADDY_BANDWIDTH_LIMIT" "$ANONADDY_BANDWIDTH_LIMIT"
  dotenv_entry "ANONADDY_BANDWIDTH_LIMIT_ENABLED" "$ANONADDY_BANDWIDTH_LIMIT_ENABLED"
  dotenv_entry "ANONADDY_NEW_ALIAS_LIMIT" "$ANONADDY_NEW_ALIAS_LIMIT"
  dotenv_entry "ANONADDY_ADDITIONAL_USERNAME_LIMIT" "$ANONADDY_ADDITIONAL_USERNAME_LIMIT"
  dotenv_entry "ANONADDY_SIGNING_KEY_FINGERPRINT" "$ANONADDY_SIGNING_KEY_FINGERPRINT"
  dotenv_entry "ANONADDY_DKIM_SIGNING_KEY" "$ANONADDY_DKIM_SIGNING_KEY"
  dotenv_entry "ANONADDY_DKIM_SELECTOR" "$ANONADDY_DKIM_SELECTOR"

  printf '\n'
  dotenv_entry "BLOCKLIST_API_ALLOWED_IPS" "$BLOCKLIST_API_ALLOWED_IPS"
  dotenv_entry "BLOCKLIST_API_SECRET" "$BLOCKLIST_API_SECRET"

  printf '\n'
  dotenv_entry "POSTFIX_LOG_PATH" "$POSTFIX_LOG_PATH"

  printf '\n'
} >/var/www/anonaddy/.env

if [ -f "/data/.env" ]; then
  cat "/data/.env" >> /var/www/anonaddy/.env
fi

chown anonaddy:anonaddy /var/www/anonaddy/.env

echo "Trust all proxies"
sed -i "s|^    protected \$proxies.*|    protected \$proxies = '\*';|g" /var/www/anonaddy/vendor/laravel/framework/src/Illuminate/Http/Middleware/TrustProxies.php
