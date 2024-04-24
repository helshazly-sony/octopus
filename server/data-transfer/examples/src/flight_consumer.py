import subprocess

import pyarrow as pa
import pyarrow.flight as pa_flight

from spark_flight_connector import SparkFlightConnector

def main():

    # Location of the Flight Service
    host = '127.0.0.1'
    port = '8888'

    # Unique identifier for flight data
    #flight_desc = 'neo4j-spark-flight-test'
    flight_desc = "flight_local-1712671213857"
    # ------------------------------------------------------------- #
    # Create a Pandas DataFrame from a pyarrow Flight client reader #
    # ------------------------------------------------------------- #

    # Connect to the Flight service and get endpoints from FlightInfo
    client = pa_flight.connect((host, int(port)))
    desc = pa_flight.FlightDescriptor.for_path(flight_desc)
    info = client.get_flight_info(desc)
    endpoints = info.endpoints

    # Read all flight endpoints into pyarrow Tables
    tables = []
    print("endpoints: {0}".format(len(endpoints)))
    for e in endpoints:
        flight_reader = client.do_get(e.ticket)
        table = flight_reader.read_all()
        tables.append(table)

    # Convert Tables to a single Pandas DataFrame
    # table = pa.concat_tables(tables)
    # pdf = table.to_pandas()
    for t in tables:
        #print("Data Type: ", t)
        print("Count: ", len(t)) 
    #print(f"DataFrame from Flight streams:\n{pdf}")

if __name__ == "__main__":
    main()
