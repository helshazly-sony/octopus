FROM python:3.10-bullseye as git

RUN mkdir -p -m 0600 ~/.ssh && \
    ssh-keyscan github.com >> ~/.ssh/known_hosts

WORKDIR /git
RUN --mount=type=ssh,id=default git clone git@github.com:helshazly-sony/octopus.git

FROM python:3.10-bullseye as arrow-flight-base

# Install additional libraries
RUN apt-get update && apt-get install -y \
    curl \
    vim \
    lsof \
    unzip \
    rsync \
    openjdk-17-jdk \
    maven \
    build-essential \
    software-properties-common \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN pip3 install poetry

EXPOSE 8888

ENV OCTOPUS_HOME="/home/octopus"
ENV OCTOPUS_DATA_TRANSFER_HOME="${OCTOPUS_HOME}/server/data-transfer" 
ENV OCTOPUS_ARROW_FLIGHT_LOGS="${OCTOPUS_HOME}/logs"
ENV OCTOPUS_LIB_DIR="/var/octopus/lib"
ENV OCTOPUS_ARROW_FLIGHT_LOGS="${OCTOPUS_HOME}/logs/"
ENV ARROW_FLIGHT_SERVER="arrow-flight-server-container"
ENV PATH="${OCTOPUS_LIB_DIR}":"${OCTOPUS_DATA_TRANSFER_HOME}/bin":$PATH

COPY arrow-entrypoint.sh .

RUN chmod +x ./arrow-entrypoint.sh

### Add non-root user
RUN addgroup --gid 1000 octopus && \
    adduser --uid 1000 --shell /bin/bash --system --gid 1000 octopus

### Create Octopus User
RUN chown -R 1000:1000 $OCTOPUS_HOME && \
    mkdir -p $OCTOPUS_LIB_DIR && \
    mkdir -p $OCTOPUS_ARROW_FLIGHT_LOGS && \
    chown -R 1000:1000 $OCTOPUS_LIB_DIR

RUN chown octopus:octopus /arrow-entrypoint.sh && \
    chown -R octopus:octopus $OCTOPUS_ARROW_FLIGHT_LOGS

WORKDIR $OCTOPUS_HOME
USER 1000

########################################
### Arrow Flight Server
########################################
COPY --from=git --chown=1000 /git/octopus/server ${OCTOPUS_HOME}/server

WORKDIR $OCTOPUS_HOME/server/data-transfer/

RUN touch ${OCTOPUS_ARROW_FLIGHT_LOGS}/container_blocker && \
    ./build.sh

ENTRYPOINT ["/arrow-entrypoint.sh"]


