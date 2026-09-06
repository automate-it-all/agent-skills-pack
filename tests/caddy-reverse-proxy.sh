#!/usr/bin/env bash
# Follows caddy-reverse-proxy/SKILL.md steps 1-2 in a fresh container.
# Proves the private-subnet gate blocks, then allows, the proxy.
set -uo pipefail

docker run --rm caddy:latest sh -c '
    set -e
    apk add --no-cache python3 curl >/dev/null

    python3 -m http.server 9000 --directory /tmp &
    echo backend > /tmp/index.html

    cat > /tmp/deny.Caddyfile <<EOF
(private_subnet) {
    @denied not remote_ip 10.0.0.0/8
    abort @denied
}
:8080 {
    import private_subnet
    reverse_proxy 127.0.0.1:9000
}
EOF
    cat > /tmp/allow.Caddyfile <<EOF
(private_subnet) {
    @denied not remote_ip 10.0.0.0/8 127.0.0.1
    abort @denied
}
:8080 {
    import private_subnet
    reverse_proxy 127.0.0.1:9000
}
EOF

    caddy validate --config /tmp/deny.Caddyfile --adapter caddyfile
    caddy validate --config /tmp/allow.Caddyfile --adapter caddyfile

    caddy start --config /tmp/deny.Caddyfile --adapter caddyfile
    sleep 1
    code=$(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:8080/) || code="blocked"
    caddy stop
    test "$code" != "200"
    echo "OK: private_subnet without 127.0.0.1 rejects ($code)"

    caddy start --config /tmp/allow.Caddyfile --adapter caddyfile
    sleep 1
    code=$(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:8080/)
    caddy stop
    test "$code" = "200"
    echo "OK: private_subnet with 127.0.0.1 allow proxies ($code)"
'
