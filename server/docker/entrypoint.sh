#!/bin/bash

# Start Spark History Server
#/opt/spark/sbin/start-history-server.sh
#echo $SPARK_HOME
#echo $PATH
start-history-server.sh

# move to dockerfile:
# Build Octopus Server
#cd $OCTOPUS_HOME/server/
#./build.sh -s

# Install server dependencies
#cd job-dispatcher
#poetry install --no-root

# Launch the server
JOB_DISPATCHER_LOG=$(start_job_dispatcher.sh)

# Tail the log of job-dispatcher to keep container alive
tail -f $JOB_DISPATHCER_LOG
