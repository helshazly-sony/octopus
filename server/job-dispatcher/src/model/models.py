from sqlalchemy import Column, Text, Integer, String, DateTime
from src.model.database import Base

from datetime import datetime

class ExecutionRecord(Base):
    __tablename__ = "executionRecords"

    id = Column(Integer, primary_key=True)
    neo4j_username = Column(String, index=True)
    neo4j_password = Column(String)
    timestamp = Column(DateTime, default=datetime.now)
    neo4j_query = Column(String)
    spark_partitions = Column(Integer)
    spark_app_state = Column(String)
    spark_app_id = Column(String, index=True)
    flight_description = Column(String, index=True)
    spark_app_log_path = Column(Text)


