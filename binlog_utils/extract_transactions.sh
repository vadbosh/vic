#!/bin/bash
# extract_transactions.sh - Extract complete transactions from binlog

LOG_FILE="$1"
FILTER_TABLE="$2"

if [[ -z "$LOG_FILE" ]]; then
  echo "Usage: $0 <logfile> [table_name]"
  echo "Example: $0 audit.log"
  echo "Example: $0 audit.log order_numerics"
  exit 1
fi

echo "📦 Extracting TRANSACTIONS from $LOG_FILE"
if [[ -n "$FILTER_TABLE" ]]; then
  echo "🔍 Filter: transactions affecting table '$FILTER_TABLE'"
fi
echo ""

awk -v filter="$FILTER_TABLE" '
BEGIN { 
  in_transaction = 0;
  transaction_buffer = "";
  timestamp = "";
  transaction_count = 0;
  filtered_count = 0;
  operation_count = 0;
  has_filter_match = 0;
}

# Timestamp
/^#[0-9]{6}\s+[0-9]+:[0-9]+:[0-9]+/ {
  timestamp = $1 " " $2;
  gsub(/#/, "", timestamp);
}

# BEGIN - Start of transaction
/^BEGIN/ {
  in_transaction = 1;
  transaction_buffer = "";
  operation_count = 0;
  has_filter_match = 0;
  transaction_start_time = timestamp;
  next;
}

# Collect all lines while in transaction
in_transaction {
  transaction_buffer = transaction_buffer $0 "\n";
  
  # Count operations
  if (/### (INSERT INTO|UPDATE|DELETE FROM)/) {
    operation_count++;
    
    # Check if matches filter
    if (filter == "" || $0 ~ filter) {
      has_filter_match = 1;
    }
  }
}

# COMMIT - End of transaction
in_transaction && /^COMMIT/ {
  transaction_count++;
  
  # Apply filter if needed
  if (filter == "" || has_filter_match) {
    filtered_count++;
    
    print "\n╔═══════════════════════════════════════════════════════════════╗";
    print "║ TRANSACTION #" filtered_count " at " transaction_start_time;
    print "║ Operations: " operation_count;
    print "╚═══════════════════════════════════════════════════════════════╝";
    print "";
    print transaction_buffer;
    print "✓ COMMIT";
    print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━";
  }
  
  in_transaction = 0;
  transaction_buffer = "";
  next;
}

# ROLLBACK - Transaction rollback
in_transaction && /^ROLLBACK/ {
  transaction_count++;
  
  if (filter == "" || has_filter_match) {
    filtered_count++;
    
    print "\n╔═══════════════════════════════════════════════════════════════╗";
    print "║ TRANSACTION #" filtered_count " at " transaction_start_time " [ROLLBACK]";
    print "║ Operations: " operation_count;
    print "╚═══════════════════════════════════════════════════════════════╝";
    print "";
    print transaction_buffer;
    print "✗ ROLLBACK";
    print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━";
  }
  
  in_transaction = 0;
  transaction_buffer = "";
  next;
}

END {
  print "\n╔═══════════════════════════════════════════════════════════════╗";
  print "║ SUMMARY";
  print "╠═══════════════════════════════════════════════════════════════╣";
  print "║ Total transactions in log: " transaction_count;
  if (filter != "") {
    print "║ Matching filter: " filtered_count;
  }
  print "╚═══════════════════════════════════════════════════════════════╝";
}
' "$LOG_FILE"
