# Use the official Neo4j image as the base image
FROM neo4j:latest

# Install additional libraries
# For example, installing curl and vim
RUN apt-get update && apt-get install -y \
    curl \
    vim \
    lsof \
    python3 \
    python3-pip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Create a soft link from python3 to python 
RUN ln -s /usr/bin/python3 /usr/bin/python

# Install Poetry
RUN pip3 install poetry

# Expose the necessary ports (7474: HTTP, 7687: Bolt)
EXPOSE 7474 7687

# Optionally, you can specify a custom entrypoint or command
# CMD ["neo4j"]

# By default, the Neo4j image uses the following entrypoint
# ENTRYPOINT ["tini", "-g", "--", "/docker-entrypoint.sh"]
# CMD ["neo4j"]

# Setup the directories for our Spark and Hadoop installations
ENV SPARK_HOME=${SPARK_HOME:-"/opt/spark"}
RUN mkdir -p ${SPARK_HOME} 
RUN curl https://dlcdn.apache.org/spark/spark-3.5.1/spark-3.5.1-bin-hadoop3.tgz -o spark-3.5.1-bin-hadoop3.tgz \
 && tar xvzf spark-3.5.1-bin-hadoop3.tgz --directory /opt/spark --strip-components 1 \
 && rm -rf spark-3.5.1-bin-hadoop3.tgz

# Add Spark bins to PATH
ENV PATH=${SPARK_HOME}/bin/:${SPARK_HOME}/sbin:$PATH

# Start Spark history server 
RUN mkdir /tmp/spark-events
RUN chmod -R 777 ${SPARK_HOME}
#CMD ["bash", "-c", "$SPARK_HOME/sbin/start-history-server.sh"]

# NOTE: Octopus has the neo4j spark connector in $OCTOPUS_HOME/server/artifcats/
# Clone and build Octopus 
ENV OCTOPUS_HOME=${OCTOPUS_HOME:-"/opt/octopus"}
COPY octopus $OCTOPUS_HOME

ENV PATH=${OCTOPUS_HOME}/server/job-dispatcher/bin:$PATH

ADD "entrypoint.sh" /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
#WORKDIR ${OCTOPUS_HOME}/server/
#RUN ./build.sh -s

# Run Octopus Server
#WORKDIR ${OCTOPUS_HOME}/server/job-dispatcher
#RUN poetry install
#RUN PATH=${OCTOPUS_HOME}/server/job-dispatcher/bin:$PATH
#RUN start_job_dispatcher.sh


