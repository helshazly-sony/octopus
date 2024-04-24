from src.core.execution import Execution
from src.core.service import send_post_request

class DataPlatformClient:
    def __init__(self, host, port, username, password):
        self.host = host
        self.port = port 
        self.username = username
        self.password = password

    def execute(self, query, num_partitions):
        url = f'http://{self.host}:{self.port}/execute'
        payload = {
            'username': self.username,
            'password': self.password,
            'query': query,
            'num_partitions': num_partitions
        }

        execution_id = send_post_request(url, payload)
        execution = Execution(self.host, self.port, execution_id, query, num_partitions)
        return execution 
