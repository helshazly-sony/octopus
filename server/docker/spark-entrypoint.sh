#!/bin/bash

SPARK_TYPE=$1

echo "Starting $SPARK_TYPE"

if [ "$SPARK_TYPE" == "master" ]; then
	start-master.sh
	start-history-server.sh

	#echo -e "Host github.com\n\tIdentityFile /opt/octopus_key/id_rsa" >>$OCTOPUS_USER_HOME/.ssh/config
	#ssh-keyscan github.com >>$OCTOPUS_USER_HOME/.ssh/known_hosts
	#git clone git@github.com:helshazly-sony/octopus.git $OCTOPUS_HOME
	#cd $OCTOPUS_HOME/server/
	#./build.sh -s
	#cd $OCTOPUS_HOME/server/job-dispatcher/
	#poetry install

	start_job_dispatcher.sh
elif [ "$SPARK_TYPE" == "worker" ]; then
	service ssh start
	start-worker.sh spark://job-dispatcher-container:7077
fi

tail -f /opt/spark/logs/*
