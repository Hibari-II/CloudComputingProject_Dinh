from flask import Flask, Response, make_response, jsonify
from os import environ
import signal
import exoscale

# Init of Flask Webapp & Getting Environment Variables.
app = Flask(__name__)
exoApiKey = environ.get('EXOSCALE_KEY')
exoApiSecret = environ.get('EXOSCALE_SECRET')
exoZone = environ.get('EXOSCALE_ZONE')
exoInstancePoolId = environ.get('EXOSCALE_INSTANCEPOOL_ID')
listenPort = environ.get('LISTEN_PORT')

# Set Signalhandler for SIGTERM & SIGINT
signalHandler = lambda sNum, sFrame : exit(0)
signal.signal(signal.SIGTERM, signalHandler)
signal.signal(signal.SIGINT, signalHandler)

# Home Route for Testing Purposes
@app.route('/', methods=["GET","POST"])
def home():
    return "Welcome"

# Via Webhook Scaling Up the Instance Pool
@app.route('/up', methods=["POST"])
def up():
    response = scale_instance_pool(1)
    return response

# Via Webhook Scaling Down the Instance Pool
@app.route('/down', methods=["POST"])
def down():
    response = scale_instance_pool(-1)
    return response

def scale_instance_pool(num: int):
    response = ""
    try:
        exo = exoscale.Exoscale(api_key=exoApiKey, api_secret=exoApiSecret)
        exoZoneId = exo.compute.get_zone(exoZone)
        instancePool = exo.compute.get_instance_pool(zone=exoZoneId, id=exoInstancePoolId)
        instancePool.scale(instancePool.size + num)

        response = make_response("Succeeded", 200)
    except exoscale.api.APIException as e:
        print(e)
        response = make_response("Failed. Exeeding VM Limit", 503)
    finally:
        return response

if __name__ == "__main__":
      app.run(host='0.0.0.0', port=listenPort)
