package com.sony

//import scala.collection.JavaConverters._
import org.apache.arrow.flight.{AsyncPutListener, FlightClient, FlightDescriptor, Location}
//import org.apache.spark.rdd.RDD
import org.apache.spark.sql.DataFrame
//import org.apache.spark.sql.catalyst.InternalRow
import org.apache.spark.sql.execution.arrow.ArrowRDD

class SparkFlightConnector() {

  def put(dataset: DataFrame, host: String, port: Int, descriptor: String): Unit = {
    val rdd = new ArrowRDD(dataset)

    rdd.mapPartitions { it =>
      val allocator = it.allocator.newChildAllocator("SparkFlightConnector", 0, Long.MaxValue)

      val client = FlightClient.builder(allocator, Location.forGrpcInsecure(host, port)).build()
      val desc = FlightDescriptor.path(descriptor)

      val stream = client.startPut(desc, it.root, new AsyncPutListener())

      // Use VectorSchemaRootIterator to convert Rows -> Vectors
      it.foreach { root =>
        // doPut on the populated VectorSchemaRoot
        stream.putNext()
      }

      stream.completed()
      // Need to call this, or exceptions from the server get swallowed
      stream.getResult

      client.close()

      Iterator.empty
    }.count()
  }
}
