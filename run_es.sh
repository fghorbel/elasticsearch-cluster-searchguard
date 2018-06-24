#!/bin/bash
#set -e

#read -p "Enter cluster size: " cluster_size
#read -p "Enter storage path: " storage
#read -p "Enter node memory (mb): " memory

sysctl -w vm.max_map_count=262144

cluster_size=3
storage=/data/elasticsearch
memory=8

heap=$((memory/2))
image="es-t"
network="es-net"
cluster="cluster-t"
#img="khezen/elasticsearch:latest"
img="elasticsearch-searchguard:test"

# build image
if [ ! "$(docker images -q  $image)" ];then
    docker build -t $img .
fi

# create bridge network
if [ ! "$(docker network ls --filter name=$network -q)" ];then
    docker network create $network
fi

# concat all nodes addresses
hosts=""
for ((i=0; i<$cluster_size; i++)); do
    hosts+="$image$i"
        docker rm -f $image$i
	[ $i != $(($cluster_size-1)) ] && hosts+=","
done
rm -rf /etc/elasticsearch
mkdir -p /etc/elasticsearch 

# starting nodes
for ((i=0; i<$cluster_size; i++)); do
    echo "Starting node $i"
    mkdir -p /etc/elasticsearch/$image$i &&  touch /etc/elasticsearch/$image$i/jvm.options
   
    docker run -d -p 920$i:9200 \
        --name "$image$i" \
        --network "$network" \
        -v "$storage/$i":/usr/share/elasticsearch/data \
        -v /etc/elasticsearch/$image$i:/elasticsearch/config \
        -v /etc/elasticsearch/searchguard:/elasticsearch/config/searchguard \
        -e CLUSTER_NAME="elasticsearch-default" \
        -e MINIMUM_MASTER_NODES=2 \
	   -e HOSTS="$hosts"\
	   -e NODE_NAME="NODE-1" \
	   -e NODE_MASTER=true \
	   -e NODE_DATA=true \
	   -e NODE_INGEST=true \
	   -e HTTP_ENABLE=true \
	   -e HTTP_CORS_ENABLE=true \
	   -e HTTP_CORS_ALLOW_ORIGIN=* \
	   -e NETWORK_HOST="0.0.0.0" \
	   -e ELASTIC_PWD="fadhel" \
	   -e KIBANA_PWD="changeme" \
	   -e LOGSTASH_PWD="changeme" \
	   -e BEATS_PWD="changeme" \
	   -e HEAP_SIZE="2g" \
	   -e CA_PWD="changeme" \
	   -e TS_PWD="changeme" \
	   -e KS_PWD="changeme" \
	   -e HTTP_SSL=true \
	   -e LOG_LEVEL=INFO \
        --restart unless-stopped \
         $img 

        sleep 5
done

echo "waiting 15s for cluster to form"
sleep 15

# find host IP
host="$(ifconfig eth0 | sed -En 's/.*inet (addr:)?(([0-9]*\.){3}[0-9]*).*/\2/p')"

# get cluster status
status="$(curl -fsSL "http://${host}:9200/_cat/health?h=status")"
echo "cluster health status is $status"
