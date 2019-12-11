#!/usr/bin/env python3
import json
import sys
import urllib.request

def external_data():
  # Make sure the input is a valid JSON.
  input_json = sys.stdin.read()
  try:
      input_dict = json.loads(input_json)
  except ValueError as value_error:
      sys.exit(value_error)

  # Input variables
  backend_host = input_dict["backend_host"]
  account_id = input_dict["account_id"]
  username   = input_dict["username"]
  password   = input_dict["password"]

  payload = json.loads('{{"data":{{"attributes":{{"account_id":"{0}","password":"{1}","username":"{2}"}}}}}}'.format(account_id,password,username))
  url = 'https://{}/iam/users/sign_in'.format(backend_host)

  # Prepare request
  jsondata = json.dumps(payload)
  jsondataasbytes = jsondata.encode('utf-8')   # needs to be bytes

  req = urllib.request.Request(url, jsondataasbytes)
  req.add_header('Content-Type', 'application/json')
  req.add_header('Content-Length', len(jsondataasbytes))

  # Get a response
  with urllib.request.urlopen(req) as response:
    headers = response.info()

  sys.stdout.write(json.dumps({"authorization": headers["authorization"]}))
  sys.exit()

if __name__ == "__main__":
  external_data()