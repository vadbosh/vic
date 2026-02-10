#!/bin/bash
# Supervisord Event Listener to monitor dnsmasq critical errors
# If dnsmasq exits (EXITED/FATAL), this script will kill supervisord,
# which will stop the entire container and alert Kubernetes to the problem.

echo "[Event Listener] Starting up..." >&2
printf 'READY\n'

# Infinite loop to read events
while read line; do
	# Output received event to log for debugging
	echo "[Event Listener] Received: $line" >&2

	# CHECK - Is this an EXITED or FATAL event?
	if echo "$line" | grep -qE 'PROCESS_STATE_EXITED|PROCESS_STATE_FATAL'; then
		echo "[Event Listener] MATCHED: EXITED or FATAL event detected!" >&2

		# IMPORTANT - SKIP only if this is fatal_handler's OWN RESULT message
		# This will NOT be dnsmasq events!
		if echo "$line" | grep -q 'pool:fatal_handler.*RESULT 2'; then
			echo "[Event Listener] SKIPPING: This is fatal_handler's own RESULT message" >&2
		else
			echo "[Event Listener] ACTION: Process EXITED/FATAL detected! Killing supervisord to stop container..." >&2

			# Kill supervisord (PID 1) in Docker container
			# This stops the entire container
			# Try multiple methods
			kill -TERM 1 2>/dev/null || true
			sleep 1
			# If still alive, force kill
			kill -KILL 1 2>/dev/null || true
			exit 0
		fi
	else
		echo "[Event Listener] SKIPPING: Not an EXITED/FATAL event" >&2
	fi

	# Send acknowledgment to supervisord (proper protocol)
	printf 'RESULT 2\nOK'

	# Signal ready for next event
	printf 'READY\n'
done
