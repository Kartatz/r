#!/usr/bin/env bash
set -euo pipefail
NS_IP=10.200.0.2
PORT=${PORT:-1080}

socat "TCP-LISTEN:${PORT},bind=127.0.0.1,fork,reuseaddr" "TCP:${NS_IP}:${PORT}" &
A=$!
socat "TCP6-LISTEN:${PORT},bind=[::1],fork,reuseaddr" "TCP:${NS_IP}:${PORT}" &
B=$!
trap 'kill $A $B 2>/dev/null || true' EXIT
wait -n
exit 1
