#!/bin/bash

# Define the port
PORT=8000

# Find the PID of the process listening on the specified port
PID=$(lsof -t -i:$PORT)

# Check if a process is found
if [ -n "$PID" ]; then
  # Terminate the process
  kill -9 $PID
  echo "Job dispatcher server process (PID $PID) terminated."
else
  echo "No process found listening on port $PORT."
fi

