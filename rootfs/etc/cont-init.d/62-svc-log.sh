#!/usr/bin/with-contenv bash
# shellcheck shell=bash
set -e

. $(dirname $0)/00-env

mkdir -p /etc/services.d/maillog
cat > /etc/services.d/maillog/run <<EOL
#!/usr/bin/execlineb -P
with-contenv
tail -F ${POSTFIX_LOG_PATH}
EOL
chmod +x /etc/services.d/maillog/run
