#!/bin/bash

start_flight_server.sh

tail -f ${OCTOPUS_ARROW_FLIGHT_LOGS}/container_blocker
