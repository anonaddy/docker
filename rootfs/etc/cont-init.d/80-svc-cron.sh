#!/usr/bin/with-contenv bash
# shellcheck shell=sh
set -e

. $(dirname $0)/00-env

CRONTAB_PATH="/var/spool/cron/crontabs"

CROND_LOG_OUTPUT="/dev/null"
ARTISAN_LOG_OUTPUT=" > /dev/null 2>&1"
if [ "$LOG_CROND" = "true" ]; then
  CROND_LOG_OUTPUT="/dev/stdout"
  ARTISAN_LOG_OUTPUT=""
fi

# Init
rm -rf ${CRONTAB_PATH}
mkdir -m 0644 -p ${CRONTAB_PATH}
echo "* * * * * php /var/www/anonaddy/artisan schedule:run --no-ansi --no-interaction${ARTISAN_LOG_OUTPUT}" >> ${CRONTAB_PATH}/anonaddy

# Fix perms
echo "Fixing crontabs permissions..."
chmod -R 0644 ${CRONTAB_PATH}

# Create service
mkdir -p /etc/services.d/cron
cat > /etc/services.d/cron/run <<EOL
#!/usr/bin/execlineb -P
with-contenv
exec busybox crond -f -L ${CROND_LOG_OUTPUT}
EOL
chmod +x /etc/services.d/cron/run
