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
  - job_name: Monitoring Server Node Exporter
    file_sd_configs:
      - files:
          - /service-discovery/config.json
        refresh_interval: 10s
""" >> /srv/prometheus.yml

# Region Providing Data Source, Notification Channel & Dashboards Config File for Grafana
mkdir -p etc/grafana/provisioning/{datasources,notifiers,dashboards}
mkdir -p etc/grafana/dashboards

echo """
${grafana_prometheus_datasource}
""" >> /etc/grafana/provisioning/datasources/prometheus_datascource.yaml

echo """
${grafana_upscale_notifier}
""" >> /etc/grafana/provisioning/notifiers/upscale.yaml

echo """
${grafana_downscale_notifier}
""" >> /etc/grafana/provisioning/notifiers/downscale.yaml

echo """
${grafana_cpu_dashboard}
""" >> /etc/grafana/provisioning/dashboards/cpu_dashboard.yaml

echo '''
${grafana_cpu_panels}
''' >> etc/grafana/dashboards/cpu_panels.json

mkdir /srv/service-discovery
# Region Run Prometheus
docker run \
    -d \
    --name prometheus \
    -p 9090:9090 \
    -v /srv/service-discovery/:/service-discovery/ \
    -v /srv/prometheus.yml:/etc/prometheus/prometheus.yml \
    prom/prometheus

# Region Run Autoscaler.py
docker run \
    -d \
    --name autoscaler \
    -p ${listen_port}:5000 \
    -e EXOSCALE_KEY=${exoscale_key} \
    -e EXOSCALE_SECRET=${exoscale_secret} \
    -e EXOSCALE_ZONE=${exoscale_zone} \
    -e EXOSCALE_ZONE_ID=${exoscale_zone_id} \
    -e EXOSCALE_INSTANCEPOOL_ID=${exoscale_instancepool_id} \
    -e LISTEN_PORT=${listen_port} \
    fhhoabinhdinh/py_autoscaler

# Region Run Grafana
docker run -d \
    -p 3000:3000 \
    --name grafana \
    --link prometheus \
    --link autoscaler \
    -v /etc/grafana/provisioning/datasources:/etc/grafana/provisioning/datasources \
    -v /etc/grafana/provisioning/notifiers:/etc/grafana/provisioning/notifiers \
    -v /etc/grafana/provisioning/dashboards:/etc/grafana/provisioning/dashboards \
    -v /etc/grafana/dashboards:/etc/grafana/dashboards \
    grafana/grafana

# Region Run Service Discovery
docker run \
    -d \
    --name service_discovery \
    -v /srv/service-discovery:/srv/service-discovery \
    -e EXOSCALE_KEY=${exoscale_key} \
    -e EXOSCALE_SECRET=${exoscale_secret} \
    -e EXOSCALE_ZONE=${exoscale_zone} \
    -e EXOSCALE_ZONE_ID=${exoscale_zone_id} \
    -e EXOSCALE_INSTANCEPOOL_ID=${exoscale_instancepool_id} \
    -e TARGET_PORT=${target_port} \
    fhhoabinhdinh/py_service_discovery