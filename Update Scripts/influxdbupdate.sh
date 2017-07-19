#!/bin/bash
# Define a timestamp function
timestamp() {
  date +"%Y-%m-%d_%H-%M-%S"
}
timestamp
echo -ne "\e[36mPulling latest from InfluxDB\e[0m"
docker pull influxdb >/dev/null 2>>influxdb_update.log
echo -e "\r\033[K\e[36mPulling latest from InfluxDB ----- Complete\e[0m"

echo -ne "\e[36mStopping InfluxDB\e[0m"
docker stop influxdb >/dev/null 2>>influxdb_update.log
echo -e "\r\033[K\e[36mStopping InfluxDB ----- Complete\e[0m"

echo -ne "\e[36mBacking up old InfluxDB container to grafana_$(timestamp)\e[0m"
docker rename influxdb influxdb_$(timestamp) >/dev/null 2>>influxdb_update.log
echo -e "\r\033[K\e[36mBacking up old InfluxDB container to influxdb_$(timestamp) ----- Complete\e[0m"

echo -ne "\e[36mCreating InfluxDB docker container - This make take awhile!\e[0m"
docker create \
--name influxdb \
--restart always \
-e PUID=1000 -e PGID=1000 \
-p 8083:8083 -p 8086:8086 \
-v /docker/containers/influxdb/conf/influxdb.conf:/etc/influxdb/influxdb.conf:ro \
-v /docker/containers/influxdb/db:/var/lib/influxdb \
influxdb -config /etc/influxdb/influxdb.conf >/dev/null 2>>influxdb_update.log
echo -e "\r\033[K\e[36mCreating InfluxDB docker container ----- Complete\e[0m"

echo -ne "\e[36mStarting InfluxDB container!\e[0m"
docker start influxdb >/dev/null 2>>influxdb_update.log
echo -e "\r\033[K\e[36mStarting InfluxDB container ----- Complete\e[0m"