#!/bin/bash

# Define the directory
JOB_DISPATCHER_DIR="$OCTOPUS_HOME/server/job-dispatcher"

# Define the log file with timestamp
LOG_FILE="/tmp/job_dispatcher_$(date +'%Y%m%d%H%M%S').log"

# Navigate to the job dispatcher directory
cd "$JOB_DISPATCHER_DIR" || exit

# Start the job dispatcher server and redirect stdout and stderr to the log file
# Launch the server in the background
poetry run uvicorn src.main:app --host 0.0.0.0 --reload >"$LOG_FILE" 2>&1 &

# Print the log file location
echo "$LOG_FILE"
