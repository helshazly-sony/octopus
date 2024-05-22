#!/bin/bash

# Use the provided port number or the default port if not provided
PORT_NUM=${1:-8888}

# Get the process ID listening on the specified port
PID=$(lsof -ti :$PORT_NUM)

# Check if the process ID exists
if [ -z "$PID" ]; then
    echo "No process found listening on port $PORT_NUM"
else
    # Kill the process
    kill -9 $PID
    echo "Process with ID $PID listening on port $PORT_NUM killed"
fi

