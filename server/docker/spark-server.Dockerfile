FROM python:3.10-bullseye as spark-base

# Install additional libraries
RUN apt-get update && apt-get install -y \
    sudo \
    curl \
    vim \
    lsof \
    unzip \
    rsync \
    openjdk-11-jdk \
    build-essential \
    software-properties-common \
    ssh \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install Poetry
RUN pip3 install poetry

EXPOSE 8000 18080 4040 22 7077 8081

# Setup the directories for our Spark and Hadoop installations
ENV SPARK_HOME=${SPARK_HOME:-"/opt/spark"}
RUN mkdir -p ${SPARK_HOME} && mkdir -p {HADOOP_HOME}
RUN curl https://dlcdn.apache.org/spark/spark-3.5.1/spark-3.5.1-bin-hadoop3.tgz -o spark-3.5.1-bin-hadoop3.tgz \
 && tar xvzf spark-3.5.1-bin-hadoop3.tgz --directory /opt/spark --strip-components 1 \
 && rm -rf spark-3.5.1-bin-hadoop3.tgz

FROM spark-base as pyspark

COPY requirements.txt .
RUN pip3 install -r requirements.txt 

ENV PATH="/opt/spark/sbin:/opt/spark/bin:${PATH}"
ENV SPARK_HOME="/opt/spark"
ENV SPARK_MASTER="job-dispatcher-container:7077"
ENV SPARK_MASTER_HOST job-dispatcher-container
ENV SPARK_MASTER_PORT 7077
ENV PYSPARK_PYTHON python3

#COPY conf/spark-defaults.conf "$SPARK_HOME/conf"

RUN chmod u+x /opt/spark/sbin/* && \
    chmod u+x /opt/spark/bin/*
RUN mkdir /tmp/spark-events

ENV PYTHON_PATH=$SPARK_HOME/python:$PYTHONPATH

COPY spark-entrypoint.sh .
RUN chmod +x ./spark-entrypoint.sh
ENTRYPOINT ["./spark-entrypoint.sh"]

# Start Spark history server 
#RUN mkdir /tmp/spark-events
#RUN chmod -R 777 ${SPARK_HOME}
#CMD ["bash", "-c", "$SPARK_HOME/sbin/start-history-server.sh"]

# NOTE: Octopus has the neo4j spark connector in $OCTOPUS_HOME/server/artifcats/
# Clone and build Octopus 
#ENV OCTOPUS_HOME=${OCTOPUS_HOME:-"/opt/octopus"}
#COPY octopus $OCTOPUS_HOME

#ENV PATH=${OCTOPUS_HOME}/server/job-dispatcher/bin:$PATH

#ADD "entrypoint.sh" /entrypoint.sh
#RUN chmod +x /entrypoint.sh
#ENTRYPOINT ["/entrypoint.sh"]
#WORKDIR ${OCTOPUS_HOME}/server/
#RUN ./build.sh -s

# Run Octopus Server
#WORKDIR ${OCTOPUS_HOME}/server/job-dispatcher
#RUN poetry install
#RUN PATH=${OCTOPUS_HOME}/server/job-dispatcher/bin:$PATH
#RUN start_job_dispatcher.sh


