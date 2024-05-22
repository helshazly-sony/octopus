from crud import update_spark_app_id
from crud import update_spark_app_status
from crud import update_flight_description

from constants import Constants
from database import get_db

from pyspark.sql import SparkSession

from spark_flight_connector import SparkFlightConnector

import argparse

def parse_arguments():
    parser = argparse.ArgumentParser(description='PySpark Script Argument Parser')
    parser.add_argument('execution_record_id', type=str, help='Execution Record ID')
    parser.add_argument('username', type=str, help='Username')
    parser.add_argument('password', type=str, help='Password')
    parser.add_argument('query', type=str, help='Neo4j Query')
    parser.add_argument('num_partitions', type=str, help='Number of partitions', default=1)

    return parser.parse_args()

def connect(execution_record_id):
    """Creates or gets Spark session object.

    Returns:
      Spark Session: Spark session Object.
    """
    spark = SparkSession.builder \
            .appName("execution-{0}".format(execution_record_id)) \
            .getOrCreate()

    return spark

def execute_query(spark, args):
    """Executes a Neo4j Query.

    Args:
      spark (Spark Session): Spark session object.
      args (Dict): Arguments.

    Return:
      int: Node count.
    """
    df = spark.read.format("org.neo4j.spark.DataSource") \
            .option("authentication.basic.username", args.username) \
            .option("authentication.basic.password", args.password) \
            .option("url", Constants.NEO4J_BOLT_SERVER_URL) \
            .option("query", args.query) \
            .option("partitions", int(args.num_partitions)) \
            .load() \

    return df

def test(num_partitions):
    from pyspark.sql.functions import regexp_replace, col

    sample_data = [{"name": "John    D.", "age": 30},{"name": "Alice   G.", "age": 25},{"name": "Bob  T.", "age": 35},{"name": "Eve   A.", "age": 28}]

    df = spark.createDataFrame(sample_data)
    df_transformed = df.withColumn("name", regexp_replace(col("name"), "\\s+", " "))
    df_transformed.show()

    df_transformed = df_transformed.repartition(num_partitions)

    return df_transformed

if __name__ == "__main__":
    spark = None
    args = parse_arguments()
    db = None

    try:
      db = next(get_db())
    except Exception as error:
      print("FATAL! Failed to connect to the database.")
      sys.exit(1)

    #Add running signal to the database
    update_spark_app_status(db, \
                            int(args.execution_record_id), \
                            Constants.STATE["RUNNING"])

    try:
       spark = connect(int(args.execution_record_id))

       update_spark_app_id(db, \
                           int(args.execution_record_id), \
                           spark._sc.applicationId)

       #df = test(int(args.num_partitions))
       df = execute_query(spark, args)
       
       #Add Flight Description to DB
       flight_description = "flight_" + spark._sc.applicationId
       update_flight_description(db, \
                                 int(args.execution_record_id), \
                                 flight_description)

       #Put the data in the flight server
       SparkFlightConnector.put(df, Constants.HOST, Constants.PORT, flight_description)

       spark.stop()

       #Add success signal to the database
       update_spark_app_status(db, \
                               int(args.execution_record_id), \
                               Constants.STATE["SUCCESS"])
    except Exception as error:
        #Add Failure signal to the database
        update_spark_app_status(db, \
                                int(args.execution_record_id), \
                                Constants.STATE["FAIL"])

        if spark is not None:
           spark.stop()

        print(error)

