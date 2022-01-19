#!/usr/bin/with-contenv bash
# shellcheck shell=bash

. $(dirname $0)/00-env

if [ "$DMARC_ENABLE" != "true" ]; then
  echo "INFO: OpenDMARC service disabled."
  exit 0
fi

echo "Setting OpenDMARC configuration"
cat >/etc/opendmarc/opendmarc.conf <<EOL
BaseDirectory               /var/spool/postfix/opendmarc

AuthservID                  OpenDMARC
TrustedAuthservIDs          ${ANONADDY_HOSTNAME}

Syslog                      yes
DNSTimeout                  10

FailureReports              ${DMARC_FAILURE_REPORTS}
FailureReportsOnNone        false
FailureReportsSentBy        postmaster@${ANONADDY_DOMAIN}

HistoryFile                 /data/dmarc/opendmarc.dat
RecordAllMessages           false

IgnoreAuthenticatedClients  true

MilterDebug                 ${DMARC_MILTER_DEBUG}

RejectFailures              true
RequiredHeaders             true

Socket                      local:/var/spool/postfix/opendmarc/opendmarc.sock
UMask                       007
PidFile                     /var/spool/postfix/opendmarc/opendmarc.pid
UserID                      opendmarc

SoftwareHeader              true
SPFIgnoreResults            true
SPFSelfValidate             true
EOL
