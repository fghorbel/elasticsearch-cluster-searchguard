#!/bin/bash

http="http"
if [ $HTTP_SSL ]; then
  http="https"
fi

curl -XPUT -k -H 'Content-Type: application/json' -u "elastic:$ELASTIC_PWD" "$http://localhost:9200/_all/_settings?preserve_existing=true" -d '{
    "index.auto_expand_replicas" : "0-all"
}'

