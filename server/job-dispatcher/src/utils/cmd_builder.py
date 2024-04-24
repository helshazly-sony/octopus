from src.utils.constants import Constants

class CommandBuilder():
    def __init__(self, cmd_type, request, execution_record_id):
        self.cmd_type = cmd_type
        self.request = request
        self.execution_record_id = execution_record_id

    def build_command(self):
        if self.cmd_type == "SPARK":
           return self.build_spark_launch_command()

    def build_spark_launch_command(self):
        command = [Constants.SPARK_SUBMIT_COMMAND, \
                   #NOTE: commented out for testing, local[*] causes issues in commandline
                   #"--master", \
                   #Constants.MASTER_URL, \
                   #NOTE: The conf args are specified because the client deployment mode, yarn should have its own parameters for tuning executor memories
                   "--conf", Constants.SPARK_EXECUTOR_MEMORY, \
                   "--conf", Constants.SPARK_DRIVER_MEMORY, \
                   "--conf", Constants.SPARK_DRIVER_MAX_RESULT_SIZE, \
                   "--deploy-mode", \
                   Constants.DEPLOY_MODE, \
                   "--jars", \
                   ",".join(Constants.JARS), \
                   "--py-files", \
                   ",".join(Constants.PY_FILES), \
                   Constants.PYSPARK_SCRIPT_PATH, \
                   self.execution_record_id, \
                   self.request.username, \
                   self.request.password, \
                   self.request.query, \
                   str(self.request.num_partitions)]

        return command


