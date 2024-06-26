package org.apache.spark.sql.execution.arrow

import org.apache.arrow.memory.BufferAllocator
import org.apache.arrow.vector.VectorSchemaRoot
import org.apache.spark.internal.Logging
import org.apache.spark.rdd.{RDD, RDDOperationScope}
import org.apache.spark.sql.catalyst.InternalRow
import org.apache.spark.sql.execution.python.BatchIterator
import org.apache.spark.sql.types.StructType
import org.apache.spark.sql.{DataFrame, SQLContext}
import org.apache.spark.sql.util.ArrowUtils
import org.apache.spark.{Partition, Partitioner, SparkContext, TaskContext}

import scala.reflect.ClassTag


class VectorSchemaRootIterator(
    batchIter: Iterator[Iterator[InternalRow]],
    val allocator: BufferAllocator,
    val root: VectorSchemaRoot)
  extends Iterator[VectorSchemaRoot] {

  private var rowBatchIter = if (batchIter.hasNext) batchIter.next() else Iterator.empty

  override def hasNext: Boolean = rowBatchIter.hasNext

  override def next(): VectorSchemaRoot = {
    val arrowWriter = ArrowWriter.create(root)
    while (rowBatchIter.hasNext) {
      arrowWriter.write(rowBatchIter.next())
    }
    arrowWriter.finish()
    if (batchIter.hasNext) {
      rowBatchIter = batchIter.next()
    }
    root
  }
}

  class ArrowRDD(
    @transient val parent: DataFrame,
    isFromBarrier: Boolean = false)
  extends Serializable with Logging {

  protected def sqlContext: SQLContext = parent.sqlContext
  protected def sc: SparkContext = parent.sqlContext.sparkContext

  lazy val rdd: RDD[InternalRow] = parent.queryExecution.toRdd

  def mapPartitions[U: ClassTag](
      f: VectorSchemaRootIterator => Iterator[U],
      preservesPartitioning: Boolean = false): RDD[U] = withScope {
    val cleanedF = sc.clean(f)
    new MapPartitionsArrowRDD(
      this,
      parent.schema,
      (context: TaskContext, index: Int, iter: VectorSchemaRootIterator) => cleanedF(iter),
      preservesPartitioning)
  }

  def mapPartitionsWithIndex[U: ClassTag](
      f: (Int, VectorSchemaRootIterator) => Iterator[U],
      preservesPartitioning: Boolean = false): RDD[U] = withScope {
    val cleanedF = sc.clean(f)
    new MapPartitionsArrowRDD(
      this,
      parent.schema,
      (context: TaskContext, index: Int, iter: VectorSchemaRootIterator) => cleanedF(index, iter),
      preservesPartitioning)
  }

  private[spark] def withScope[U](body: => U): U = RDDOperationScope.withScope[U](sc)(body)
}

private[spark] class MapPartitionsArrowRDD[U: ClassTag](
    var prev: ArrowRDD,
    schema: StructType,
    f: (TaskContext, Int, VectorSchemaRootIterator) => Iterator[U],  // (TaskContext, partition index, iterator)
    preservesPartitioning: Boolean = false,
    isFromBarrier: Boolean = false,
    isOrderSensitive: Boolean = false)
  extends RDD[U](prev.rdd) {

  override val partitioner: Option[Partitioner] = if (preservesPartitioning)
    firstParent[VectorSchemaRootIterator].partitioner else None

  override def getPartitions: Array[Partition] = firstParent[VectorSchemaRootIterator].partitions

  override def compute(split: Partition, context: TaskContext): Iterator[U] = {
    val iter = firstParent[InternalRow].iterator(split, context)
    val batchSize = 0  // TODO: from ArrowEvalPythonExec
    val batchIter = if (batchSize > 0) new BatchIterator(iter, batchSize) else Iterator(iter)
    val arrowSchema = ArrowUtils.toArrowSchema(schema, null, false, false)  // TODO: timeZoneId)
    val allocator = ArrowUtils.rootAllocator.newChildAllocator(
      s"stdout writer for MapPartitionsArrowRDD", 0, Long.MaxValue)
    val root = VectorSchemaRoot.create(arrowSchema, allocator)
    val arrowRootIter = new VectorSchemaRootIterator(batchIter, allocator, root)
    f(context, split.index, arrowRootIter)
  }

  override def clearDependencies() {
    super.clearDependencies()
    prev = null
  }

  @transient protected lazy override val isBarrier_ : Boolean =
    isFromBarrier || dependencies.exists(_.rdd.isBarrier())
  /* TODO
  override protected def getOutputDeterministicLevel = {
    if (isOrderSensitive && prev.outputDeterministicLevel == DeterministicLevel.UNORDERED) {
      DeterministicLevel.INDETERMINATE
    } else {
      super.getOutputDeterministicLevel
    }
  }*/
}

