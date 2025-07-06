#!/usr/bin/with-contenv bash
# shellcheck shell=bash
set -e

. $(dirname $0)/00-env

if [ "$RSPAMD_ENABLE" != "true" ]; then
  echo "INFO: Rspamd service disabled."
  exit 0
fi

echo "Determining shared domains"
CHECK_DOMAINS="${ANONADDY_ALL_DOMAINS}"
if [[ "${CHECK_DOMAINS}" != *"${ANONADDY_DOMAIN}"* ]]; then
    CHECK_DOMAINS="${ANONADDY_DOMAIN} ${CHECK_DOMAINS}"
fi

echo "Building DKIM tables"
CONFIG_SIGNING_TABLE=
CONFIG_KEY_TABLE=
for DOM in ${CHECK_DOMAINS//,/ }; do
  CONFIG_SIGNING_TABLE=$( printf '%s\n"*@%s %s",\n"*@*.%s %s",' "${CONFIG_SIGNING_TABLE}" "${DOM}" "${DOM}" "${DOM}" "${DOM}")
  CONFIG_KEY_TABLE=$( printf '%s\n"%s %s:%s:/var/lib/rspamd/dkim/%s.%s.key",' "${CONFIG_KEY_TABLE}" "${DOM}" "${DOM}" "${ANONADDY_DKIM_SELECTOR}" "${DOM}" "${ANONADDY_DKIM_SELECTOR}")
  # try to register a new dkim and if it fails don't exit this script.
  # failure can occur when the files have already been generated.
  /bin/sh /usr/local/bin/gen-dkim "${DOM}" >/dev/null 2>/dev/null && true
done
CONFIG_SIGNING_TABLE="${CONFIG_SIGNING_TABLE#*$'\n'}"
CONFIG_KEY_TABLE="${CONFIG_KEY_TABLE#*$'\n'}"

echo "Setting Rspamd dkim_signing.conf"
cat >/etc/rspamd/local.d/dkim_signing.conf <<EOL
signing_table = [
${CONFIG_SIGNING_TABLE}
];

key_table = [
${CONFIG_KEY_TABLE}
];

use_domain = "envelope";
allow_hdrfrom_mismatch = true;
allow_hdrfrom_mismatch_sign_networks = true;
allow_username_mismatch = true;
use_esld = true;
sign_authenticated = false;
EOL

echo "Copying and moving keys for shared domains"
for file in /data/dkim/*.private; do
    cp "$file" "${file%.*}.${ANONADDY_DKIM_SELECTOR}.key"
done
mkdir -p /var/lib/rspamd/dkim
mv /data/dkim/*.key /var/lib/rspamd/dkim/

echo "Setting Rspamd arc.conf"
cp /etc/rspamd/local.d/dkim_signing.conf /etc/rspamd/local.d/arc.conf

# Note to future self, if you are stuck, then read these instructions.
#
# Run these commands in your addy docker folder, they generate two
# local variables you can use to generate the DNS records you need:
#
# YOUR_DOMAIN_NAME=idhi.de
# DKIM_DOM="$( cat data/dkim/${YOUR_DOMAIN_NAME}.txt | tr -d '\n\\"' | sed -r 's/[[:space:]]+/ /g' | sed -E 's/ ([^;])/\1/g' | grep -oP '\(\K[^)]+' )"
#
# These are the DNS records required for a bare domain (you will need to
# amend these for subdomains and fill in the ANONADDY_* variables yourself,
# I'm not going to do all the work for you):
#
# TXT ${ANONADDY_DKIM_SELECTOR}._domainkey.${YOUR_DOMAIN_NAME} ${DKIM_DOM}
# MX ${YOUR_DOMAIN_NAME} ${ANONADDY_DOMAIN}. 10
# TXT ${YOUR_DOMAIN_NAME} v=spf1 mx include:${ANONADDY_DOMAIN} ~all
# TXT _dmarc.${YOUR_DOMAIN_NAME} v=DMARC1; p=reject; rua=mailto:postmaster@${YOUR_DOMAIN_NAME}; ruf=mailto:postmaster@${YOUR_DOMAIN_NAME}; pct=100; adkim=r; aspf=r
#
# You will need to add these records wherever your domain name is registered.

echo "Setting Rspamd classifier-bayes.conf"
cat >/etc/rspamd/local.d/classifier-bayes.conf <<EOL
backend = "redis";
EOL

echo "Setting Rspamd logging.inc"
cat >/etc/rspamd/local.d/logging.inc <<EOL
level = "error";
debug_modules = [];
EOL

if [ -n "$REDIS_HOST" ]; then
  echo "Setting Rspamd redis.conf"
  cat >/etc/rspamd/local.d/redis.conf <<EOL
write_servers = "${REDIS_HOST}";
password = "${REDIS_PASSWORD}";
read_servers = "${REDIS_HOST}";
EOL

if [ "${RSPAMD_GREYLIST_ENABLE:-true}" = true ]
then
  echo "Setting Rspamd greylist.conf"
  cat >/etc/rspamd/local.d/greylist.conf <<EOL
servers = "${REDIS_HOST}:${REDIS_PORT}";
EOL
else
  echo "Disabling greylisting"
  echo "enabled = false;" > /etc/rspamd/override.d/greylist.conf
fi

  echo "Setting Rspamd history_redis.conf"
  cat >/etc/rspamd/local.d/history_redis.conf <<EOL
subject_privacy = true;
EOL
fi

echo "Setting Rspamd groups.conf"
cat >/etc/rspamd/local.d/groups.conf <<EOL
group "headers" {
  symbols {
    "FAKE_REPLY" {
      weight = 0.0;
    }

    "FROM_NEQ_DISPLAY_NAME" {
      weight = 0.0;
    }

    "FORGED_RECIPIENTS" {
      weight = 0.0;
    }
  }
}
EOL

if [ -n "$RSPAMD_WEB_PASSWORD" ]; then
  echo "Setting Rspamd worker-controller.inc"
  cat >/etc/rspamd/local.d/worker-controller.inc <<EOL
bind_socket = "*:11334";
secure_ip = "127.0.0.1/32";
password = "${RSPAMD_WEB_PASSWORD}";
enable_password = "${RSPAMD_WEB_PASSWORD}";
EOL
fi

echo "Setting Rspamd dmarc.conf"
cat >/etc/rspamd/local.d/dmarc.conf <<EOL
actions = {
  quarantine = "add_header";
  reject = "reject";
}
EOL

echo "Setting Rspamd milter_headers.conf"
cat >/etc/rspamd/local.d/milter_headers.conf <<EOL
use = ["authentication-results", "remove-headers", "spam-header", "add_dmarc_allow_header"];

routines {
  remove-headers {
    headers {
      "X-Spam" = 0;
      "X-Spamd-Bar" = 0;
      "X-Spam-Level" = 0;
      "X-Spam-Status" = 0;
      "X-Spam-Flag" = 0;
    }
  }
  authentication-results {
    header = "X-AnonAddy-Authentication-Results";
    remove = 0;
  }
  spam-header {
    header = "X-AnonAddy-Spam";
    value = "Yes";
    remove = 0;
  }
}

custom {
  add_dmarc_allow_header = <<EOD
return function(task, common_meta)
  if task:has_symbol('DMARC_POLICY_ALLOW') then
    return nil,
    {['X-AnonAddy-Dmarc-Allow'] = 'Yes'},
    {['X-AnonAddy-Dmarc-Allow'] = 0},
    {}
  end

  return nil,
  {},
  {['X-AnonAddy-Dmarc-Allow'] = 0},
  {}
end
EOD;
}
EOL

if [ "$RSPAMD_NO_LOCAL_ADDRS" = "true" ]; then
  echo "Disabling Rspamd local networks"
  # Empty the local_addrs array to avoid having Rspamd skip DMARC and SPF checks
  # if the mailserver is running in a local network. Required since it checks
  # the headers injected by Rspamd. See https://github.com/anonaddy/docker/issues/192#issuecomment-1518111988
  sed -i 's/local_addrs.*$/local_addrs=[]/' /etc/rspamd/options.inc
fi

echo "Disabling a variety of Rspamd modules"
echo "enabled = false;" > /etc/rspamd/override.d/fuzzy_check.conf
echo "enabled = false;" > /etc/rspamd/override.d/asn.conf
echo "enabled = false;" > /etc/rspamd/override.d/metadata_exporter.conf
echo "enabled = false;" > /etc/rspamd/override.d/trie.conf
echo "enabled = false;" > /etc/rspamd/override.d/neural.conf
echo "enabled = false;" > /etc/rspamd/override.d/chartable.conf
echo "enabled = false;" > /etc/rspamd/override.d/ratelimit.conf
echo "enabled = false;" > /etc/rspamd/override.d/replies.conf
