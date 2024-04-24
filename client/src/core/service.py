import requests

def send_post_request(url, payload):
    response = requests.post(url, json=payload)
        
    if response.status_code == 200:
       execution_id = response.json()["execution_record_id"]
       if not execution_id:
          raise Exception("Fatal! execution_id is None!")

       return execution_id  
    else:
       raise Exception("Request failed with status {0}!".format(response.status_code)) 

def send_get_request(url, params):
    response = requests.get(url, params=params)
        
    if response.status_code == 200:
       return response.json()
    else:
       raise Exception("Request failed with status {0}!".format(response.status_code))

   
