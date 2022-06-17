#!/usr/bin/with-contenv bash
# shellcheck shell=bash

. $(dirname $0)/00-env

if [ "$POSTSRSD_ENABLE" != "true" ]; then
  echo "INFO: PostSRSd service disabled."
  exit 0
fi
if [ -z "$SRS_DOMAIN" ]; then
  echo "WRN: SRS_DOMAIN required. PostSRSd service disabled."
  exit 0
fi

echo "Checking postsrsd.secret"
if [ ! -f /data/postsrsd.secret ]; then
  echo "Generating postsrsd.secret"
  dd if=/dev/urandom bs=18 count=1 status=none | base64 > /data/postsrsd.secret
fi

echo "Setting Postfix SRS configuration"
cat >>/etc/postfix/main.cf <<EOL

# SRS configuration
sender_canonical_maps = tcp:127.0.0.1:10001
sender_canonical_classes = envelope_sender
recipient_canonical_maps = tcp:127.0.0.1:10002
recipient_canonical_classes = envelope_recipient,header_recipient
EOL
