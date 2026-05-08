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

if [ "$RSPAMD_GREYLIST_ENABLE" = true ]; then
  echo "Setting Rspamd greylist.conf"
  cat >/etc/rspamd/local.d/greylist.conf <<EOL
servers = "${REDIS_HOST}:${REDIS_PORT}";
EOL
else
  echo "Rspamd greylisting disabled"
  echo "enabled = false;" > /etc/rspamd/local.d/greylist.conf
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
secure_ip = "${RSPAMD_SECURE_IP}";
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

echo "Setting Rspamd actions.conf"
cat >/etc/rspamd/local.d/actions.conf <<EOL
reject = 500;
EOL

echo "Setting Rspamd milter_headers.conf"
cat >/etc/rspamd/local.d/milter_headers.conf <<EOL
use = ["authentication-results", "remove-headers", "spam-header", "add_dmarc_allow_header", "add_should_quarantine_header"];

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
  add_should_quarantine_header = <<EOD
return function(task, common_meta)
  local metric = task:get_metric_score('default')
  local score = metric and metric[1] or 0
  local reject_threshold = 15.0
  local should_quarantine = false
  local quarantine_reason = nil

  if score >= reject_threshold then
    should_quarantine = true
    quarantine_reason = quarantine_reason or '5.7.1 Spam message rejected'
  end

  if should_quarantine then
    return nil,
      {
        ['X-AnonAddy-Should-Quarantine'] = 'Yes',
        ['X-AnonAddy-Quarantine-Reason'] = quarantine_reason or '5.7.1 Spam message rejected'
      },
      {
        ['X-AnonAddy-Should-Quarantine'] = 0,
        ['X-AnonAddy-Quarantine-Reason'] = 0
      },
      {}
  end

  return nil,
    {},
    {
      ['X-AnonAddy-Should-Quarantine'] = 0,
      ['X-AnonAddy-Quarantine-Reason'] = 0
    },
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

# https://github.com/anonaddy/anonaddy/blob/fd4c71bef72213dd61b88b242c17be37c14158fe/SELF-HOSTING.md?plain=1#L933
echo "Setting Rspamd addy_blocklist.lua"
mkdir -p /etc/rspamd/lua.local.d
cat >/etc/rspamd/lua.local.d/addy_blocklist.lua <<EOL
local blocklist_api_url = '${APP_URL}/api/blocklist-check'
local blocklist_secret = '${BLOCKLIST_API_SECRET}'

-- Simple percent-encode for query parameter values (rspamd_http has no escape)
local function url_encode(s)
  if s == nil or s == '' then return '' end
  s = tostring(s)
  return (s:gsub('[^%w%-_.~ ]', function(c)
    return string.format('%%%02X', string.byte(c))
  end):gsub(' ', '%%20'))
end

local logger = require "rspamd_logger"
local rspamd_http = require 'rspamd_http'

rspamd_config:register_symbol({
  name = 'BLOCKLIST_USER',
  callback = function(task)
    local rcpts = task:get_recipients('smtp')
    local from_env = task:get_from('smtp')
    if not rcpts or #rcpts == 0 then
      logger.infox('blocklist: skip - missing recipient')
      return false
    end
    local recipient = (rcpts[1].addr and rcpts[1].addr:lower()) or ''

    local sender = ''
    if from_env and from_env.addr then
      sender = from_env.addr:lower()
    end

    local from_email = ''
    local from_hdr = task:get_header('From')
    if from_hdr then
      local raw = (type(from_hdr) == 'table') and (from_hdr[1] or from_hdr) or from_hdr
      raw = tostring(raw)
      from_email = raw:match('<([^>]+)>') or raw:match('%S+@%S+') or ''
      from_email = from_email:lower()
    end
    if from_email == '' then
      from_email = sender
    end

    if recipient == '' or (sender == '' and from_email == '') then
      logger.infox('blocklist: skip - missing recipient or from (recipient=%1, sender=%2, from_email=%3)', recipient, sender, from_email)
      return false
    end

    local url = blocklist_api_url
      .. '?recipient=' .. url_encode(recipient)
      .. '&from_email=' .. url_encode(from_email)

    local req_headers = {}
    if blocklist_secret ~= '' then
      req_headers['X-Blocklist-Secret'] = blocklist_secret
    end

    rspamd_http.request({
      url = url,
      headers = req_headers,
      timeout = 2.0,
      task = task,
      callback = function(err_message, code, body, _headers)
        if err_message then
          logger.warnx('blocklist: HTTP error - %1', err_message)
          return
        end
        if code == 200 and body and body:match('"block"%s*:%s*true') then
          task:set_pre_result('reject', '550 5.1.1 Address not found')
          task:insert_result(true, 'BLOCKLIST_USER', 1000.0, '550 5.1.1 Address not found')
          logger.infox('blocklist: BLOCKLIST_USER set for recipient=%1 from_email=%2', recipient, from_email)
        end
      end,
    })

    return false  -- do not match symbol here; only HTTP callback may add it via insert_result
  end,
  score = 1000.0,
})
EOL

echo "Disabling a variety of Rspamd modules"
echo "enabled = false;" > /etc/rspamd/override.d/fuzzy_check.conf
echo "enabled = false;" > /etc/rspamd/override.d/asn.conf
echo "enabled = false;" > /etc/rspamd/override.d/metadata_exporter.conf
echo "enabled = false;" > /etc/rspamd/override.d/trie.conf
echo "enabled = false;" > /etc/rspamd/override.d/neural.conf
echo "enabled = false;" > /etc/rspamd/override.d/chartable.conf
echo "enabled = false;" > /etc/rspamd/override.d/ratelimit.conf
echo "enabled = false;" > /etc/rspamd/override.d/replies.conf
