FROM bitnami/java:17.0.11-12 as build

ENV OCTOPUS_LIB_DIR="/data-transfer/lib"

COPY server/data-transfer /data-transfer

WORKDIR /data-transfer
RUN install_packages maven
RUN ./build.sh


FROM bitnami/java:17.0.11-12 as arrow-flight

ENV OCTOPUS_HOME="/opt/octopus"
ENV OCTOPUS_LIB_DIR="${OCTOPUS_HOME}/lib"
ENV OCTOPUS_ARROW_FLIGHT_LOGS="${OCTOPUS_HOME}/logs"

RUN install_packages python3.11 python3-pip

WORKDIR $OCTOPUS_HOME
COPY server ./server
COPY --from=build /data-transfer/lib $OCTOPUS_LIB_DIR

RUN rm -rf /usr/lib/python3.11/EXTERNALLY-MANAGED && \
    pip3 install -r server/requirements.txt && \
    mkdir -p -m 775 $OCTOPUS_ARROW_FLIGHT_LOGS

USER 1001
EXPOSE 8888

ENTRYPOINT ["./server/data-transfer/bin/start_flight_server.sh"]


