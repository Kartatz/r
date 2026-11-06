#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

pacman --sync --refresh --needed --noconfirm wireguard-tools socat go iptables

cp '/usr/bin/wg-quick' '/usr/local/bin/wg-quick-wgcf'

declare -r WGCF_VERSION='2.3.1'
curl --connect-timeout 10 --retry 15 --retry-all-errors --fail --silent --location \
    --url "https://github.com/ViRb3/wgcf/releases/download/v${WGCF_VERSION}/wgcf_${WGCF_VERSION}_linux_amd64" \
    --output /usr/local/bin/wgcf
chmod +x /usr/local/bin/wgcf

rm --recursive --force /tmp/socks5-server
git clone --depth 1 --quiet https://github.com/serjs/socks5-server /tmp/socks5-server
(cd /tmp/socks5-server && go build -mod=vendor -o /usr/local/bin/warp-socks5 .)

chmod +x "${DIR}"/*.sh

mkdir --parents /etc/wgcf-socks/wgcf /etc/netns/wgcf
printf 'nameserver 1.1.1.1\nnameserver 1.0.0.1\n' > /etc/netns/wgcf/resolv.conf

bash "${DIR}/sync.sh"

cat > /etc/systemd/system/wgcf-netns.service <<'EOF'
[Unit]
Description=wgcf-socks network namespace and veth setup
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/opt/wgcf-socks/netns.sh up
ExecStop=/opt/wgcf-socks/netns.sh down

[Install]
WantedBy=multi-user.target
EOF

cat > /etc/systemd/system/wgcf-warp.service <<'EOF'
[Unit]
Description=wgcf-socks Cloudflare WARP WireGuard tunnel (in wgcf netns)
Requires=wgcf-netns.service
After=wgcf-netns.service

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/opt/wgcf-socks/sync.sh
ExecStartPost=/opt/wgcf-socks/warp-up.sh
ExecStop=-/usr/bin/ip netns exec wgcf /usr/local/bin/wg-quick-wgcf down /etc/wireguard/wgcf.conf
TimeoutStartSec=180

[Install]
WantedBy=multi-user.target
EOF

cat > /etc/systemd/system/wgcf-socks5.service <<'EOF'
[Unit]
Description=wgcf-socks SOCKS5 proxy (in wgcf netns)
Requires=wgcf-warp.service
After=wgcf-warp.service

[Service]
ExecStart=/usr/bin/ip netns exec wgcf env PROXY_PORT=1080 REQUIRE_AUTH=false /usr/local/bin/warp-socks5
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

cat > /etc/systemd/system/wgcf-socks5-bridge.service <<'EOF'
[Unit]
Description=wgcf-socks loopback 1080 bridge into wgcf netns
Requires=wgcf-socks5.service
After=wgcf-socks5.service

[Service]
ExecStart=/opt/wgcf-socks/bridge.sh
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

cat > /etc/systemd/system/wgcf-healthcheck.service <<'EOF'
[Unit]
Description=wgcf-socks healthcheck (restart tunnel when warp is off)

[Service]
Type=oneshot
ExecStart=/opt/wgcf-socks/healthcheck.sh
EOF

cat > /etc/systemd/system/wgcf-healthcheck.timer <<'EOF'
[Unit]
Description=wgcf-socks periodic healthcheck

[Timer]
OnBootSec=2min
OnUnitActiveSec=1min

[Install]
WantedBy=timers.target
EOF

systemctl daemon-reload
systemctl enable --now wgcf-socks5-bridge.service wgcf-healthcheck.timer

for attempt in 1 2 3 4 5 6 7 8 9 10; do
    if curl --fail --silent --max-time 5 --proxy socks5h://127.0.0.1:1080 https://www.cloudflare.com/cdn-cgi/trace | grep --quiet --extended-regexp 'warp=(on|plus)'; then
        echo 'WARP SOCKS5 proxy is up on 127.0.0.1:1080'
        exit 0
    fi
    sleep 2
done

echo 'WARP SOCKS5 proxy failed to start' >&2
exit 1
