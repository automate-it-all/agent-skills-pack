#!/usr/bin/env bash
# Follows the reference guard script in a fresh container, stubs ping/curl/ip.
#
# Drives fail/recover/reboot ticks and asserts the four-state machine.
set -uo pipefail
skill_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/paid/skills/wan-failover-uplink-guard"

docker run --rm \
  -v "$skill_dir/references:/refs:ro" \
  debian:12-slim bash -c '
    set -e
    mkdir -p /stub /work
    control=/work/control.log

    cat > /stub/ping <<"EOF"
#!/bin/bash
for a in "$@"; do [ "$prev" = -I ] && iface="$a"; prev="$a"; done
[ "$(cat /work/health_$iface 2>/dev/null)" = up ]
EOF
    cat > /stub/curl <<"EOF"
#!/bin/bash
for a in "$@"; do [ "$prev" = --interface ] && iface="$a"; prev="$a"; done
# A probe call names --interface; a notify call does not and always succeeds,
# standing in for a reachable local webhook.
[ -z "${iface:-}" ] && exit 0
[ "$(cat /work/health_$iface 2>/dev/null)" = up ]
EOF
    cat > /stub/ip <<"EOF"
#!/bin/bash
case "$*" in
  *"route show"*) [ -f /work/override ] && cat /work/override ;;
  *"route replace"*"via "*"dev "*"metric "*)
    gw=""; dev=""; metric=""
    for i in "$@"; do
      case "$prev" in via) gw="$i" ;; dev) dev="$i" ;; metric) metric="$i" ;; esac
      prev="$i"
    done
    echo "default via $gw dev $dev metric $metric" > /work/override ;;
  *"route del"*) rm -f /work/override ;;
esac
exit 0
EOF
    cat > /stub/logger <<"EOF"
#!/bin/bash
exit 0
EOF
    chmod +x /stub/*
    export PATH=/stub:$PATH

    export WIRED_IF=eth0 BACKUP_IF=wlan0 BACKUP_GW=10.0.0.1 METRIC=50
    export FAIL_THRESHOLD=3 OK_THRESHOLD=2 STRANDED_THRESHOLD=2
    export PROBES=1.1.1.1
    export NOTIFY_URL=http://127.0.0.1:1/notify
    export UPLINK_GUARD_STATE_DIR=/work/state UPLINK_GUARD_SPOOL_DIR=/work/spool
    export UPLINK_GUARD_SYSFS_NET=/work/sysfs
    g="bash /refs/uplink-guard.sh.example"

    mkdir -p /work/sysfs/wlan0
    echo down > /work/sysfs/wlan0/operstate

    echo up > /work/health_eth0
    $g check >/dev/null
    [ "$($g status | grep -o "^state: [a-z]*" | cut -d" " -f2)" = wired ]

    echo down > /work/health_eth0
    echo down > /work/health_wlan0
    for i in 1 2 3; do $g check >/dev/null; done
    st=$($g status | grep -o "^state: [a-z]*" | cut -d" " -f2)
    [ "$st" = unknown ] || { echo "FAIL: expected unknown with backup unusable, got $st"; exit 1; }
    for i in 1 2; do $g check >/dev/null; done
    st=$($g status | grep -o "^state: [a-z]*" | cut -d" " -f2)
    [ "$st" = stranded ] || { echo "FAIL: expected stranded after STRANDED_THRESHOLD ticks, got $st"; exit 1; }

    echo up > /work/health_wlan0
    echo up > /work/sysfs/wlan0/operstate
    $g check >/dev/null
    grep -q "^default via 10.0.0.1 dev wlan0 metric 50" /work/override \
      || { echo "FAIL: expected override route once backup became usable"; exit 1; }
    [ "$($g status | grep -o "^state: [a-z]*" | cut -d" " -f2)" = backup ]

    echo up > /work/health_eth0
    for i in 1 2; do $g check >/dev/null; done
    [ ! -f /work/override ] || { echo "FAIL: expected failback once OK_THRESHOLD reached"; exit 1; }
    [ "$($g status | grep -o "^state: [a-z]*" | cut -d" " -f2)" = wired ]

    echo down > /work/health_eth0
    echo down > /work/health_wlan0
    echo down > /work/sysfs/wlan0/operstate
    rm -rf /work/state
    $g check >/dev/null
    st=$($g status | grep -o "^state: [a-z]*" | cut -d" " -f2)
    [ "$st" = unknown ] || { echo "FAIL: reboot with WAN still dead must read unknown, not a false wired/backup, got $st"; exit 1; }

    echo "OK: wan-failover-uplink-guard state machine"
  '
