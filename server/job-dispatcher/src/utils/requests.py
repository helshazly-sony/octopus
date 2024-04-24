from pydantic import BaseModel

class QueryExecutionRequest(BaseModel):
    username: str
    password: str
    query: str
    num_partitions: int
