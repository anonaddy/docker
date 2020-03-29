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

ANONADDY_DOMAIN=${ANONADDY_DOMAIN:-null}

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
echo "Setting Postfix master configuration..."
sed -i "s|^smtp.*inet.*|2500 inet n - - - - smtpd -o content_filter=anonaddy:dummy|g" /etc/postfix/master.cf
cat >> /etc/postfix/master.cf <<EOL
anonaddy unix - n n - - pipe
  flags=F user=anonaddy argv=php /var/www/anonaddy/artisan anonaddy:receive-email --sender=\${sender} --recipient=\${recipient} --local_part=\${user} --extension=\${extension} --domain=\${domain} --size=\${size}
EOL

echo "Setting Postfix main configuration..."
sed -i 's/inet_interfaces = localhost/inet_interfaces = all/g' /etc/postfix/main.cf
cat >> /etc/postfix/main.cf <<EOL
mynetworks = 127.0.0.0/8 [::ffff:127.0.0.0]/104 [::1]/128 ${SMTP_NETWORKS}
maillog_file = /dev/stdout
smtpd_recipient_restrictions = permit_mynetworks, reject_unauth_destination, check_recipient_access mysql:/etc/postfix/mysql-recipient-access.cf
local_recipient_maps =
EOL
if [ "${ANONADDY_DOMAIN}" != "null" ]; then
  cat >> /etc/postfix/main.cf <<EOL
myhostname = ${ANONADDY_DOMAIN}
EOL
fi

echo "Creating recipient access configuration..."
cat > /etc/postfix/mysql-recipient-access.cf <<EOL
user = ${DB_USERNAME}
password = ${DB_PASSWORD}
hosts = ${DB_HOST}:${DB_PORT}
dbname = ${DB_DATABASE}
query = CALL block_alias('%s')
EOL
chmod o= /etc/postfix/mysql-recipient-access.cf
chgrp postfix /etc/postfix/mysql-recipient-access.cf

echo "Creating stored procedure..."
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
