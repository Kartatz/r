#!/usr/bin/env bash
set -euo pipefail

NS=wgcf
HOST_VIF=v-wgcf-h
NS_VIF=v-wgcf
HOST_IP=10.200.0.1
NS_IP=10.200.0.2
SUBNET=10.200.0.0/24
WAN=${WAN_IF:-eth0}

case "${1:-up}" in
  up)
    if ! ip netns list | awk '{print $1}' | grep -qx "$NS"; then
      ip netns add "$NS"
      ip netns exec "$NS" sysctl -qw net.ipv6.conf.all.disable_ipv6=0 net.ipv6.conf.default.disable_ipv6=0
    fi
    if ! ip link show "$HOST_VIF" >/dev/null 2>&1; then
      ip link add "$HOST_VIF" type veth peer name "$NS_VIF"
      ip link set "$NS_VIF" netns "$NS"
    fi
    ip link set "$HOST_VIF" up
    ip addr replace "$HOST_IP/24" dev "$HOST_VIF"
    ip -n "$NS" link set "$NS_VIF" up
    ip -n "$NS" addr replace "$NS_IP/24" dev "$NS_VIF"
    ip -n "$NS" link set lo up
    ip -n "$NS" route replace default via "$HOST_IP"
    sysctl -qw net.ipv4.ip_forward=1
    iptables -t nat -C POSTROUTING -s "$SUBNET" -o "$WAN" -j MASQUERADE 2>/dev/null ||
      iptables -t nat -A POSTROUTING -s "$SUBNET" -o "$WAN" -j MASQUERADE
    iptables -C FORWARD -i "$HOST_VIF" -o "$WAN" -j ACCEPT 2>/dev/null ||
      iptables -A FORWARD -i "$HOST_VIF" -o "$WAN" -j ACCEPT
    iptables -C FORWARD -i "$WAN" -o "$HOST_VIF" -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT 2>/dev/null ||
      iptables -A FORWARD -i "$WAN" -o "$HOST_VIF" -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
    ;;
  down)
    ip netns del "$NS" 2>/dev/null || true
    ip link del "$HOST_VIF" 2>/dev/null || true
    iptables -t nat -D POSTROUTING -s "$SUBNET" -o "$WAN" -j MASQUERADE 2>/dev/null || true
    iptables -D FORWARD -i "$HOST_VIF" -o "$WAN" -j ACCEPT 2>/dev/null || true
    iptables -D FORWARD -i "$WAN" -o "$HOST_VIF" -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT 2>/dev/null || true
    ;;
  *)
    echo "usage: $0 {up|down}" >&2
    exit 2
    ;;
esac
