#!/bin/bash
# universal_binlog_search.sh - Universal binlog search for ANY table

LOG_FILE="$1"
TABLE_NAME="$2"
SEARCH_TYPE="$3"
shift 3
SEARCH_PARAMS=("$@")

show_usage() {
  cat << 'USAGE'
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Universal Binlog Search Tool
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Usage: ./universal_binlog_search.sh <logfile> <table> <search_type> [params...]

SEARCH TYPES:

1) Search by field position:
   ./universal_binlog_search.sh audit.log order_numerics field 1 195457
   (finds records where @1=195457)

2) Search by field name (requires structure file):
   ./universal_binlog_search.sh audit.log order_numerics name id 195457
   (finds records where id=195457)

3) Search by multiple fields (AND condition):
   ./universal_binlog_search.sh audit.log order_numerics multi 1:195457 2:179700
   (finds records where @1=195457 AND @2=179700)

4) Search by range:
   ./universal_binlog_search.sh audit.log order_numerics range 2 100000 200000
   (finds records where @2 between 100000 and 200000)

5) List all changes:
   ./universal_binlog_search.sh audit.log order_numerics all

6) Show structure (extract fields from first record):
   ./universal_binlog_search.sh audit.log order_numerics structure

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

EXAMPLES:

# Find order by id
./universal_binlog_search.sh audit.log gameshopLsis_order_numerics field 1 195457

# Find orders with discount > 5000
./universal_binlog_search.sh audit.log gameshopLsis_order_numerics range 3 5000 999999

# Find orders with specific subtotal AND discount
./universal_binlog_search.sh audit.log gameshopLsis_order_numerics multi 2:179700 3:0

# Show all changes to users table
./universal_binlog_search.sh audit.log users all

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
USAGE
  exit 1
}

if [[ -z "$LOG_FILE" ]] || [[ -z "$TABLE_NAME" ]] || [[ -z "$SEARCH_TYPE" ]]; then
  show_usage
fi

if [[ ! -f "$LOG_FILE" ]]; then
  echo "❌ Log file not found: $LOG_FILE"
  exit 1
fi

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Escape table name for regex
TABLE_REGEX=$(echo "$TABLE_NAME" | sed 's/\./\\./g')

echo -e "${BLUE}🔍 Searching in table: ${YELLOW}$TABLE_NAME${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

case "$SEARCH_TYPE" in

  structure)
    echo "📊 Extracting table structure from first record..."
    echo ""
    
    awk -v table="$TABLE_REGEX" '
    BEGIN { found = 0; field_count = 0; }
    
    $0 ~ table {
      if ($0 ~ /INSERT INTO|UPDATE|DELETE FROM/) {
        found = 1;
      }
    }
    
    found && /###   @[0-9]+=/ {
      match($0, /@([0-9]+)=([^ ]+)/, arr);
      field_num = arr[1];
      field_value = arr[2];
      
      # Determine type
      if (field_value == "NULL") {
        type = "NULL";
      } else if (field_value ~ /^[0-9]+$/) {
        type = "INT";
      } else {
        type = "STRING";
      }
      
      print "@" field_num " - Type: " type " - Example: " field_value;
      field_count++;
    }
    
    found && /^# at [0-9]+$/ {
      print "\nTotal fields: " field_count;
      exit;
    }
    ' "$LOG_FILE"
    ;;

  field)
    FIELD_NUM="${SEARCH_PARAMS[0]}"
    FIELD_VALUE="${SEARCH_PARAMS[1]}"
    
    if [[ -z "$FIELD_NUM" ]] || [[ -z "$FIELD_VALUE" ]]; then
      echo "❌ Usage: field <field_number> <value>"
      echo "Example: field 1 195457"
      exit 1
    fi
    
    echo -e "Searching for: ${GREEN}@${FIELD_NUM}=${FIELD_VALUE}${NC}"
    echo ""
    
    awk -v table="$TABLE_REGEX" -v field="$FIELD_NUM" -v value="$FIELD_VALUE" '
    BEGIN { 
      in_record = 0;
      buffer = "";
      found = 0;
      match_count = 0;
    }

    /^#[0-9]{6}/ {
      timestamp = $0;
    }

    $0 ~ table {
      if ($0 ~ /INSERT INTO|UPDATE|DELETE FROM/) {
        operation = $0;
        in_record = 1;
        buffer = timestamp "\n" operation "\n";
        found = 0;
      }
    }

    in_record {
      buffer = buffer $0 "\n";
      
      pattern = "###   @" field "=";
      if ($0 ~ pattern) {
        match($0, /@[0-9]+=([^ ]+)/, arr);
        if (arr[1] == value) {
          found = 1;
        }
      }
      
      if (/^# at [0-9]+$/) {
        if (found) {
          print buffer;
          print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n";
          match_count++;
        }
        in_record = 0;
        found = 0;
        buffer = "";
      }
    }
    
    END {
      print "\n✅ Found " match_count " matching records";
    }
    ' "$LOG_FILE"
    ;;

  multi)
    echo "Searching with multiple conditions (AND):"
    for param in "${SEARCH_PARAMS[@]}"; do
      IFS=':' read -r field value <<< "$param"
      echo -e "  ${GREEN}@${field}=${value}${NC}"
    done
    echo ""
    
    # Build awk script dynamically
    CONDITIONS=""
    for param in "${SEARCH_PARAMS[@]}"; do
      IFS=':' read -r field value <<< "$param"
      CONDITIONS="${CONDITIONS}field${field}==\"${value}\" && "
    done
    CONDITIONS="${CONDITIONS%&& }"  # Remove trailing &&
    
    awk -v table="$TABLE_REGEX" -v conditions="$CONDITIONS" '
    BEGIN { 
      in_record = 0;
      buffer = "";
      match_count = 0;
    }

    /^#[0-9]{6}/ {
      timestamp = $0;
    }

    $0 ~ table {
      if ($0 ~ /INSERT INTO|UPDATE|DELETE FROM/) {
        operation = $0;
        in_record = 1;
        buffer = timestamp "\n" operation "\n";
        delete fields;
      }
    }

    in_record {
      buffer = buffer $0 "\n";
      
      if (/###   @[0-9]+=/) {
        match($0, /@([0-9]+)=([^ ]+)/, arr);
        fields[arr[1]] = arr[2];
      }
      
      if (/^# at [0-9]+$/) {
        # Check all conditions
        all_match = 1;
        '"$(
          for param in "${SEARCH_PARAMS[@]}"; do
            IFS=':' read -r field value <<< "$param"
            echo "if (fields[$field] != \"$value\") all_match = 0;"
          done
        )"'
        
        if (all_match) {
          print buffer;
          print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n";
          match_count++;
        }
        in_record = 0;
        buffer = "";
      }
    }
    
    END {
      print "\n✅ Found " match_count " matching records";
    }
    ' "$LOG_FILE"
    ;;

  range)
    FIELD_NUM="${SEARCH_PARAMS[0]}"
    MIN_VALUE="${SEARCH_PARAMS[1]}"
    MAX_VALUE="${SEARCH_PARAMS[2]}"
    
    if [[ -z "$FIELD_NUM" ]] || [[ -z "$MIN_VALUE" ]] || [[ -z "$MAX_VALUE" ]]; then
      echo "❌ Usage: range <field_number> <min_value> <max_value>"
      echo "Example: range 2 100000 200000"
      exit 1
    fi
    
    echo -e "Searching for: ${GREEN}@${FIELD_NUM}${NC} between ${YELLOW}${MIN_VALUE}${NC} and ${YELLOW}${MAX_VALUE}${NC}"
    echo ""
    
    awk -v table="$TABLE_REGEX" -v field="$FIELD_NUM" -v min="$MIN_VALUE" -v max="$MAX_VALUE" '
    BEGIN { 
      in_record = 0;
      buffer = "";
      found = 0;
      match_count = 0;
    }

    /^#[0-9]{6}/ {
      timestamp = $0;
    }

    $0 ~ table {
      if ($0 ~ /INSERT INTO|UPDATE|DELETE FROM/) {
        operation = $0;
        in_record = 1;
        buffer = timestamp "\n" operation "\n";
        found = 0;
      }
    }

    in_record {
      buffer = buffer $0 "\n";
      
      pattern = "###   @" field "=";
      if ($0 ~ pattern) {
        match($0, /@[0-9]+=([0-9]+)/, arr);
        val = arr[1] + 0;
        if (val >= min && val <= max) {
          found = 1;
        }
      }
      
      if (/^# at [0-9]+$/) {
        if (found) {
          print buffer;
          print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n";
          match_count++;
        }
        in_record = 0;
        found = 0;
        buffer = "";
      }
    }
    
    END {
      print "\n✅ Found " match_count " matching records";
    }
    ' "$LOG_FILE"
    ;;

  all)
    echo "Listing all changes..."
    echo ""
    
    awk -v table="$TABLE_REGEX" '
    BEGIN { 
      in_record = 0;
      buffer = "";
      count = 0;
    }

    /^#[0-9]{6}/ {
      timestamp = $0;
    }

    $0 ~ table {
      if ($0 ~ /INSERT INTO|UPDATE|DELETE FROM/) {
        operation = $0;
        in_record = 1;
        buffer = timestamp "\n" operation "\n";
      }
    }

    in_record {
      buffer = buffer $0 "\n";
      
      if (/^# at [0-9]+$/) {
        print buffer;
        print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n";
        count++;
        in_record = 0;
        buffer = "";
      }
    }
    
    END {
      print "\n✅ Total records: " count;
    }
    ' "$LOG_FILE"
    ;;

  *)
    echo "❌ Unknown search type: $SEARCH_TYPE"
    show_usage
    ;;
esac

