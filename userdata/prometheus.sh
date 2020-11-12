#!/bin/bash

set -e

export DEBIAN_FRONTEND=noninteractive

# region Install Docker
apt-get update
apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

apt-key fingerprint 0EBFCD88
add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io
# endregion

echo """
global:
  scrape_interval: 15s
scrape_configs:
  - job_name: 'prometheus'
    scrape_interval: 5s
    static_configs:
      - targets: ['localhost:9090']
  - job_name: Monitoring Server Node Exporter
    file_sd_configs:
      - files:
          - /service-discovery/config.json
        refresh_interval: 10s
""" >> /srv/prometheus.yml

mkdir /srv/service-discovery

# Region Run Prometheus
docker run \
    -d \
    -p 9090:9090 \
    -v /srv/service-discovery/:/service-discovery/ \
    -v /srv/prometheus.yml:/etc/prometheus/prometheus.yml \
    prom/prometheus
# endregion

# Region Run Service Discovery
docker run \
    -d \
    -v /srv/service-discovery:/srv/service-discovery \
    -e EXOSCALE_KEY=${exoscale_key} \
    -e EXOSCALE_SECRET=${exoscale_secret} \
    -e EXOSCALE_ZONE=${exoscale_zone} \
    -e EXOSCALE_ZONE_ID=${exoscale_zone_id} \
    -e EXOSCALE_INSTANCEPOOL_ID=${exoscale_instancepool_id} \
    -e TARGET_PORT=${target_port} \
    fhhoabinhdinh/py_service_discovery
