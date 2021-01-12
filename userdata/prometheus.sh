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

mkdir /srv/service-discovery

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

# Region Run Prometheus
docker run \
    -d \
    --name prometheus \
    -p 9090:9090 \
    -v /srv/service-discovery/:/service-discovery/ \
    -v /srv/prometheus.yml:/etc/prometheus/prometheus.yml \
    prom/prometheus
# endregion

# Region Providing Data Source, Notification Channel & Dashboards Config File for Grafana
mkdir -p etc/grafana/provisioning/{datasources,notifiers,dashboards}
mkdir -p etc/grafana/dashboards

echo """
apiVersion: 1
datasources:
- name: Prometheus
  type: prometheus
  access: proxy
  orgId: 1
  url: http://prometheus:9090
  version: 1
  editable: false
""" >> /etc/grafana/provisioning/datasources/prometheus_datascource.yaml

echo """
notifiers:
  - name: Scale up
    type: webhook
    uid: scale-up
    org_id: 1
    is_default: false
    send_reminder: true
    disable_resolve_message: true
    frequency: '2m'
    settings:
      autoResolve: true
      httpMethod: 'POST'
      severity: 'critical'
      uploadImage: false
      url: 'http://autoscaler:8090/up'
""" >> /etc/grafana/provisioning/notifiers/upscale.yaml

echo """
notifiers:
  - name: Scale Down
    type: webhook
    uid: scale-down
    org_id: 1
    is_default: false
    send_reminder: true
    disable_resolve_message: true
    frequency: '2m'
    settings:
      autoResolve: true
      httpMethod: 'POST'
      severity: 'critical'
      uploadImage: false
      url: 'http://autoscaler:8090/down'
""" >> /etc/grafana/provisioning/notifiers/downscale.yaml

echo """
apiVersion: 1

providers:
- name: 'AVG CPU Performance'
  orgId: 1
  folder: ''
  type: file
  updateIntervalSeconds: 10
  options:
    path: /etc/grafana/dashboards
""" >> /etc/grafana/provisioning/dashboards/cpu_dashboard.yaml

echo '''
{
  "annotations": {
    "list": [
      {
        "builtIn": 1,
        "datasource": "-- Grafana --",
        "enable": true,
        "hide": true,
        "iconColor": "rgba(0, 211, 255, 1)",
        "name": "Annotations & Alerts",
        "type": "dashboard"
      }
    ]
  },
  "editable": true,
  "gnetId": null,
  "graphTooltip": 0,
  "links": [],
  "panels": [
    {
      "alert": {
        "alertRuleTags": {},
        "conditions": [
          {
            "evaluator": {
              "params": [
                0.2
              ],
              "type": "lt"
            },
            "operator": {
              "type": "and"
            },
            "query": {
              "params": [
                "A",
                "1m",
                "now"
              ]
            },
            "reducer": {
              "params": [],
              "type": "avg"
            },
            "type": "query"
          }
        ],
        "executionErrorState": "alerting",
        "for": "1m",
        "frequency": "10s",
        "handler": 1,
        "name": "Scaling Down Alert",
        "noDataState": "no_data",
        "notifications": [
          {
            "uid": "scale-down"
          }
        ]
      },
      "aliasColors": {},
      "bars": false,
      "dashLength": 10,
      "dashes": false,
      "datasource": "Prometheus",
      "fieldConfig": {
        "defaults": {
          "custom": {}
        },
        "overrides": []
      },
      "fill": 1,
      "fillGradient": 0,
      "gridPos": {
        "h": 8,
        "w": 12,
        "x": 0,
        "y": 0
      },
      "hiddenSeries": false,
      "id": 4,
      "legend": {
        "avg": false,
        "current": false,
        "max": false,
        "min": false,
        "show": true,
        "total": false,
        "values": false
      },
      "lines": true,
      "linewidth": 1,
      "nullPointMode": "null",
      "options": {
        "alertThreshold": true
      },
      "percentage": false,
      "pluginVersion": "7.3.6",
      "pointradius": 2,
      "points": false,
      "renderer": "flot",
      "seriesOverrides": [],
      "spaceLength": 10,
      "stack": false,
      "steppedLine": false,
      "targets": [
        {
          "expr": "avg(\r\n    sum by (instance) (rate(node_cpu_seconds_total{mode!=\"idle\"}[1m])) /\r\n    sum by (instance) (rate(node_cpu_seconds_total[1m]))\r\n)",
          "interval": "",
          "legendFormat": "",
          "queryType": "randomWalk",
          "refId": "A"
        }
      ],
      "thresholds": [
        {
          "colorMode": "critical",
          "fill": true,
          "line": true,
          "op": "lt",
          "value": 0.2
        }
      ],
      "timeFrom": null,
      "timeRegions": [],
      "timeShift": null,
      "title": "Avg CPU (Scaling Down Alert)",
      "tooltip": {
        "shared": true,
        "sort": 0,
        "value_type": "individual"
      },
      "type": "graph",
      "xaxis": {
        "buckets": null,
        "mode": "time",
        "name": null,
        "show": true,
        "values": []
      },
      "yaxes": [
        {
          "format": "short",
          "label": null,
          "logBase": 1,
          "max": null,
          "min": null,
          "show": true
        },
        {
          "format": "short",
          "label": null,
          "logBase": 1,
          "max": null,
          "min": null,
          "show": true
        }
      ],
      "yaxis": {
        "align": false,
        "alignLevel": null
      }
    },
    {
      "alert": {
        "alertRuleTags": {},
        "conditions": [
          {
            "evaluator": {
              "params": [
                0.6
              ],
              "type": "gt"
            },
            "operator": {
              "type": "and"
            },
            "query": {
              "params": [
                "A",
                "1m",
                "now"
              ]
            },
            "reducer": {
              "params": [],
              "type": "avg"
            },
            "type": "query"
          }
        ],
        "executionErrorState": "alerting",
        "for": "1m",
        "frequency": "10s",
        "handler": 1,
        "name": "Scaling Up Alert",
        "noDataState": "no_data",
        "notifications": [
          {
            "uid": "scale-up"
          }
        ]
      },
      "aliasColors": {},
      "bars": false,
      "dashLength": 10,
      "dashes": false,
      "datasource": "Prometheus",
      "fieldConfig": {
        "defaults": {
          "custom": {}
        },
        "overrides": []
      },
      "fill": 1,
      "fillGradient": 0,
      "gridPos": {
        "h": 9,
        "w": 12,
        "x": 0,
        "y": 8
      },
      "hiddenSeries": false,
      "id": 2,
      "legend": {
        "avg": false,
        "current": false,
        "max": false,
        "min": false,
        "show": true,
        "total": false,
        "values": false
      },
      "lines": true,
      "linewidth": 1,
      "nullPointMode": "null",
      "options": {
        "alertThreshold": true
      },
      "percentage": false,
      "pluginVersion": "7.3.6",
      "pointradius": 2,
      "points": false,
      "renderer": "flot",
      "seriesOverrides": [],
      "spaceLength": 10,
      "stack": false,
      "steppedLine": false,
      "targets": [
        {
          "expr": "avg(\r\n    sum by (instance) (rate(node_cpu_seconds_total{mode!=\"idle\"}[1m])) /\r\n    sum by (instance) (rate(node_cpu_seconds_total[1m]))\r\n)",
          "interval": "",
          "legendFormat": "",
          "queryType": "randomWalk",
          "refId": "A"
        }
      ],
      "thresholds": [
        {
          "colorMode": "critical",
          "fill": true,
          "line": true,
          "op": "gt",
          "value": 0.6
        }
      ],
      "timeFrom": null,
      "timeRegions": [],
      "timeShift": null,
      "title": "Avg Cpu (Scaling Up Alert)",
      "tooltip": {
        "shared": true,
        "sort": 0,
        "value_type": "individual"
      },
      "type": "graph",
      "xaxis": {
        "buckets": null,
        "mode": "time",
        "name": null,
        "show": true,
        "values": []
      },
      "yaxes": [
        {
          "format": "short",
          "label": null,
          "logBase": 1,
          "max": null,
          "min": null,
          "show": true
        },
        {
          "format": "short",
          "label": null,
          "logBase": 1,
          "max": null,
          "min": null,
          "show": true
        }
      ],
      "yaxis": {
        "align": false,
        "alignLevel": null
      }
    }
  ],
  "refresh": false,
  "schemaVersion": 26,
  "style": "dark",
  "tags": [],
  "templating": {
    "list": []
  },
  "time": {
    "from": "2021-01-12T17:03:17.512Z",
    "to": "2021-01-12T17:27:08.457Z"
  },
  "timepicker": {},
  "timezone": "",
  "title": "CPU Performance",
  "uid": "KO1r59-Mz",
  "version": 1
}
''' >> etc/grafana/dashboards/avg_cpu.json

# Region Run Autoscaler.py
docker run \
    -d \
    --name autoscaler \
    -p ${listen_port}:${listen_port} \
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
