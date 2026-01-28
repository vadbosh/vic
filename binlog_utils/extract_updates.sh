#!/bin/bash
# extract_updates.sh

LOG_FILE="$1"

echo "Extracting all UPDATEs from $LOG_FILE..."
echo ""

awk '
BEGIN { in_update = 0; }

/^#[0-9]{6}/ {
  timestamp = $1 " " $2;
}

/### UPDATE/ {
  in_update = 1;
  table = $3;
  gsub(/`/, "", table);
  print "\n=== UPDATE at " timestamp " on " table " ===";
  next;
}

/### WHERE/ {
  if (in_update) {
    print "\nOLD VALUES:";
    in_where = 1;
  }
  next;
}

/### SET/ {
  if (in_update) {
    print "\nNEW VALUES:";
    in_where = 0;
  }
  next;
}

/###   @/ {
  if (in_update) {
    print $0;
  }
}

/^# at [0-9]+$/ {
  in_update = 0;
}
' "$LOG_FILE"
