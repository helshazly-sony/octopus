from pyspark.sql import SparkSession
import socket

def get_hostname(iterator):
    # Return the hostname of the worker running this partition
    yield socket.gethostname()

def print_worker_names():
    # Initialize Spark session
    spark = SparkSession.builder \
        .appName("PrintWorkerNames") \
        .getOrCreate()

    # Create an RDD with dummy data
    data = range(1, 5)
    rdd = spark.sparkContext.parallelize(data, 4)  # 4 partitions

    # Run a job to get the hostname of each worker
    hostnames = rdd.mapPartitions(get_hostname).distinct().collect()

    # Print the worker hostnames
    print("Worker Hostnames:")
    for hostname in hostnames:
        print(hostname)

    # Stop Spark session
    spark.stop()

if __name__ == "__main__":
    print_worker_names()

