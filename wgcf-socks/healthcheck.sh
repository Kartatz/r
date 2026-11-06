#!/usr/bin/env bash
if ! ip netns exec wgcf curl -fs --max-time 5 https://www.cloudflare.com/cdn-cgi/trace | grep -qE 'warp=(on|plus)'; then
  systemctl try-restart wgcf-warp.service wgcf-socks5.service
fi
