#!/bin/bash

## NOTE: java 17 must be used or risk running into bugs in the maven command

# Run Maven install command
mvn clean install

# Check if Maven install succeeded
if [ $? -eq 0 ]; then
    # Copy JAR files and binaries to /opt/octopus/lib
    cp target/*.jar /var/octopus/lib/
    echo "JAR files copied to /var/octopus/lib successfully."
else
    echo "Maven install failed. JAR files not copied."
fi

