#!/bin/bash
# extract_inserts_filtered.sh - INSERT from current table

LOG_FILE="$1"
FILTER_TABLE="$2"

if [[ -z "$LOG_FILE" ]]; then
  echo "Usage: $0 <logfile> [table_name]"
  echo "Example: $0 audit.log"
  echo "Example: $0 audit.log order_numerics"
  exit 1
fi

echo "📝 Extracting INSERTs from $LOG_FILE"
if [[ -n "$FILTER_TABLE" ]]; then
  echo "🔍 Filter: table contains '$FILTER_TABLE'"
fi
echo ""

awk -v filter="$FILTER_TABLE" '
BEGIN { 
  in_insert = 0;
  timestamp = "";
  count = 0;
  filtered_count = 0;
}

/^#[0-9]{6}\s+[0-9]+:[0-9]+:[0-9]+/ {
  timestamp = $1 " " $2;
  gsub(/#/, "", timestamp);
}

/### INSERT INTO/ {
  current_table = $0;
  
  if (filter == "" || current_table ~ filter) {
    in_insert = 1;
    filtered_count++;
    
    match($0, /INSERT INTO `([^`]+)`\.`([^`]+)`/, arr);
    if (arr[1] != "") {
      database = arr[1];
      table = arr[2];
    } else {
      match($0, /INSERT INTO `([^`]+)`/, arr);
      database = "";
      table = arr[1];
    }
    
    print "\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━";
    print "INSERT #" filtered_count " at " timestamp;
    if (database != "") {
      print "Table: " database "." table;
    } else {
      print "Table: " table;
    }
    print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━";
  } else {
    in_insert = 0;
  }
  
  count++;
  next;
}

in_insert && /### SET/ {
  print "\nValues:";
  next;
}

in_insert && /###   @[0-9]+=/ {
  match($0, /###   @([0-9]+)=(.*)/, arr);
  field_num = arr[1];
  field_value = arr[2];
  gsub(/\/\*.*\*\//, "", field_value);
  gsub(/^ +| +$/, "", field_value);
  printf "  @%-2s = %s\n", field_num, field_value;
}

in_insert && /^# at [0-9]+$/ {
  in_insert = 0;
}

END {
  print "\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━";
  print "✅ Total INSERTs in log: " count;
  if (filter != "") {
    print "📊 Matching filter: " filtered_count;
  }
}
' "$LOG_FILE"

