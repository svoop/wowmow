#!/usr/bin/env bash
set -euo pipefail

echo "--> Starting reverse proxy"
ruby lib/reverse_proxy.rb
