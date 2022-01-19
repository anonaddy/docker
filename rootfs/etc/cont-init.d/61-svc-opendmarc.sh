#!/usr/bin/with-contenv bash
# shellcheck shell=bash

. $(dirname $0)/00-env

if [ "$DMARC_ENABLE" != "true" ]; then
  echo "INFO: OpenDMARC service disabled."
  exit 0
fi

# Init
mkdir -m o-rwx /var/spool/postfix/opendmarc
chown opendmarc:postfix /var/spool/postfix/opendmarc

# Fix perms
chown -R opendmarc. /data/dmarc /etc/opendmarc

# Create service
mkdir -p /etc/services.d/opendmarc
cat > /etc/services.d/opendmarc/run <<EOL
#!/usr/bin/execlineb -P
with-contenv
/usr/sbin/opendmarc -f -u opendmarc -c /etc/opendmarc/opendmarc.conf
EOL
chmod +x /etc/services.d/opendmarc/run
