from os import environ
import exoscale
import json
import time

"""
 Snake, do you see C#?
 You have to gather intel about Metal Gear Exoscale...
 Snake, do you hear me? Snake? Snakeeee? Sneeeeeeeeeeeek!!!!!
"""
exoApiKey = environ.get("EXOSCALE_KEY")
exoApiSecret = environ.get("EXOSCALE_SECRET")
exoZone = environ.get("EXOSCALE_ZONE")
exoInstancePoolId = environ.get("EXOSCALE_INSTANCEPOOL_ID")
exoTargetPort = environ.get("TARGET_PORT")

# Instance for the Exoscale API
exo = exoscale.Exoscale(api_key=exoApiKey, api_secret=exoApiSecret)
exoZoneId = exo.compute.get_zone(exoZone) # Getting the Zone ID for getting the list of instances later

while (True):
    # Init empty list for adding instance ip address utilized by prometheus
    ipData = [{
        "targets": []
    }]
    for instance in exo.compute.list_instances(exoZoneId):
        print("{name} {zone} {ip}".format(
            name=instance.name,
            zone=instance.zone.name,
            ip=instance.ipv4_address,
        ))
        if (instance.instance_pool != None):
            if (instance.instance_pool.id == exoInstancePoolId):
                ipData[0]["targets"].append(
                    "{ip}:{port}".format(ip=instance.ipv4_address, port=exoTargetPort)
                )

    with open("srv/service-discovery/config.json", "w+") as file:
        json.dump(ipData, file)

    time.sleep(10)
