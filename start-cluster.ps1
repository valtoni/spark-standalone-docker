function Capture-Host-IPV4() {
    return (
        Get-NetIPConfiguration |
        Where-Object {
            $_.IPv4DefaultGateway -ne $null -and
            $_.NetAdapter.Status -ne "Disconnected"
        }
    ).IPv4Address.IPAddress
}

Function Create-Master($SPARK_IMAGE, $MASTER_HOST, $MASTER_PORT, $MASTER_WEBUI_PORT) {
    $MASTER_BIND="0.0.0.0"
    $MASTER_CONTAINER_NAME="spark-master"
    Write-Host ("Creating master at {0}:{1} (webui: {0}:{2})..." -f $MASTER_HOST,$MASTER_PORT.ToString(),$MASTER_WEBUI_PORT.ToString())
    docker stop $MASTER_CONTAINER_NAME
    docker rm $MASTER_CONTAINER_NAME
    docker run -d -p ${MASTER_PORT}:${MASTER_PORT} -p ${MASTER_WEBUI_PORT}:${MASTER_WEBUI_PORT} --name $MASTER_CONTAINER_NAME -it ${SPARK_IMAGE} /usr/local/spark/bin/spark-class org.apache.spark.deploy.master.Master --host $MASTER_BIND --port $MASTER_PORT --webui-port $MASTER_WEBUI_PORT
    docker exec -it $MASTER_CONTAINER_NAME /bin/bash -c "ssh-keygen -t rsa -P '' -f /root/.ssh/id_rsa"
    $public_key=docker exec -it $MASTER_CONTAINER_NAME /bin/bash -c "cat ~/.ssh/id_rsa.pub"
    return $public_key
}


function Create-Worker {
    [CmdletBinding()]
    param (
        [string]$SPARK_IMAGE,
        [string]$public_key,
        [string]$WEBUI_PORT,
        [string]$BIND_PORT,
        [string]$MEMORY,
        [string]$CORES,
        [string]$NAME,
        [string]$MASTER_HOST,
        [string]$MASTER_PORT
    )
    docker stop $NAME
    docker rm $NAME
    docker run -d -p ${BIND_PORT}:${BIND_PORT} -p ${WEBUI_PORT}:${WEBUI_PORT} --name $NAME -it ${SPARK_IMAGE} /usr/local/spark/sbin/custom-run-worker.sh ""$public_key"" $CORES $BIND_PORT $MEMORY $WEBUI_PORT spark://${MASTER_HOST}:${MASTER_PORT}
}

function Create-Workers($SPARK_IMAGE, $MASTER_HOST, $MASTER_PORT, $WORKERS_CORES, $WORKERS_MEMORY, $public_key, $workers) {
    # Reference for ports: https://spark.apache.org/docs/latest/security.html#configuring-ports-for-network-security
    # Generic configuration of workers
    #$WORKERS_CORES=2
    #$WORKERS_MEMORY="2G"
    $BASE_WEBUI_PORT=8081
    $BASE_BIND_PORT=10000
    for ($worker=1; $worker -le $workers; $worker++) {
        $WORKER_WEBUI_PORT=$BASE_WEBUI_PORT+$worker
        $WORKER_BIND_PORT=$BASE_BIND_PORT+$worker
        $WORKER_MEMORY=$WORKERS_MEMORY
        $WORKER_CORES=$WORKERS_CORES
        $WORKER_NAME="spark-worker-${worker}"
        Write-Host "Creating worker ${WORKER_NAME}..."
        Create-Worker $SPARK_IMAGE "$public_key" $WORKER_WEBUI_PORT $WORKER_BIND_PORT $WORKER_MEMORY $WORKER_CORES $WORKER_NAME $MASTER_HOST $MASTER_PORT
    }
}

# Worker 1 (Yeah!)
#$WORKER1_WEBUI_PORT=8082
#$WORKER1_BIND_PORT=10001
#$WORKER1_MEMORY=$WORKERS_MEMORY
#$WORKER1_CORES=$WORKERS_CORES
#$WORKER1_NAME="spark-worker-1"

#docker stop $WORKER1_NAME
#docker rm $WORKER1_NAME
#docker run -d -p ${WORKER1_BIND_PORT}:${WORKER1_BIND_PORT} -p ${WORKER1_WEBUI_PORT}:${WORKER1_WEBUI_PORT} --name $WORKER1_NAME -it ${SPARK_IMAGE} /usr/local/spark/sbin/custom-run-worker.sh $public_key $WORKER1_CORES $WORKER1_BIND_PORT $WORKER1_MEMORY $WORKER1_WEBUI_PORT spark://${MASTER_HOST}:${MASTER_PORT}

#Create-Worker $SPARK_IMAGE $public_key $WORKER1_WEBUI_PORT $WORKER1_BIND_PORT $WORKER1_MEMORY $WORKER1_CORES $WORKER1_NAME $MASTER_HOST $MASTER_PORT

$SPARK_IMAGE="spark:3.3.0"
$MASTER_HOST=Capture-Host-IPV4
$MASTER_PORT=7007
$public_key=Create-Master $SPARK_IMAGE $MASTER_HOST $MASTER_PORT 8080
Create-Workers $SPARK_IMAGE $MASTER_HOST $MASTER_PORT 2 "2G" $public_key 5
