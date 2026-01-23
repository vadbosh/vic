#!/bin/bash
set -e

UPSTREAM_FILE="/etc/resolv.dnsmasq"
SYSTEM_RESOLV="/etc/resolv.conf"

echo "--> Checking DNS configuration..."

if grep -q "127.0.0.1" "$SYSTEM_RESOLV"; then
  echo "--> Detected restart! System DNS is already 127.0.0.1."
  if [ ! -f "$UPSTREAM_FILE" ]; then
    echo "CRITICAL ERROR: Original DNS IP lost. Cannot start."
    exit 1
  fi
  echo "--> Using existing upstream config from $UPSTREAM_FILE"

else
  echo "--> First start. Configuring DNS..."
  grep "nameserver" "$SYSTEM_RESOLV" >"$UPSTREAM_FILE"
  echo "Saved upstream DNS to $UPSTREAM_FILE"
  echo "nameserver 127.0.0.1" >/tmp/resolv.conf.new
  grep -E "^search|^options" "$SYSTEM_RESOLV" >>/tmp/resolv.conf.new
  cat /tmp/resolv.conf.new >"$SYSTEM_RESOLV"
  rm /tmp/resolv.conf.new
  echo "Updated system $SYSTEM_RESOLV to use local proxy."
fi
# !!! START dnsmasq
exec /usr/sbin/dnsmasq -k --user=root
# !!!
