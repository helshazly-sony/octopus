from fastapi import FastAPI, Depends
from fastapi.responses import HTMLResponse

from sqlalchemy.orm import Session

from src.model import crud, models, schema
from src.model.database import get_db, SessionLocal, engine

from src.utils.requests import QueryExecutionRequest
from src.utils.cmd_builder import CommandBuilder
from src.utils.constants import Constants

from src.utils.helper import *

import concurrent.futures
import subprocess
import logging
import os

def setup():
    logger = logging.getLogger(__name__)
    logging.basicConfig(filename=Constants.LOG_FILE_PATH, \
                        encoding="utf-8", \
                        level=logging.DEBUG, \
                        format='%(asctime)s.%(msecs)03d [%(levelname)s] [%(module)s - %(funcName)s]: %(message)s', \
                        datefmt='%Y-%m-%d %H:%M:%S')
   
    os.makedirs(os.path.dirname(Constants.LOG_FILE_PATH), exist_ok=True)

    logger.info("Starting Data Platform Server.")  

    app = FastAPI()
    logger.info("Initializing Thread Pool.")
    executor = concurrent.futures.ThreadPoolExecutor()
    logger.info("Initializing Metadata Database.")
    models.Base.metadata.create_all(bind=engine)

    return app, executor, logger

app, executor, logger = setup()

@app.get("/")
def read_root():
    octopus_welcome = """

   ____       _                            _    _ _       _       _____           __                                            _____        _          _____  _       _    __                     _ 
  / __ \     | |                       _  | |  | (_)     | |     |  __ \         / _|                                          |  __ \      | |        |  __ \| |     | |  / _|                   | |
 | |  | | ___| |_ ___  _ __  _   _ ___(_) | |__| |_  __ _| |__   | |__) |__ _ __| |_ ___  _ __ _ __ ___   __ _ _ __   ___ ___  | |  | | __ _| |_ __ _  | |__) | | __ _| |_| |_ ___  _ __ _ __ ___ | |
 | |  | |/ __| __/ _ \| '_ \| | | / __|   |  __  | |/ _` | '_ \  |  ___/ _ \ '__|  _/ _ \| '__| '_ ` _ \ / _` | '_ \ / __/ _ \ | |  | |/ _` | __/ _` | |  ___/| |/ _` | __|  _/ _ \| '__| '_ ` _ \| |
 | |__| | (__| || (_) | |_) | |_| \__ \_  | |  | | | (_| | | | | | |  |  __/ |  | || (_) | |  | | | | | | (_| | | | | (_|  __/ | |__| | (_| | || (_| | | |    | | (_| | |_| || (_) | |  | | | | | |_|
  \____/ \___|\__\___/| .__/ \__,_|___(_) |_|  |_|_|\__, |_| |_| |_|   \___|_|  |_| \___/|_|  |_| |_| |_|\__,_|_| |_|\___\___| |_____/ \__,_|\__\__,_| |_|    |_|\__,_|\__|_| \___/|_|  |_| |_| |_(_)
                      | |                            __/ |                                                                                                                                           
                      |_|                           |___/                                                                                                                                            

    """
    html_content = f"""
    <html>
        <body>
            <pre>{octopus_welcome}</pre>
        </body>
    </html>
    """
    return HTMLResponse(content=html_content, status_code=200)    

@app.get("/logs/{execution_record_id}")
def logs(execution_record_id: int, db: Session = Depends(get_db)):
    logger.info("Received Log View Request.")

    logger.info("Reading PySpark Application Log for Execution Record: {0}".format(execution_record_id))
    spark_app_log_path = os.path.join(Constants.SPARK_APP_LOG_PATH, "execution_log_{0}".format(execution_record_id))
    app_log = read_execution_log(spark_app_log_path)
    app_log_html = generate_html(app_log)

    return HTMLResponse(content=app_log_html)

@app.get("/status/{execution_record_id}")
def status(execution_record_id: int, db: Session = Depends(get_db)):
    logger.info("Received Status Request.")
    response = {}

    logger.info("Fetching PySpark Application Status for Execution Record: %s" % str(execution_record_id))
    status = crud.get_spark_app_status(db, execution_record_id)
 
    #NOTE: If status is None, it means that there have been problems launching the pyspark script
    if not status:
       logger.info("PySpark Application Status is None! Setting it to FAIL in the database!")
       status = Constants.STATE["FAIL"]
    elif int(status) == Constants.STATE["SUCCESS"]:
       logger.info("Fetching Flight Description for Execution Record: %s" % str(execution_record_id))
       response["flight-description"] = crud.get_flight_description(db, execution_record_id)
           
    response["state"] = int(status)
    logger.info("Returning Response: %s" % response)

    return response

@app.post("/execute/")
async def execute(request: QueryExecutionRequest, db: Session = Depends(get_db)):
    logger.info("Received Execution Request.")
    
    logger.info("Updating Metadata Database with Request Information.")
    execution_record_id = crud.create_execution_record(db, request)
    logger.info("Execution Record Registered with ID: %s" % execution_record_id)

    future = executor.submit(handle_request, request, execution_record_id, db)
    
    return {"execution_record_id": execution_record_id}

def handle_request(request: QueryExecutionRequest, execution_record_id: int, db: Session = Depends(get_db)):
    logger.info("Processing Execution Request.")

    logger.info("Building Spark Execution Command for Execution Record ID %s" % str(execution_record_id))
    cmdBuilder = CommandBuilder("SPARK", request, str(execution_record_id))
    job_launch_command = cmdBuilder.build_command()
    logger.info("Execution Command for Execution Record ID %s: %s" % (execution_record_id, " ".join(job_launch_command)))

    env = os.environ.copy()
    python_path = env.get("PYTHONPATH", "")
    python_path += os.pathsep + Constants.PYTHON_SITE_PACKAGES_PATH + os.pathsep + Constants.SPARK_ARROW_PATH
    logger.info("PYTHONPATH for the Execution Environment of the Forked Process: %s" % python_path) 
    env["PYTHONPATH"] = python_path
 
    logger.info("Launching the Execution Command.")
    process = subprocess.Popen(job_launch_command, stdout=subprocess.PIPE, stderr=subprocess.PIPE, env=env)
    app_out, app_err = process.communicate()
    app_log = app_out + app_err
    
    app_log_path = os.path.join(Constants.SPARK_APP_LOG_PATH, "execution_log_{0}".format(execution_record_id))
    write_execution_log(app_log, app_log_path)

    logger.info("Registering Log Path '{0}' in the database.".format(app_log_path))
    crud.update_spark_app_log_path(db, execution_record_id, app_log_path)

@app.on_event("shutdown")
async def shutdown_event():
    logger.info("Server Shutting down.")
