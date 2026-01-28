#!/bin/bash
# extract_inserts.sh - INSERT from all tables

LOG_FILE="$1"

if [[ -z "$LOG_FILE" ]]; then
  echo "Usage: $0 <logfile>"
  echo "Example: $0 audit_changes.log"
  exit 1
fi

echo "📝 Extracting all INSERTs from $LOG_FILE..."
echo ""

awk '
BEGIN { 
  in_insert = 0;
  timestamp = "";
  count = 0;
}

# Timestamp з типовим форматом binlog
/^#[0-9]{6}\s+[0-9]+:[0-9]+:[0-9]+/ {
  # Формат: #260127  9:01:53
  timestamp = $1 " " $2;
  gsub(/#/, "", timestamp);  # Видаляємо #
}

# INSERT INTO
/### INSERT INTO/ {
  in_insert = 1;
  count++;
  
  match($0, /INSERT INTO `([^`]+)`\.`([^`]+)`/, arr);
  if (arr[1] != "") {
    database = arr[1];
    table = arr[2];
  } else {
    # Якщо без БД
    match($0, /INSERT INTO `([^`]+)`/, arr);
    database = "";
    table = arr[1];
  }
  
  print "\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━";
  print "INSERT #" count " at " timestamp;
  if (database != "") {
    print "Table: " database "." table;
  } else {
    print "Table: " table;
  }
  print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━";
  next;
}

# SET (data...)
in_insert && /### SET/ {
  print "\nValues:";
  next;
}

# FIELDS
in_insert && /###   @[0-9]+=/ {
  # Форматуємо вивід
  match($0, /###   @([0-9]+)=(.*)/, arr);
  field_num = arr[1];
  field_value = arr[2];
  
  gsub(/\/\*.*\*\//, "", field_value);
  gsub(/^ +| +$/, "", field_value);  # Trim spaces
  
  printf "  @%-2s = %s\n", field_num, field_value;
}

# END INSERT
in_insert && /^# at [0-9]+$/ {
  in_insert = 0;
}

END {
  print "\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━";
  print "✅ Total INSERTs found: " count;
}
' "$LOG_FILE"

