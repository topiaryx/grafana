#!/bin/bash
# Define a timestamp function
timestamp() {
  date +"%Y-%m-%d_%H-%M-%S"
}
timestamp
echo "Pulling Latest from influxdb"
docker pull influxdb
echo "Stopping influxdb Container"
docker stop influxdb
echo "Backing up old influxdb Container to influxdb_$(timestamp)"
docker rename influxdb influxdb_$(timestamp)
echo "Creating and starting new influxdb Server"
docker create \
--name influxdb \
-e PUID=1000 -e PGID=1000 \
-p 8083:8083 -p 8086:8086 \
-v /docker/containers/influxdb/conf/influxdb.conf:/etc/influxdb/influxdb.conf:ro \
-v /docker/containers/influxdb/db:/var/lib/influxdb \
influxdb -config /etc/influxdb/influxdb.conf