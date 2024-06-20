#!/bin/bash

## NOTE: java 17 must be used or risk running into bugs in the maven command

# Run Maven install command
mvn clean install

# Check if Maven install succeeded
if [ $? -eq 0 ]; then
    # Copy JAR files and binaries to /opt/octopus/lib
    mkdir -p ${OCTOPUS_LIB_DIR}
    cp target/*.jar ${OCTOPUS_LIB_DIR}
    echo "JAR files copied to ${OCTOPUS_LIB_DIR} successfully."
else
    echo "Maven install failed. JAR files not copied."
fi

