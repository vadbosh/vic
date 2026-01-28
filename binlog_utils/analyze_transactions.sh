#!/bin/bash
# analyze_transactions.sh - Advanced transaction analysis

LOG_FILE="$1"
MODE="${2:-summary}"  # summary, full, stats

show_usage() {
  cat << 'USAGE'
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Transaction Analysis Tool
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Usage: ./analyze_transactions.sh <logfile> [mode]

MODES:
  summary  - Transaction summary (default)
  full     - Full transaction details
  stats    - Detailed statistics
  tables   - Group by affected tables

EXAMPLES:
  ./analyze_transactions.sh audit.log summary
  ./analyze_transactions.sh audit.log stats
  ./analyze_transactions.sh audit.log tables
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
USAGE
  exit 1
}

if [[ -z "$LOG_FILE" ]]; then
  show_usage
fi

if [[ ! -f "$LOG_FILE" ]]; then
  echo "❌ Log file not found: $LOG_FILE"
  exit 1
fi

case "$MODE" in

  summary)
    echo "📊 Transaction Summary"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    awk '
    BEGIN { 
      in_trans = 0;
      trans_count = 0;
      rollback_count = 0;
      total_ops = 0;
      current_ops = 0;
    }
    
    /^#[0-9]{6}\s+[0-9]+:[0-9]+:[0-9]+/ {
      timestamp = $1 " " $2;
      gsub(/#/, "", timestamp);
    }
    
    /^BEGIN/ {
      in_trans = 1;
      current_ops = 0;
      trans_start = timestamp;
    }
    
    in_trans && /### (INSERT INTO|UPDATE|DELETE FROM)/ {
      current_ops++;
      total_ops++;
    }
    
    /^COMMIT/ {
      trans_count++;
      printf "Transaction #%-4d | Time: %s | Operations: %d\n", trans_count, trans_start, current_ops;
      in_trans = 0;
    }
    
    /^ROLLBACK/ {
      rollback_count++;
      printf "Transaction #%-4d | Time: %s | Operations: %d [ROLLBACK]\n", trans_count + rollback_count, trans_start, current_ops;
      in_trans = 0;
    }
    
    END {
      print "";
      print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━";
      print "Committed: " trans_count;
      print "Rolled back: " rollback_count;
      print "Total operations: " total_ops;
      if (trans_count > 0) {
        printf "Avg operations per transaction: %.2f\n", total_ops / trans_count;
      }
    }
    ' "$LOG_FILE"
    ;;

  stats)
    echo "📈 Detailed Transaction Statistics"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    awk '
    BEGIN { 
      in_trans = 0;
      trans_count = 0;
      rollback_count = 0;
      
      inserts = 0;
      updates = 0;
      deletes = 0;
      
      current_inserts = 0;
      current_updates = 0;
      current_deletes = 0;
      
      max_ops = 0;
      min_ops = 999999;
    }
    
    /^BEGIN/ {
      in_trans = 1;
      current_inserts = 0;
      current_updates = 0;
      current_deletes = 0;
    }
    
    in_trans && /### INSERT INTO/ {
      current_inserts++;
      inserts++;
    }
    
    in_trans && /### UPDATE/ {
      current_updates++;
      updates++;
    }
    
    in_trans && /### DELETE FROM/ {
      current_deletes++;
      deletes++;
    }
    
    /^COMMIT/ {
      trans_count++;
      ops = current_inserts + current_updates + current_deletes;
      if (ops > max_ops) max_ops = ops;
      if (ops < min_ops) min_ops = ops;
      in_trans = 0;
    }
    
    /^ROLLBACK/ {
      rollback_count++;
      in_trans = 0;
    }
    
    END {
      total_ops = inserts + updates + deletes;
      
      print "Transactions:";
      print "  Committed: " trans_count;
      print "  Rolled back: " rollback_count;
      print "  Total: " (trans_count + rollback_count);
      print "";
      print "Operations:";
      print "  INSERTs: " inserts " (" (total_ops > 0 ? int(inserts*100/total_ops) : 0) "%)";
      print "  UPDATEs: " updates " (" (total_ops > 0 ? int(updates*100/total_ops) : 0) "%)";
      print "  DELETEs: " deletes " (" (total_ops > 0 ? int(deletes*100/total_ops) : 0) "%)";
      print "  Total: " total_ops;
      print "";
      print "Per Transaction:";
      if (trans_count > 0) {
        printf "  Average: %.2f operations\n", total_ops / trans_count;
        print "  Maximum: " max_ops " operations";
        if (min_ops < 999999) {
          print "  Minimum: " min_ops " operations";
        }
      }
    }
    ' "$LOG_FILE"
    ;;

  tables)
    echo "📋 Transactions Grouped by Affected Tables"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    awk '
    BEGIN { 
      in_trans = 0;
      trans_count = 0;
    }
    
    /^BEGIN/ {
      in_trans = 1;
      delete tables;
      trans_count++;
    }
    
    in_trans && /### (INSERT INTO|UPDATE|DELETE FROM)/ {
      # Extract table name
      if (match($0, /`([^`]+)`\.`([^`]+)`/, arr)) {
        table = arr[1] "." arr[2];
      } else if (match($0, /`([^`]+)`/, arr)) {
        table = arr[1];
      }
      
      if (table != "") {
        tables[table]++;
      }
    }
    
    /^COMMIT/ {
      # Print transaction info
      if (length(tables) > 0) {
        print "Transaction #" trans_count ":";
        for (table in tables) {
          print "  • " table " (" tables[table] " operations)";
        }
        print "";
      }
      in_trans = 0;
    }
    
    /^ROLLBACK/ {
      in_trans = 0;
    }
    ' "$LOG_FILE"
    ;;

  full)
    # Just call the main extract script
    exec bash "$(dirname "$0")/extract_transactions.sh" "$LOG_FILE"
    ;;

  *)
    echo "❌ Unknown mode: $MODE"
    show_usage
    ;;
esac
