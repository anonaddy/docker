#!/bin/sh
set -eu

active=$(s6-rc -a list)
expected="nginx php-fpm postfix postfix-logs cron"
absent=""

if [ "${1:-sync}" = redis ]; then
  expected="$expected queue"
else
  absent="$absent queue"
fi
if [ "${2:-true}" = true ]; then
  expected="$expected rspamd"
else
  absent="$absent rspamd"
fi

for service in $expected; do
  printf '%s\n' "$active" | grep -qx "$service"
  test "$(s6-svstat -o up,wantedup "/run/service/$service")" = "true true"
done

for service in $absent; do
  if printf '%s\n' "$active" | grep -qx "$service"; then
    echo "Unexpected active service: $service" >&2
    exit 1
  fi
done

curl -fsS -o /dev/null http://127.0.0.1:8000/login
postfix status
