import os

def write_execution_log(app_log, app_log_path):
    os.makedirs(os.path.dirname(app_log_path), exist_ok=True)

    with open(app_log_path, "wb") as fb:
       fb.write(app_log)

def read_execution_log(app_log_path):
    log = None
    try:
       with open(app_log_path, "rb") as fb:
          log = fb.read()
       return log
    except FileNotFoundError:
       raise FileNotFoundError(f"The file '{app_log_path}' does not exist.")

def generate_html(app_log):
    app_log = app_log.decode("utf-8").replace("\n", "<br/>")

    html_content = f"""
    <html>
    <body>
        <p>{app_log}</p>
    </body>
    </html>
    """
   
    return html_content    
