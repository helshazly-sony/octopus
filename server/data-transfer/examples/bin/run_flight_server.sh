#!/bin/bash

PORT_NUM=${1:-8888}

java --add-opens=java.base/java.nio=ALL-UNNAMED -cp ../../../artifacts/data-platform-server-1.0.0-SNAPSHOT-jar-with-dependencies.jar com.sony.SparkFlightServer --port ${PORT_NUM}
