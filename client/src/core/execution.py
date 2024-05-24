from src.core.service import send_get_request
from src.core.execution_output import ExecutionOutput

import time

class Execution:
   def __init__(self, host, port, execution_id, query, num_partitions):
       self.host = host
       self.port = port
       self.id = execution_id
       self.query = query
       self.num_partitions = num_partitions
       self.state = None
       self.last_status_check_time = 0
       self.last_status = None
       self.flight_description = None
       self.output = None

   def status(self):
       # No need to send the request if the state is failed or success
       if self.state in (0, 1):
          return self.state

       current_time = time.time()
       if current_time - self.last_status_check_time < 1:
          return self.state

       url = f"http://{self.host}:{self.port}/status/{self.id}" 
       response_json = send_get_request(url, params=None) 
       self.state = response_json["state"]
       #TODO: None probably means that status needs more time to be written in the database.. add retries instead!
       if self.state is None:
          raise Exception("Fatal! Execution {0} has None state!".format(self.id)) 
       if self.state == 0:
          self.flight_description = response_json["flight-description"]
          flight_container_hostname = "arrow-flight-server"
          self.output = ExecutionOutput(flight_container_hostname, self.flight_description)

       self.last_status_check_time = current_time
  
       return self.state

   def poll(self):
       while self.state != 0 and self.state != 1:
          self.status()
       return self.state

   def get_output(self):
       return self.output
