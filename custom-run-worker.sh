#!/bin/bash

public_key=$1
CORES=$2
#BIND_HOST="0.0.0.0"
BIND_HOST=$(hostname -I)
# It's a random *fixed* port, HUH? It must be exported to docker
BIND_PORT=$3
MEMORY=$4
WEBUI_PORT=$5 
MASTER=$6

mkdir -p ~/.ssh
echo $1 > ~/.ssh/authorized_keys
#/usr/local/spark/bin/spark-class org.apache.spark.deploy.worker.Worker -c 2 -h 172.17.0.3 -p 10000 -m 2G --webui-port 8081 spark://192.168.100.120:7007
/usr/local/spark/bin/spark-class org.apache.spark.deploy.worker.Worker -c ${CORES} -h ${BIND_HOST} -p ${BIND_PORT} -m ${MEMORY} --webui-port ${WEBUI_PORT} ${MASTER}