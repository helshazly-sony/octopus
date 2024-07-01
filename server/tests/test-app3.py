from pyspark.sql import SparkSession
import time

# Initialize Spark Session
spark = SparkSession.builder \
    .appName("TestApp3") \
    .config("spark.executor.memory", "100g") \
    .config("spark.executor.cores", "24") \
    .config("spark.cores.max", "24") \
    .getOrCreate()

# Dummy job to hold the resources
df = spark.range(100000000).toDF("number")
df.select("number").count()

# Keep the job running for a while to observe the behavior
time.sleep(30)

spark.stop()

