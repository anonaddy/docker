#!/usr/bin/with-contenv bash

SIDECAR_CRON=${SIDECAR_CRON:-0}

if [ "$SIDECAR_CRON" = "1" ]; then
  exit 0
fi

mkdir -p /etc/services.d/postfix
cat > /etc/services.d/postfix/run <<EOL
#!/usr/bin/execlineb -P
/usr/sbin/postfix -c /etc/postfix start-fg
EOL
chmod +x /etc/services.d/postfix/run
