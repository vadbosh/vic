#!/bin/bash
# binlog_info.sh

RDS_HOST="${1}"
RDS_USER="${2}"
RDS_PASS="${3}"

if [[ -z "$RDS_HOST" ]] || [[ -z "$RDS_USER" ]] || [[ -z "$RDS_PASS" ]]; then
  echo "Usage: $0 <host> <user> <password>"
  exit 1
fi

# Export password as an environment variable to suppress the warning
# "Using a password on the command line interface can be insecure"
export MYSQL_PWD="${RDS_PASS}"

echo "📋 Available Binary Logs:"
echo ""

# Fetch binary logs list (removed -p flag)
binlogs=($(mysql -h "$RDS_HOST" -u "$RDS_USER" -s -N -e "SHOW BINARY LOGS;" | awk '{print $1}'))

for i in "${!binlogs[@]}"; do
  printf "%2d) %s\n" $((i + 1)) "${binlogs[$i]}"
done

echo ""
read -p "Select binlog number (or 'all' for all): " selection

if [[ "$selection" == "all" ]]; then
  echo ""
  echo "Getting dates for all binlogs..."
  echo ""

  for binlog in "${binlogs[@]}"; do
    # Removed --password flag
    start=$(mysqlbinlog \
      --read-from-remote-server \
      --host="$RDS_HOST" \
      --user="$RDS_USER" \
      --start-position=4 \
      --stop-position=2000 \
      "$binlog" 2>/dev/null |
      grep -m 1 "^#[0-9]" |
      awk '{print $1 " " $2}' |
      sed 's/#//')

    printf "%-35s Start: %s\n" "$binlog" "$start"
  done
else
  binlog="${binlogs[$((selection - 1))]}"

  if [[ -z "$binlog" ]]; then
    echo "Invalid selection"
    # Unset password before exiting on error
    unset MYSQL_PWD
    exit 1
  fi

  echo ""
  echo "📅 Binlog: $binlog"
  echo ""

  echo -n "⏰ Start time: "
  # Removed --password flag
  mysqlbinlog \
    --read-from-remote-server \
    --host="$RDS_HOST" \
    --user="$RDS_USER" \
    --start-position=4 \
    --stop-position=2000 \
    "$binlog" 2>/dev/null |
    grep -m 1 "^#[0-9]" |
    awk '{print $1 " " $2}' |
    sed 's/#//'

  echo -n "⏰ End time:   "
  # Removed --password flag
  mysqlbinlog \
    --read-from-remote-server \
    --host="$RDS_HOST" \
    --user="$RDS_USER" \
    "$binlog" 2>/dev/null |
    grep "^#[0-9]" |
    tail -1 |
    awk '{print $1 " " $2}' |
    sed 's/#//'
fi

# Unset the variable for security reasons
unset MYSQL_PWD
