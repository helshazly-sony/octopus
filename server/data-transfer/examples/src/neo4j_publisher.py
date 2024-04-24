from pyspark.sql import SparkSession
from pyspark.sql.pandas.types import to_arrow_schema

import pyarrow as pa
import pyarrow.flight as pa_flight

from spark_flight_connector import SparkFlightConnector


def main():
    # Location of the Flight Service
    host = '127.0.0.1'
    port = '8888'

    # Unique identifier for flight data
    flight_desc = 'neo4j-spark-flight-test'

    # --------------------------------------------- #
    # Run Spark to put Arrow data to Flight Service #
    # --------------------------------------------- #
    spark = SparkSession.builder \
            .appName("Cleaner") \
            .master("local[*]") \
            .config("spark.executor.memory", "7g") \
            .config("spark.driver.memory", "200g") \
            .config("spark.driver.maxResultSize", "150g") \
            .getOrCreate()

    df = spark.read.format("org.neo4j.spark.DataSource") \
            .option("authentication.basic.username", "neo4j") \
            .option("authentication.basic.password", "password") \
            .option("url", "bolt://localhost:7687") \
            .option("query", "MATCH (r) RETURN r") \
            .option("partitions", 4) \
            .load() \

    print(">>>>>>>>>>>>>>>> ", df.rdd.getNumPartitions())
    print(">>>>>>>>>>>>>>>> ", df.count())

    # Put the Spark DataFrame to the Flight Service
    SparkFlightConnector.put(df, host, port, flight_desc)
    
    # Exit
    spark.stop()

if __name__ == "__main__":
    main()
