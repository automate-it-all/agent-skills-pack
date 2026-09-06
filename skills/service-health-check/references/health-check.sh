#!/usr/bin/env bash
# Checks a service in three layers: process, port, HTTP status. Exits on
# the first failed layer and names which one failed.
set -uo pipefail

service_name="$1"  # process name to match against, e.g. "nginx"
host="$2"           # host to probe, e.g. "127.0.0.1"
port="$3"           # TCP port the service listens on
url="$4"            # HTTP URL to check for a 2xx status

if ! pgrep -f "$service_name" >/dev/null; then
  echo "FAIL: no process matching '$service_name'"
  exit 1
fi

if ! (exec 3<>"/dev/tcp/$host/$port") 2>/dev/null; then
  echo "FAIL: $host:$port refused a connection"
  exit 1
fi
exec 3>&- 3<&- 2>/dev/null

status="$(curl -s -o /dev/null -w '%{http_code}' "$url")"
if [ "$status" -lt 200 ] || [ "$status" -ge 300 ]; then
  echo "FAIL: $url returned HTTP $status"
  exit 1
fi

echo "OK: $service_name up, $host:$port open, $url returned $status"
