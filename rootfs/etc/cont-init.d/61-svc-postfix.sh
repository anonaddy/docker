#!/usr/bin/with-contenv bash
# shellcheck shell=bash
set -e

. $(dirname $0)/00-env

mkdir -p /etc/services.d/postfix
cat > /etc/services.d/postfix/run <<EOL
#!/usr/bin/execlineb -P
with-contenv
/usr/sbin/postfix -c /etc/postfix start-fg
EOL
chmod +x /etc/services.d/postfix/run

mkdir -p /etc/services.d/postfix-logs
cat > /etc/services.d/postfix-logs/run <<EOL
#!/usr/bin/execlineb -P
with-contenv
tail -F ${POSTFIX_LOG_PATH}
EOL
chmod +x /etc/services.d/postfix-logs/run
