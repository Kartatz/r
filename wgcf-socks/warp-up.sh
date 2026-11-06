#!/usr/bin/env bash
set -euo pipefail
NS=wgcf
WG_CONF=/etc/wireguard/wgcf.conf
WG_QUICK=/usr/local/bin/wg-quick-wgcf
RETRIES=${RETRIES:-10}

probe() {
  ip netns exec "$NS" curl -fs --max-time 5 https://www.cloudflare.com/cdn-cgi/trace |
    grep -qE 'warp=(on|plus)'
}

probe && exit 0

echo "Checking network status, please wait...."
for i in $(seq 1 "$RETRIES"); do
  ip netns exec "$NS" "${WG_QUICK}" down "$WG_CONF" 2>/dev/null || true
  sleep 2
  ip netns exec "$NS" "${WG_QUICK}" up "$WG_CONF"
  if probe; then
    echo "OK, wgcf is up."
    exit 0
  fi
  echo "attempt $i/$RETRIES failed, retrying..."
done
echo "warp tunnel failed after $RETRIES attempts" >&2
exit 1
