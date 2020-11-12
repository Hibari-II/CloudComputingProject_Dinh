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

# Regions Run the load generator
docker run -d \
  --restart=always \
  -p 8080:8080 \
  janoszen/http-load-generator:1.0.1

# Run the node exporter
docker run -d \
 --restart=always \
 --net="host" \
 --pid="host" \
 -v "/:/host:ro,rslave" \
 quay.io/prometheus/node-exporter \
 --path.rootfs=/host

# endregion
