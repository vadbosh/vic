#!/bin/bash

# Check if at least 4 arguments are passed (Host, User, Pass + at least 1 file)
if [ "$#" -lt 4 ]; then
  echo "Usage: $0 <host> <user> <password> <binlog_file_1> [binlog_file_2 ...]"
  exit 1
fi

RDS_HOST="${1}"
RDS_USER="${2}"
RDS_PASS="${3}"

# Export password as an environment variable to suppress the warning
# "Using a password on the command line interface can be insecure"
export MYSQL_PWD="${RDS_PASS}"

# Shift arguments by 3 positions, so $@ now contains only the file list
shift 3

# Generate directory name with current date and time
CURRENT_DATE=$(date +"%Y-%m-%d_%H-%M-%S")
OUTPUT_DIR="binlogs_${CURRENT_DATE}"

# Create the output directory
mkdir -p "$OUTPUT_DIR"
echo "Output directory created: $OUTPUT_DIR"

# Loop through all remaining arguments (binlog filenames)
for BINLOG_FILE in "$@"; do
  echo "Downloading and processing: $BINLOG_FILE ..."

  # Define output file path inside the new directory
  OUTPUT_FILE="${OUTPUT_DIR}/${BINLOG_FILE}.log"

  # Note: The --password flag is removed here because we use MYSQL_PWD above
  mysqlbinlog \
    --read-from-remote-server \
    --host="$RDS_HOST" \
    --port=3306 \
    --user="$RDS_USER" \
    -vv \
    --base64-output=DECODE-ROWS \
    "$BINLOG_FILE" >"$OUTPUT_FILE"

  # Check if the command was successful
  if [ $? -eq 0 ]; then
    echo "  -> Successfully saved to: $OUTPUT_FILE"
  else
    echo "  -> Error downloading $BINLOG_FILE"
  fi
done

# Unset the variable for security reasons after the script is done (optional but good practice)
unset MYSQL_PWD

echo "All tasks completed."
