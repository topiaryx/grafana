#!/bin/bash
# Define a timestamp function
timestamp() {
  date +"%Y-%m-%d_%H-%M-%S"
}
timestamp
echo "Pulling Latest from grafana/grafana"
docker pull grafana/grafana
echo "Stopping grafana Container"
docker stop grafana
echo "Backing up old grafana Container to grafana_$(timestamp)"
docker rename grafana grafana_$(timestamp)
echo "Creating and starting new grafana Server"
docker create \
--name=grafana \
-p 3000:3000 \
--volumes-from grafana-storage \
-e "GF_SECURITY_ADMIN_PASSWORD=hunter2" \
grafana/grafana
docker start grafana