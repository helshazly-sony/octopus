
import os 

class Constants():
    PYTHON_SITE_PACKAGES_PATH = "/usr/local/lib/python3.9/dist-packages"

    SPARK_SUBMIT_COMMAND = "spark-submit"
    MASTER_URL = "localhost[*]"
    DEPLOY_MODE = "client"
    SPARK_EXECUTOR_MEMORY = "spark.executor.memory=7g"
    SPARK_DRIVER_MEMORY = "spark.driver.memory=150g"
    SPARK_DRIVER_MAX_RESULT_SIZE = "spark.driver.maxResultSize=150g"

    ROOT_DIR = "/opt/octopus/server/job-dispatcher/src"
    PYSPARK_SCRIPT_PATH = os.path.join(ROOT_DIR, "utils/scripts/pyspark_connector.py")
    PY_CRUD_PATH = os.path.join(ROOT_DIR, "model/crud.py")
    PY_DB_PATH = os.path.join(ROOT_DIR, "model/database.py")
    PY_CONSTANTS_PATH = os.path.join(ROOT_DIR, "utils/constants.py")
    PY_FILES = [PY_CRUD_PATH, \
                PY_DB_PATH, \
                PY_CONSTANTS_PATH]

    JARS_PATH = "/opt/octopus/server/artifacts"
    NEO4J_SPARK_CONN_JAR = os.path.join(JARS_PATH, "neo4j-connector-apache-spark_2.12-5.2.0_for_spark_3.jar")
    FLIGHT_CORE_JAR = os.path.join(JARS_PATH, "flight-core-16.0.0-SNAPSHOT-shaded-ext.jar")
    FLIGHT_CORE_JAR_W_DEP_JAR = os.path.join(JARS_PATH, "flight-core-16.0.0-SNAPSHOT-jar-with-dependencies.jar")
    SPARK_ARROW_CONN_JAR = os.path.join(JARS_PATH, "data-platform-server-1.0.0-SNAPSHOT-jar-with-dependencies.jar")
    
    # For Testing
    NEO4J_JAR = os.path.join("/var/lib/neo4j/plugins/", NEO4J_SPARK_CONN_JAR)

    JARS = [NEO4J_SPARK_CONN_JAR, \
            FLIGHT_CORE_JAR, \
            FLIGHT_CORE_JAR_W_DEP_JAR, \
            SPARK_ARROW_CONN_JAR]

    # FLIGHT ARROW
    SPARK_ARROW_PATH = "/opt/octopus/server/job-dispatcher/src" + "/../../data-transfer/src/main/python"
    HOST = "arrow-flight-server"
    PORT = "8888"

    # NEO4J
    NEO4J_BOLT_SERVER_URL = "bolt://localhost:7687"

    # METADATA Database
    METADATA_DB = os.path.join("/tmp/", "metadata.db")

    # LOGGING
    LOG_FILE_PATH = os.path.join("/tmp/", "octopus-server.log")
    SPARK_APP_LOG_PATH = os.path.join("/tmp/", "spark-logs")

    # SPARK APP STATUS
    STATE = {"STAGED":-2, \
             "RUNNING":-1, \
             "SUCCESS":0, \
             "FAIL":1}
   