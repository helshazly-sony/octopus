import pyarrow as pa
import pyarrow.flight as paf

class ExecutionOutput:
   def __init__(self, host, flight_description, port="8888"):
       self.host = host
       self.port = port
       self.client = paf.connect((host, int(port)))
       self.flight_description = paf.FlightDescriptor.for_path(flight_description)
       self.info = self.client.get_flight_info(self.flight_description)
       self.endpoints = self.info.endpoints
       self.index = 0
       self.tables = None

   def __iter__(self):
       return self

   def __next__(self):
       if self.index < len(self.endpoints):
           table = self.fetch_next()
           self.index += 1
           return table
       else:
          raise StopIteration

   def has_next(self):
       return self.index < len(self.endpoints)

   def fetch_next(self):
       if self.index == -1 or self.index > len(self.endpoints):
           return None

       e = self.endpoints[self.index]
       flight_reader = self.client.do_get(e.ticket)
       table = flight_reader.read_all()

       # Remove partitions from the server
       self.drop(e.ticket.ticket)
 
       return table

   def fetch_all(self):
       if self.tables != None and len(self.tables) == len(self.endpoints):
           return self.tables

       self.tables = []
       for e in self.endpoints:
           flight_reader = self.client.do_get(e.ticket)
           table = flight_reader.read_all()
           # Remove parition from the server after consumption
           self.drop(e.ticket.ticket)           
   
           self.tables.append(table)

       return self.tables

   def drop(self, partition_ticket):
       drop_action = pa.flight.Action("drop", partition_ticket)

       # TODO: Improve Error Checking (Return Integer Flags Instead of Text)
       for response in self.client.do_action(drop_action):
           if "Failure" in response.body.to_pybytes().decode("utf-8"):
               return 1 
