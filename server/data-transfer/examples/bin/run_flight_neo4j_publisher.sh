#!/bin/bash


SPARK_SUBMIT=spark-submit
M2_LOCAL_REPO=$HOME/.m2/repository
FLIGHT_CORE=/root/eval/arrow/java/flight/flight-core/target/
MY_SPARK_ARROW=../../data-platform-server-1.0.0-SNAPSHOT.jar

PYSPARK_PYTHON=`which python` $SPARK_SUBMIT \
    --jars "/var/lib/neo4j/plugins/neo4j-connector-apache-spark_2.12-5.2.0_for_spark_3.jar,$MY_SPARK_ARROW,$FLIGHT_CORE/flight-core-16.0.0-SNAPSHOT-shaded-ext.jar,$FLIGHT_CORE/flight-core-16.0.0-SNAPSHOT-jar-with-dependencies.jar" \
    --py-files "../src/main/python/spark_flight_connector.py" \
    --conf spark.executor.memory=7g \
    --conf spark.driver.memory=300g \
    --conf spark.driver.maxResultSize=150g \
     ../src/python/neo4j_publisher.py

