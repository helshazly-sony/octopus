#!/bin/bash

SPARK_TYPE=$1

echo "Starting $SPARK_TYPE"

if [ "$SPARK_TYPE" == "master" ]; then
	start-master.sh
	start-history-server.sh
	start-job-dispatcher.sh
elif [ "$SPARK_TYPE" == "worker" ]; then
	/usr/sbin/sshd -f ~/ssh/sshd_config && \
	start-worker.sh spark://job-dispatcher-container:7077
fi

tail -f /opt/spark/logs/*
