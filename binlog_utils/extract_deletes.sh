#!/bin/bash
# extract_deletes.sh

LOG_FILE="$1"

echo "Extracting all DELETEs from $LOG_FILE..."
echo ""

awk '
BEGIN { in_delete = 0; }

/^#[0-9]{6}/ {
  timestamp = $1 " " $2;
}

/### DELETE FROM/ {
  in_delete = 1;
  table = $4;
  gsub(/`/, "", table);
  print "\n=== DELETE at " timestamp " from " table " ===";
  next;
}

/### WHERE/ {
  if (in_delete) {
    print "\nDELETED VALUES:";
  }
  next;
}

/###   @/ {
  if (in_delete) {
    print $0;
  }
}

/^# at [0-9]+$/ {
  in_delete = 0;
}
' "$LOG_FILE"
