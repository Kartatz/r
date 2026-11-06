#!/usr/bin/env bash
set -euo pipefail
BASE=/etc/wgcf-socks/wgcf
WG_CONF=/etc/wireguard/wgcf.conf
WGCF=${WGCF_BIN:-/usr/local/bin/wgcf}

cd "$BASE"

if [ ! -e wgcf-account.toml ]; then
  "$WGCF" register --accept-tos
fi

if [ -e custom-wgcf-license.conf ]; then
  _license_key=$(cat custom-wgcf-license.conf)
  _old_license_key=$(awk -F "['']" '/license_key/{print $2}' wgcf-account.toml)
  if [ "$_license_key" != "$_old_license_key" ]; then
    echo 'updating license key'
    sed -i "s/license_key.*$/license_key = '${_license_key}'/" wgcf-account.toml
    "$WGCF" update
  fi
fi

if [ ! -e wgcf-profile.conf ]; then
  "$WGCF" generate
else
  _account_file_private_key=$(awk -F "['']" '/private_key/{print $2}' wgcf-account.toml)
  _profile_file_private_key=$(awk -F " = " '/PrivateKey/{print $2}' wgcf-profile.conf)
  if [ "$_account_file_private_key" != "$_profile_file_private_key" ]; then
    echo 're generate profile'
    "$WGCF" generate
  fi
fi

if [ -e custom-wgcf-endpoint.conf ]; then
  _endpoint=$(cat custom-wgcf-endpoint.conf)
  sed -i "s/Endpoint.*$/Endpoint = ${_endpoint}/" wgcf-profile.conf
fi

install -m 600 wgcf-profile.conf "$WG_CONF"
sed -i '/^[Dd][Nn][Ss] *=/d' "$WG_CONF"
