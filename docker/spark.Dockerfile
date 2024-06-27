FROM bitnami/spark:3.5.1 as spark-master

ARG SPARK_INITSCRIPTS_DIR="/docker-entrypoint-initdb.d"
ARG SPARK_CONF_FILE="${SPARK_HOME}/conf/spark-defaults.conf"
ENV OCTOPUS_HOME="/opt/octopus"

USER root

COPY docker/conf/spark-defaults.conf $SPARK_CONF_FILE

WORKDIR $OCTOPUS_HOME
COPY server ./server

# NOTE: Octopus has the neo4j spark connector in $OCTOPUS_HOME/server/artifcats/
RUN pip3 install -r server/requirements.txt && \
    ./server/build.sh -s && \
    poetry install --directory=server/job-dispatcher

# Copy custom init scripts to $SPARK_INITSCRIPTS_DIR and send to background start-history-server.sh on execution
WORKDIR $SPARK_INITSCRIPTS_DIR
RUN cp $OCTOPUS_HOME/server/job-dispatcher/bin/start-job-dispatcher.sh ./ && \
    sed -e '$ s/$/ \&/' $SPARK_HOME/sbin/start-history-server.sh > ./start-history-server.sh && \
    chmod +x ./start-history-server.sh

    
WORKDIR $OCTOPUS_HOME
USER 1001