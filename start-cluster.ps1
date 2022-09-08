$SPARK_IMAGE="spark:3.3.0"

# Capture Windows IPV4 address of localhost
$MASTER_HOST_WINDOWS=(
    Get-NetIPConfiguration |
    Where-Object {
        $_.IPv4DefaultGateway -ne $null -and
        $_.NetAdapter.Status -ne "Disconnected"
    }
)
$MASTER_HOST=$MASTER_HOST_WINDOWS.IPv4Address.IPAddress
$MASTER_BIND="0.0.0.0"
$MASTER_PORT=7007
$MASTER_WEBUI_PORT=8080
$MASTER_CONTAINER_NAME="spark-master"

# Run master spark
docker stop spark-master
docker rm spark-master
docker run -d -p ${MASTER_PORT}:${MASTER_PORT} -p ${MASTER_WEBUI_PORT}:${MASTER_WEBUI_PORT} --name $MASTER_CONTAINER_NAME -it ${SPARK_IMAGE} /usr/local/spark/bin/spark-class org.apache.spark.deploy.master.Master --host $MASTER_BIND --port $MASTER_PORT --webui-port $MASTER_WEBUI_PORT
docker exec -it spark-master /bin/bash -c "ssh-keygen -t rsa -P '' -f /root/.ssh/id_rsa"
$public_key=docker exec -it spark-master /bin/bash -c "cat ~/.ssh/id_rsa.pub"
Write-Host $public_key

# Reference for ports: https://spark.apache.org/docs/latest/security.html#configuring-ports-for-network-security

# Generic configuration of workers
$WORKERS_CORES=2
$WORKERS_MEMORY="2G"

# Worker 1 (Yeah!)
$WORKER1_WEBUI_PORT=8082
$WORKER1_BIND_PORT="10001"
$WORKER1_MEMORY=$WORKERS_MEMORY
$WORKER1_CORES=$WORKERS_CORES
$WORKER1_NAME="spark-worker-1"
docker stop $WORKER1_NAME
docker rm $WORKER1_NAME
docker run -d -p ${WORKER1_BIND_PORT}:${WORKER1_BIND_PORT} -p ${WORKER1_WEBUI_PORT}:${WORKER1_WEBUI_PORT} --name $WORKER1_NAME -it ${SPARK_IMAGE} /usr/local/spark/sbin/custom-run-worker.sh $public_key $WORKER1_CORES $WORKER1_BIND_PORT $WORKER1_MEMORY $WORKER1_WEBUI_PORT spark://${MASTER_HOST}:${MASTER_PORT}