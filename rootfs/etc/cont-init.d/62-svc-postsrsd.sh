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

# Init
mkdir -m o-rwx /usr/lib/postsrsd
chown postsrsd. /usr/lib/postsrsd

# Fix perms
chown -R postsrsd. /data/postsrsd.secret /usr/lib/postsrsd
chmod 600 /data/postsrsd.secret

flags=(-s /data/postsrsd.secret)
if [ -n "$SRS_DOMAIN" ]; then
  flags+=(-d "${SRS_DOMAIN}")
fi
if [ -n "$SRS_SEPARATOR" ]; then
  flags+=(-a "${SRS_SEPARATOR}")
fi
if [ -n "$SRS_HASHLENGTH" ]; then
  flags+=(-n "${SRS_HASHLENGTH}")
fi
if [ -n "$SRS_HASHMIN" ]; then
  flags+=(-N "${SRS_HASHMIN}")
fi
flags+=(-l 127.0.0.1 -f 10001 -r 10002)
flags+=(-c /usr/lib/postsrsd -u postsrsd)
if [ -n "$SRS_EXCLUDE_DOMAINS" ]; then
  flags+=(-X "${SRS_EXCLUDE_DOMAINS}")
fi

# Create service
# https://github.com/roehling/postsrsd/blob/6e701fa51f26bb344bc0230cdfb13ae1e14afb8d/postsrsd.c#L271-L312
mkdir -p /etc/services.d/postsrsd
cat >/etc/services.d/postsrsd/run <<EOL
#!/usr/bin/execlineb -P
with-contenv
/usr/sbin/postsrsd ${flags[@]}
EOL
chmod +x /etc/services.d/postsrsd/run
