#!/usr/bin/with-contenv bash
# shellcheck shell=bash

. $(dirname $0)/00-env

if [ "$DKIM_ENABLE" != "true" ]; then
  echo "INFO: OpenDKIM service disabled."
  exit 0
fi
if [ ! -f "$DKIM_PRIVATE_KEY" ]; then
  echo "WRN: $DKIM_PRIVATE_KEY not found. OpenDKIM service disabled."
  exit 0
fi

echo "Copying OpenDKIM private key"
mkdir -p /var/db/dkim
cp -f "${DKIM_PRIVATE_KEY}" "/var/db/dkim/${ANONADDY_DOMAIN}.private"

echo "Setting OpenDKIM configuration"
cat >/etc/opendkim/opendkim.conf <<EOL
BaseDirectory         /var/spool/postfix/opendkim

LogWhy                yes
Syslog                yes
SyslogSuccess         yes

Canonicalization      simple
Mode                  sv
SubDomains            yes

KeyTable              refile:/etc/opendkim/key.table
SigningTable          refile:/etc/opendkim/signing.table
RequireSafeKeys       false

ExternalIgnoreList    /etc/opendkim/trusted.hosts
InternalHosts         /etc/opendkim/trusted.hosts

Socket                local:/var/spool/postfix/opendkim/opendkim.sock
UMask                 007
PidFile               /var/spool/postfix/opendkim/opendkim.pid
UserID                opendkim

ReportAddress         ${DKIM_REPORT_ADDRESS}
SendReports           yes
EOL

echo "Setting OpenDKIM trusted hosts"
cat >/etc/opendkim/trusted.hosts <<EOL
127.0.0.1
localhost
*.${ANONADDY_DOMAIN}
EOL

echo "Setting OpenDKIM signing table"
cat >/etc/opendkim/signing.table <<EOL
*@${ANONADDY_DOMAIN}    default._domainkey.${ANONADDY_DOMAIN}
*@*.${ANONADDY_DOMAIN}    default._domainkey.${ANONADDY_DOMAIN}
EOL

echo "Setting OpenDKIM key table"
cat >/etc/opendkim/key.table <<EOL
default._domainkey.${ANONADDY_DOMAIN}    ${ANONADDY_DOMAIN}:default:/var/db/dkim/${ANONADDY_DOMAIN}.private
EOL
