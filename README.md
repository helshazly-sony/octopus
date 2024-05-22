# Octopus

Octopus is a powerful and flexible data processing platform designed to handle large-scale data analytics. 
Leveraging technologies such as Neo4j, PySpark, and Apache Arrow Flight, Octopus enables efficient graph data querying, processing, and analysis. 
Octopus is offered as a Platform-as-a-Service (PaaS), such that users can leverage its capabilities without worrying about underlying computation resources or performance management. 
Thus, enabling users to focus on data processing and analytics tasks while Octopus handles the scalability, resource allocation, and performance optimization. 
Octopus also provides a high-level Python API that gives users flexibility to retrieve their results in batches/partitions of pyarrow format that can be easily used in down-stream workflows. 

# Features
- **Graph Database Integration:** Utilize Neo4j for efficient graph data querying and management.
- **Distributed Processing:** Leverage PySpark for scalable and distributed data processing.
- **High-Performance Data Transfer:** Use Apache Arrow Flight for fast and efficient data transport.
- **Iterable-like Python API:** Client can use iterable Python syntax to retrieve query results from the server.

# Usage

## Basic Usage

1. Client initializes Octopus Client

```python
from octopus import OctopusClient

oc = OctopusClient("octopus_server_ip", "octopus_server_port", "neo4j_username", "neo4j_password")
```

2. Execute a Query

```python
execution = oc.execute("MATCH (h)-[r]-(t) RETURN h, r, t", 20)
```

3. Fetch Results

```python
success = execution.poll()
if success == 0:
   result = execution.output

partitions = result.fetch_all()

for partition in partitions:
    print(len(partition))
```
