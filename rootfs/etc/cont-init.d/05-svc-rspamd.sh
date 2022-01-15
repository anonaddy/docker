#!/usr/bin/with-contenv bash
# shellcheck shell=bash

RSPAMD_ENABLE=${RSPAMD_ENABLE:-false}

if [ "$RSPAMD_ENABLE" != "true" ]; then
  echo "INFO: Rspamd service disabled."
  exit 0
fi

# Init
mkdir -m o-rwx /var/run/rspamd
chown rspamd. /var/run/rspamd

# Fix perms
chown -R rspamd. /etc/rspamd /var/lib/rspamd

# Create service
mkdir -p /etc/services.d/rspamd
cat >/etc/services.d/rspamd/run <<EOL
#!/usr/bin/execlineb -P
with-contenv
/usr/sbin/rspamd -i -f -u rspamd -g rspamd
EOL
chmod +x /etc/services.d/rspamd/run
