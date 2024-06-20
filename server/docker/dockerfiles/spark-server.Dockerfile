FROM python:3.10-bullseye as git

RUN mkdir -p -m 0600 ~/.ssh && \
    ssh-keyscan github.com >> ~/.ssh/known_hosts

WORKDIR /git
RUN --mount=type=ssh,id=default git clone git@github.com:helshazly-sony/octopus.git

FROM python:3.10-bullseye as spark-base

# Install additional libraries
RUN apt-get update && apt-get install -y \
    curl \
    vim \
    lsof \
    unzip \
    rsync \
    openjdk-11-jdk \
    build-essential \
    software-properties-common \
    openssh-server \
    #openssh-client \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install Poetry
RUN pip3 install poetry

EXPOSE 8000 18080 4040 22 7077 8081

# Setup the directories for our Spark and Hadoop installations
ENV SPARK_HOME=${SPARK_HOME:-"/opt/spark"}
RUN mkdir -p ${SPARK_HOME} && \
    curl https://dlcdn.apache.org/spark/spark-3.5.1/spark-3.5.1-bin-hadoop3.tgz -o spark-3.5.1-bin-hadoop3.tgz \
    && tar xvzf spark-3.5.1-bin-hadoop3.tgz --directory /opt/spark --strip-components 1 \
    && rm -rf spark-3.5.1-bin-hadoop3.tgz

COPY conf/requirements.txt .
RUN pip3 install -r requirements.txt 

ENV PATH="/opt/spark/sbin:/opt/spark/bin:${PATH}"
ENV SPARK_MASTER="job-dispatcher-container:7077"
ENV SPARK_MASTER_HOST job-dispatcher-container
ENV SPARK_MASTER_PORT 7077
ENV PYSPARK_PYTHON python3
ENV PYTHON_PATH=$SPARK_HOME/python:$PYTHONPATH
ENV OCTOPUS_HOME="/home/octopus"

COPY conf/spark/spark-defaults.conf $SPARK_HOME/conf
COPY conf/spark/spark-env.sh $SPARK_HOME/conf
COPY entrypoints/spark-entrypoint.sh .

# TODO: restrict access to octopus user
RUN chmod -R 777 ${SPARK_HOME} && \
    chmod +x $SPARK_HOME/conf/spark-env.sh && \
    chmod u+x /opt/spark/sbin/* && \
    chmod u+x /opt/spark/bin/* && \
    chmod +x ./spark-entrypoint.sh

### To prevent container exist
RUN touch /container_blocker

### Add non-root user
RUN addgroup --gid 1000 octopus && \
    adduser --uid 1000 --shell /bin/bash --system --gid 1000 octopus

### Setup SSH bits
RUN mkdir -p /var/run/sshd && \
    mkdir -p $OCTOPUS_HOME/.ssh && \
    chown -R 1000:1000 $OCTOPUS_HOME

RUN chown octopus:octopus /spark-entrypoint.sh && \
    chown octopus:octopus /container_blocker

WORKDIR $OCTOPUS_HOME
USER 1000

########################################
### SPARK MASTER
########################################

FROM spark-base as spark-master

# TODO: switch to password-based ssh
RUN echo "StrictHostKeyChecking accept-new" > ~/.ssh/config && \
    ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -q -N "" && \
    chmod 600 ~/.ssh/id_ed25519 && \
    chmod 644 ~/.ssh/id_ed25519.pub

COPY --from=git --chown=1000 /git/octopus/server ${OCTOPUS_HOME}/server

COPY --chown=1000 sched-tests ./sched-tests

# Spark history server 
RUN mkdir /tmp/spark-events

### Octopus Job Dispatcher
# NOTE: Octopus has the neo4j spark connector in $OCTOPUS_HOME/server/artifcats/
ENV PATH=${OCTOPUS_HOME}/server/job-dispatcher/bin:$PATH

WORKDIR ${OCTOPUS_HOME}/server/

RUN ./build.sh -s && \
    poetry install --directory=job-dispatcher

ENTRYPOINT ["/spark-entrypoint.sh", "master"]

########################################
### SPARK WORKER
########################################

FROM spark-base as spark-worker

### The only key which is authorized to connect is the master's key

### use hardened config for sshd
COPY --chown=1000 conf/ssh/sshd_config ./ssh/sshd_config
RUN ssh-keygen -t ed25519 -f ~/ssh/ssh_host_ed25519_key -q -N ""

COPY --from=spark-master ${OCTOPUS_HOME}/.ssh/id_ed25519.pub ${OCTOPUS_HOME}/.ssh/authorized_keys

ENTRYPOINT ["/spark-entrypoint.sh", "worker"]

