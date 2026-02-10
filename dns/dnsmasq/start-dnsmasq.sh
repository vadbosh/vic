#!/bin/bash
set -e

UPSTREAM_FILE="/etc/resolv.dnsmasq"
SYSTEM_RESOLV="/etc/resolv.conf"
BACKUP_RESOLV="/etc/resolv.conf.original"

# Flag to track if critical_error_exit was called
CRITICAL_ERROR_DETECTED=0

# Function to handle critical errors and stop the container
critical_error_exit() {
  local error_message="$1"

  # Set flag to prevent double-handling
  CRITICAL_ERROR_DETECTED=1

  echo ""
  echo "=========================================="
  echo "CRITICAL ERROR - STOPPING CONTAINER"
  echo "=========================================="
  echo "$error_message"
  echo "=========================================="
  echo ""

  # Try to kill supervisord (PID 1) to stop the container immediately
  # This is faster than waiting for supervisord to mark dnsmasq as FATAL
  if [ -f /var/run/supervisord.pid ]; then
    SUPERVISOR_PID=$(cat /var/run/supervisord.pid)
    echo "Sending SIGTERM to supervisord (PID $SUPERVISOR_PID) to stop container..."
    kill -TERM $SUPERVISOR_PID 2>/dev/null || true
  else
    # Fallback: kill PID 1 directly
    echo "Sending SIGTERM to PID 1 (supervisord) to stop container..."
    kill -TERM 1 2>/dev/null || true
  fi

  # Wait a bit for graceful shutdown
  sleep 2

  # Exit with code 1 (set -e won't interfere)
  exit 1
}

# Trap to catch script exit and ensure supervisord is killed
trap 'if [ $CRITICAL_ERROR_DETECTED -eq 1 ]; then exit 1; fi' EXIT
trap 'if [ $CRITICAL_ERROR_DETECTED -eq 1 ]; then exit 1; fi' ERR

echo "======================================="
echo "DNS Configuration Script Starting..."
echo "======================================="

# Function to handle critical errors and stop the container
critical_error_exit() {
  local error_message="$1"

  echo ""
  echo "=========================================="
  echo "CRITICAL ERROR - STOPPING CONTAINER"
  echo "=========================================="
  echo "$error_message"
  echo "=========================================="
  echo ""

  # Try to kill supervisord (PID 1) to stop the container immediately
  # This is faster than waiting for supervisord to mark dnsmasq as FATAL
  if [ -f /var/run/supervisord.pid ]; then
    SUPERVISOR_PID=$(cat /var/run/supervisord.pid)
    echo "Sending SIGTERM to supervisord (PID $SUPERVISOR_PID) to stop container..."
    kill -TERM $SUPERVISOR_PID 2>/dev/null || true
  else
    # Fallback: kill PID 1 directly
    echo "Sending SIGTERM to PID 1 (supervisord) to stop container..."
    kill -TERM 1 2>/dev/null || true
  fi

  # Wait a bit for graceful shutdown
  sleep 2

  # If still running, force exit (supervisord will see this as FATAL)
  exit 1
}

# Function to validate DNS nameserver exists
validate_dns_file() {
  local file="$1"
  if [ ! -f "$file" ]; then
    echo "ERROR: File $file does not exist"
    return 1
  fi
  if ! grep -q "nameserver" "$file"; then
    echo "ERROR: No nameserver found in $file"
    return 1
  fi
  return 0
}

# Function to extract non-localhost nameservers from a file
extract_upstream_dns() {
  local source_file="$1"
  local dest_file="$2"

  if [ ! -f "$source_file" ]; then
    echo "ERROR: Source file $source_file does not exist"
    return 1
  fi

  # Extract nameservers excluding 127.0.0.1 and ::1
  # IMPORTANT: Use temporary file to avoid creating empty dest_file
  local temp_file="/tmp/dns_extract.$$"
  grep "nameserver" "$source_file" | grep -v "127.0.0.1" | grep -v "::1" >"$temp_file" 2>/dev/null || true

  if [ -s "$temp_file" ]; then
    # File has content, move to destination
    mv "$temp_file" "$dest_file"
    return 0
  else
    # No valid nameservers found, cleanup and fail
    rm -f "$temp_file"
    return 1
  fi
}

# Step 1: Create original backup if not exists (CRITICAL for EKS!)
if [ ! -f "$BACKUP_RESOLV" ]; then
  echo "---> Creating original backup of $SYSTEM_RESOLV"

  # IMPORTANT: Only backup if current resolv.conf is valid (not localhost)
  if grep -q "127.0.0.1" "$SYSTEM_RESOLV"; then
    critical_error_exit "Cannot create backup - $SYSTEM_RESOLV already points to 127.0.0.1!
This means Pod restarted but /etc/resolv.conf.original was lost.
In EKS, this breaks Kubernetes DNS resolution.

Current resolv.conf content:
$(cat "$SYSTEM_RESOLV")

SOLUTION: Delete the Pod to get fresh Kubernetes DNS configuration.
Example: kubectl delete pod <pod-name>"
  fi

  cp "$SYSTEM_RESOLV" "$BACKUP_RESOLV"
  echo "---> Backup saved to $BACKUP_RESOLV"
  cat "$BACKUP_RESOLV"
fi

# Step 2: Check current state
if grep -q "127.0.0.1" "$SYSTEM_RESOLV"; then
  echo "---> DETECTED: System DNS already points to 127.0.0.1 (EKS restart scenario)"

  # Check if upstream DNS file exists
  if [ ! -f "$UPSTREAM_FILE" ]; then
    echo "---> WARNING: Upstream DNS file missing! Attempting recovery..."

    # Try to recover from backup (should contain Kubernetes CoreDNS)
    if extract_upstream_dns "$BACKUP_RESOLV" "$UPSTREAM_FILE"; then
      echo "---> Successfully recovered upstream DNS from backup"
    else
      critical_error_exit "Cannot extract valid upstream DNS from backup!

Backup content:
$(cat "$BACKUP_RESOLV")

In EKS, we MUST have Kubernetes DNS (CoreDNS) as upstream.
Cannot proceed without valid upstream DNS configuration.

SOLUTION: Delete the Pod to get fresh Kubernetes DNS.
Example: kubectl delete pod <pod-name>"
    fi
  fi

  echo "---> Using upstream DNS from: $UPSTREAM_FILE"

else
  echo "---> First start detected. Configuring DNS..."

  # Validate current resolv.conf has nameservers
  if ! validate_dns_file "$SYSTEM_RESOLV"; then
    critical_error_exit "Current $SYSTEM_RESOLV has no valid nameservers!

This should never happen on first start in Kubernetes.
Check that the Pod is receiving proper DNS configuration from K8s."
  fi

  # Save upstream DNS (exclude 127.0.0.1 if somehow present)
  # In EKS this should contain CoreDNS IP (e.g., 10.100.0.10)
  if extract_upstream_dns "$SYSTEM_RESOLV" "$UPSTREAM_FILE"; then
    echo "---> Saved upstream DNS to $UPSTREAM_FILE"
  else
    critical_error_exit "Cannot extract upstream DNS from $SYSTEM_RESOLV

Current resolv.conf content:
$(cat "$SYSTEM_RESOLV")

No valid nameservers found (all are localhost).
Check Kubernetes dnsPolicy and DNS configuration."
  fi

  # Create new resolv.conf
  echo "nameserver 127.0.0.1" >/tmp/resolv.conf.new
  grep -E "^search" "$SYSTEM_RESOLV" >>/tmp/resolv.conf.new 2>/dev/null || true
  echo "options ndots:2 timeout:1 attempts:3 single-request" >>/tmp/resolv.conf.new 2>/dev/null || true

  cat /tmp/resolv.conf.new >"$SYSTEM_RESOLV"
  rm /tmp/resolv.conf.new
  echo "---> Updated system $SYSTEM_RESOLV to use local DNS proxy"
fi

# Step 3: Validate upstream DNS configuration
echo "======================================="
echo "Validating DNS configuration..."
if ! validate_dns_file "$UPSTREAM_FILE"; then
  critical_error_exit "Upstream DNS file is invalid!

File: $UPSTREAM_FILE
Cannot start dnsmasq without valid upstream DNS configuration."
fi

echo "---> Current $SYSTEM_RESOLV:"
cat "$SYSTEM_RESOLV" | head -5
echo ""
echo "---> Upstream DNS ($UPSTREAM_FILE) - MUST contain Kubernetes CoreDNS in EKS:"
cat "$UPSTREAM_FILE"
echo "======================================="

# Step 4: Verify upstream DNS is not localhost
if grep -E "127\.0\.0\.1|::1" "$UPSTREAM_FILE" >/dev/null 2>&1; then
  critical_error_exit "Upstream DNS contains localhost addresses!

This will cause DNS loop. In EKS, upstream MUST be CoreDNS (e.g., 10.100.0.10)

Current upstream DNS:
$(cat "$UPSTREAM_FILE")

SOLUTION: Delete the Pod to get fresh Kubernetes DNS configuration."
fi

echo "DNS configuration validated successfully!"
echo "Starting dnsmasq..."
echo "======================================="

# !!! START dnsmasq
exec /usr/sbin/dnsmasq -k --user=root
# !!!
