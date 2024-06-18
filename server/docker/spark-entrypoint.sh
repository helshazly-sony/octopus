#!/bin/bash

SPARK_TYPE=$1

echo "$SPARK_TYPE"

if [ "$SPARK_TYPE" == "master" ]; then
	service ssh start
	start-master.sh
	start-history-server.sh
elif [ "$SPARK_TYPE" == "worker" ]; then
	service ssh start
	start-worker.sh spark://job-dispatcher-container:7077
fi

tail -f /opt/spark/logs/*
