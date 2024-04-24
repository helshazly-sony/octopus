from pydantic import BaseModel
from datetime import datetime

class ExecutionRecordSchema(BaseModel):
    id: int
    timestamp: datetime
    neo4j_username: str
    neo4j_password: str
    neo4j_query: str
    spark_partitions: int
    spark_app_state: str
    spark_app_id: int
    spark_app_log_path: str
    flight_description: str
