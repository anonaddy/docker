#!/usr/bin/with-contenv bash

# From https://github.com/docker-library/mariadb/blob/master/docker-entrypoint.sh#L21-L41
# usage: file_env VAR [DEFAULT]
#    ie: file_env 'XYZ_DB_PASSWORD' 'example'
# (will allow for "$XYZ_DB_PASSWORD_FILE" to fill in the value of
#  "$XYZ_DB_PASSWORD" from a file, especially for Docker's secrets feature)
file_env() {
  local var="$1"
  local fileVar="${var}_FILE"
  local def="${2:-}"
  if [ "${!var:-}" ] && [ "${!fileVar:-}" ]; then
    echo >&2 "error: both $var and $fileVar are set (but are exclusive)"
    exit 1
  fi
  local val="$def"
  if [ "${!var:-}" ]; then
    val="${!var}"
  elif [ "${!fileVar:-}" ]; then
    val="$(< "${!fileVar}")"
  fi
  export "$var"="$val"
  unset "$fileVar"
}

SIDECAR_POSTFIX=${SIDECAR_POSTFIX:-0}

#DB_HOST=${DB_HOST:-localhost}
DB_PORT=${DB_PORT:-3306}
DB_DATABASE=${DB_DATABASE:-anonaddy}
DB_USERNAME=${DB_USERNAME:-anonaddy}
#DB_PASSWORD=${DB_PASSWORD:-asupersecretpassword}

SMTP_PORT=${SMTP_PORT:-25}
SMTP_NETWORKS=${SMTP_NETWORKS:-172.16.0.0/12}

# Continue only if sidecar Postfix container
if [ "$SIDECAR_POSTFIX" != "1" ]; then
  exit 0
fi

file_env 'DB_USERNAME'
file_env 'DB_PASSWORD'
if [ -z "$DB_PASSWORD" ]; then
  >&2 echo "ERROR: Either DB_PASSWORD or DB_PASSWORD_FILE must be defined"
  exit 1
fi

# Master config
echo "Setting Postfix master configuration"
sed -i "s|^smtp.*inet.*|${SMTP_PORT} inet n - - - - smtpd -o content_filter=anonaddy:dummy|g" /etc/postfix/master.cf
cat >> /etc/postfix/master.cf <<EOL
anonaddy unix - n n - - pipe
  flags=F user=anonaddy argv=php /var/www/anonaddy/artisan anonaddy:receive-email --sender=\${sender} --recipient=\${recipient} --local_part=\${user} --extension=\${extension} --domain=\${domain} --size=\${size}
EOL

echo "Setting Postfix main configuration"
sed -i 's/inet_interfaces = localhost/inet_interfaces = all/g' /etc/postfix/main.cf
cat > /etc/postfix/main.cf <<EOL
smtpd_banner = \$myhostname ESMTP
biff = no

# appending .domain is the MUA's job.
append_dot_mydomain = no

readme_directory = no

# See http://www.postfix.org/COMPATIBILITY_README.html -- default to 2 on
# fresh installs.
compatibility_level = 2

# SMTP
smtp_tls_CApath = /etc/ssl/certs
smtp_use_tls=yes
smtp_tls_loglevel = 1
smtp_tls_session_cache_database = btree:\${data_directory}/smtp_scache
smtp_tls_mandatory_protocols = !SSLv2, !SSLv3, !TLSv1
smtp_tls_protocols = !SSLv2, !SSLv3, !TLSv1
smtp_tls_mandatory_ciphers = high
smtp_tls_ciphers = high
smtp_tls_mandatory_exclude_ciphers = MD5, DES, ADH, RC4, PSD, SRP, 3DES, eNULL, aNULL
smtp_tls_exclude_ciphers = MD5, DES, ADH, RC4, PSD, SRP, 3DES, eNULL, aNULL
smtp_tls_security_level = may

myhostname = mail.${ANONADDY_DOMAIN}
mydomain = ${ANONADDY_DOMAIN}
alias_maps = hash:/etc/aliases
alias_database = hash:/etc/aliases
myorigin = /etc/mailname
mydestination = localhost.\$mydomain, localhost

virtual_transport = anonaddy:
virtual_mailbox_domains = \$mydomain, unsubscribe.\$mydomain, mysql:/etc/postfix/mysql-virtual-alias-domains-and-subdomains.cf

relayhost =
mynetworks = 127.0.0.0/8 [::ffff:127.0.0.0]/104 [::1]/128 ${SMTP_NETWORKS}
mailbox_size_limit = 0
recipient_delimiter = +
inet_interfaces = all
inet_protocols = all

local_recipient_maps =

smtpd_helo_required = yes
smtpd_helo_restrictions =
    permit_mynetworks
    permit_sasl_authenticated
    reject_invalid_helo_hostname
    reject_non_fqdn_helo_hostname
    reject_unknown_helo_hostname

smtpd_sender_restrictions =
   permit_mynetworks
   permit_sasl_authenticated
   reject_non_fqdn_sender
   reject_unknown_sender_domain
   reject_unknown_reverse_client_hostname

smtpd_recipient_restrictions =
   permit_mynetworks,
   reject_unauth_destination,
   check_recipient_access mysql:/etc/postfix/mysql-recipient-access.cf, mysql:/etc/postfix/mysql-recipient-access-domains-and-additional-usernames.cf,
   check_policy_service unix:private/policyd-spf
   reject_rhsbl_helo dbl.spamhaus.org,
   reject_rhsbl_reverse_client dbl.spamhaus.org,
   reject_rhsbl_sender dbl.spamhaus.org,
   reject_rbl_client zen.spamhaus.org
   reject_rbl_client dul.dnsbl.sorbs.net

# Block clients that speak too early.
smtpd_data_restrictions = reject_unauth_pipelining

disable_vrfy_command = yes
strict_rfc821_envelopes = yes
maillog_file = /dev/stdout
EOL

echo "Creating virtual alias domains and subdomains configuration"
cat > /etc/postfix/mysql-virtual-alias-domains-and-subdomains.cf <<EOL
user = ${DB_USERNAME}
password = ${DB_PASSWORD}
hosts = ${DB_HOST}:${DB_PORT}
dbname = ${DB_DATABASE}
query = SELECT (SELECT 1 FROM users WHERE CONCAT(username, '.${ANONADDY_DOMAIN}') = '%s') AS users, (SELECT 1 FROM additional_usernames WHERE CONCAT(additional_usernames.username, '.${ANONADDY_DOMAIN}') = '%s') AS usernames, (SELECT 1 FROM domains WHERE domains.domain = '%s' AND domains.domain_verified_at IS NOT NULL) AS domains LIMIT 1;
EOL
chmod o= /etc/postfix/mysql-virtual-alias-domains-and-subdomains.cf
chgrp postfix /etc/postfix/mysql-virtual-alias-domains-and-subdomains.cf

echo "Creating recipient access configuration"
cat > /etc/postfix/mysql-recipient-access.cf <<EOL
user = ${DB_USERNAME}
password = ${DB_PASSWORD}
hosts = ${DB_HOST}:${DB_PORT}
dbname = ${DB_DATABASE}
query = CALL block_alias('%s')
EOL
chmod o= /etc/postfix/mysql-recipient-access.cf
chgrp postfix /etc/postfix/mysql-recipient-access.cf

echo "Creating recipient access domains and additional usernames configuration"
cat > /etc/postfix/mysql-recipient-access-domains-and-additional-usernames.cf <<EOL
user = ${DB_USERNAME}
password = ${DB_PASSWORD}
hosts = ${DB_HOST}:${DB_PORT}
dbname = ${DB_DATABASE}
query = SELECT (SELECT 'DISCARD' FROM additional_usernames WHERE (CONCAT(username, '.${ANONADDY_DOMAIN}') = SUBSTRING_INDEX('%s','@',-1)) AND active = 0) AS usernames, (SELECT 'DISCARD' FROM domains WHERE domain = SUBSTRING_INDEX('%s','@',-1) AND active = 0) AS domains LIMIT 1;
EOL
chmod o= /etc/postfix/mysql-recipient-access-domains-and-additional-usernames.cf
chgrp postfix /etc/postfix/mysql-recipient-access-domains-and-additional-usernames.cf

echo "Checking Postfix hostname"
postconf myhostname

echo "Creating stored procedure"
mysql -h ${DB_HOST} -P ${DB_PORT} -u "${DB_USERNAME}" "-p${DB_PASSWORD}" ${DB_DATABASE} <<EOL
DELIMITER //

DROP PROCEDURE IF EXISTS \`block_alias\`//

CREATE PROCEDURE \`block_alias\`(alias_email VARCHAR(254))
BEGIN
  UPDATE aliases SET
    emails_blocked = emails_blocked + 1
  WHERE email = alias_email AND active = 0 LIMIT 1;
  SELECT IF(deleted_at IS NULL,'DISCARD','REJECT') AS alias_action
  FROM aliases WHERE email = alias_email AND (active = 0 OR deleted_at IS NOT NULL) LIMIT 1;
END//

DELIMITER ;
EOL

mkdir -p /etc/services.d/postfix
cat > /etc/services.d/postfix/run <<EOL
#!/usr/bin/execlineb -P
/usr/sbin/postfix -c /etc/postfix start-fg
EOL
chmod +x /etc/services.d/postfix/run
