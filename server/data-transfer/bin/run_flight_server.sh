#!/bin/bash

PORT_NUM=${1:-8888}

## Check if the env variable OCTOPUS_ARROW_FLIGHT_LOGS is set
## if not, use the default /tmp/
DEFAULT_LOG_DIR="/tmp/"
LOG_DIR="${OCTOPUS_ARROW_FLIGHT_LOGS:-$DEFAULT_LOG_DIR}"
LOG_FILE="${LOG_DIR}/flight_server_$(date +'%Y%m%d_%H%M%S').log"

DEFAULT_OCTOPUS_LIB_DIR="/opt/octopus/lib"
LIB_DIR="${OCTOPUS_LIB_DIR:-$DEFAULT_OCTOPUS_LIB_DIR}"

java --add-opens=java.base/java.nio=ALL-UNNAMED -cp $DEFAULT_OCTOPUS_LIB_DIR/octopus-server-1.0.0-beta.1-SNAPSHOT-jar-with-dependencies.jar com.sony.SparkFlightServer --port ${PORT_NUM} >> ${LOG_FILE} 2>&1 &
