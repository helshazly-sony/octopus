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
RUN mkdir -p ${SPARK_HOME}
RUN curl https://dlcdn.apache.org/spark/spark-3.5.1/spark-3.5.1-bin-hadoop3.tgz -o spark-3.5.1-bin-hadoop3.tgz \
 && tar xvzf spark-3.5.1-bin-hadoop3.tgz --directory /opt/spark --strip-components 1 \
 && rm -rf spark-3.5.1-bin-hadoop3.tgz


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
# Spark history server 
RUN mkdir /tmp/spark-events
RUN chmod -R 777 ${SPARK_HOME}

ENV PYTHON_PATH=$SPARK_HOME/python:$PYTHONPATH

COPY spark-entrypoint.sh .
RUN chmod +x ./spark-entrypoint.sh
ENTRYPOINT ["./spark-entrypoint.sh"]

########################################
### SPARK MASTER
########################################

FROM spark-base as spark-master
### master does not need openssh server 
### from the docs: the master machine accesses each of the worker machines via ssh
RUN apt-get install openssh-server openssh-client -y

RUN mkdir -p /root/.ssh/ && \
    ssh-keygen -t ed25519 -f /root/.ssh/id_ed25519 -q -N "" && \
    chmod 600 /root/.ssh/id_ed25519 && \
    chmod 644 /root/.ssh/id_ed25519.pub

### The only key which is authorized to connect is the master's key
RUN cp /root/.ssh/id_ed25519.pub /root/.ssh/authorized_keys

### use hardened config for sshd
COPY sshd_config /etc/ssh/sshd_config
RUN mkdir -p /var/run/sshd

### trust the server key fingerprint on first connection
RUN echo "StrictHostKeyChecking accept-new" > /root/.ssh/config

CMD ["/bin/bash", "-c", "ssh job-dispatcher-container"]
CMD ["/bin/bash", "-c", "sleep 5 && ssh spark-worker-container"]

########################################
### SPARK WORKER
########################################

FROM spark-base as spark-worker

### worker requires a running ssh Server
RUN apt-get install openssh-server -y

### The only key which is authorized to connect is the master's key
COPY --from=spark-master /root/.ssh/id_ed25519.pub /root/.ssh/authorized_keys

### use hardened config for sshd
COPY sshd_config /etc/ssh/sshd_config

RUN mkdir -p /var/run/sshd

### run ssh server
#CMD ["/usr/bin/sshd", "-D"]

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


