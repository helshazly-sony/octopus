from sqlalchemy.orm import Session
from sqlalchemy import update

from src.model.models import ExecutionRecord

from src.utils.requests import QueryExecutionRequest

from datetime import datetime

def create_execution_record(db: Session, request: QueryExecutionRequest):
    db_execution_record = ExecutionRecord(neo4j_username = request.username, \
                                          neo4j_password = request.password, \
                                          neo4j_query = request.query, \
                                          spark_partitions = request.num_partitions, \
                                          spark_app_state = -2, \
                                          spark_app_id = None, \
                                          flight_description = None, \
                                          spark_app_log_path = None, \
                                          timestamp = datetime.now())

    db.add(db_execution_record)
    db.commit()
    db.refresh(db_execution_record)

    return db_execution_record.id

def update_spark_app_id(db: Session, execution_record_id: int, app_id: int):
    update_stmt = (
                   update(ExecutionRecord) \
                  .where(ExecutionRecord.id == execution_record_id) \
                  .values(spark_app_id = app_id)
                  )

    db.execute(update_stmt)
    db.commit()

def update_spark_app_status(db: Session, execution_record_id: int, app_state: int):
    update_stmt = (
                   update(ExecutionRecord) \
                  .where(ExecutionRecord.id == execution_record_id) \
                  .values(spark_app_state = app_state)
                  )

    db.execute(update_stmt)
    db.commit()

def update_spark_app_log_path(db: Session, execution_record_id: int, app_log_path: str):
    update_stmt = (
                   update(ExecutionRecord) \
                  .where(ExecutionRecord.id == execution_record_id) \
                  .values(spark_app_log_path = app_log_path)
                  )

    db.execute(update_stmt)
    db.commit()

def update_flight_description(db: Session, execution_record_id: int, flight_description: str):
    update_stmt = (
                   update(ExecutionRecord) \
                  .where(ExecutionRecord.id == execution_record_id) \
                  .values(flight_description = flight_description)
                  )

    db.execute(update_stmt)
    db.commit()

def get_spark_app_status(db: Session, execution_record_id: int):
    return db.query(ExecutionRecord.spark_app_state) \
           .filter(ExecutionRecord.id == execution_record_id) \
           .scalar()

def get_flight_description(db: Session, execution_record_id: int):
     return db.query(ExecutionRecord.flight_description) \
           .filter(ExecutionRecord.id == execution_record_id) \
           .scalar()

   
