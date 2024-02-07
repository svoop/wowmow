#!/usr/bin/env bash
set -euo pipefail

echo "--> Environment"
echo "PROXY_AUTH_USERNAME: ${PROXY_AUTH_USERNAME}"
echo "PROXY_AUTH_PASSWORD: ${PROXY_AUTH_PASSWORD:+(hidden)}"

echo "--> Starting reverse proxy"
ruby lib/reverse_proxy.rb
