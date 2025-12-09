#!/bin/bash
set -e;

# Function to drop the index in OpenSearch
function opensearch_schema_drop() { compose_run 'schema' node scripts/drop_index "$@" || true; }

# Function to create the index in OpenSearch
function opensearch_schema_create() { compose_run 'schema' ./bin/create_index; }

# Function to start OpenSearch
function opensearch_start(){
  mkdir -p $DATA_DIR/opensearch
  # attempt to set proper permissions if running as root
  chown -R $DOCKER_USER $DATA_DIR/opensearch 2>/dev/null || true
  chmod -R 755 $DATA_DIR/opensearch 2>/dev/null || true
  compose_exec up -d opensearch
}

# Function to stop OpenSearch
function opensearch_stop(){ compose_exec kill opensearch; }

# Register commands
register 'opensearch' 'drop' 'delete OpenSearch index & all data' opensearch_schema_drop
register 'opensearch' 'create' 'create OpenSearch index with pelias mapping' opensearch_schema_create
register 'opensearch' 'start' 'start OpenSearch server' opensearch_start
register 'opensearch' 'stop' 'stop OpenSearch server' opensearch_stop

# Function to get OpenSearch cluster health
function opensearch_status(){
  curl \
    --output /dev/null \
    --silent \
    --write-out "%{http_code}" \
    "http://${OPENSEARCH_HOST:-localhost:9200}/_cluster/health?wait_for_status=yellow&timeout=1s" \
      || true;
}

# Function to get OpenSearch status with trailing newline
function opensearch_status_newline(){ echo $(opensearch_status); }
register 'opensearch' 'status' 'HTTP status code of the OpenSearch service' opensearch_status_newline

# Function to wait for OpenSearch service to come up
function opensearch_wait(){
  echo 'waiting for OpenSearch service to come up';
  retry_count=30

  i=1
  while [[ "$i" -le "$retry_count" ]]; do
    if [[ $(opensearch_status) -eq 200 ]]; then
      echo "OpenSearch up!"
      exit 0
    elif [[ $(opensearch_status) -eq 408 ]]; then
      # 408 indicates the server is up but not yet yellow status
      printf ":"
    else
      printf "."
    fi
    sleep 1
    i=$(($i + 1))
  done

  echo -e "\n"
  echo "OpenSearch did not come up, check configuration"
  exit 1
}

register 'opensearch' 'wait' 'wait for OpenSearch to start up' opensearch_wait

# Function to display OpenSearch version and build info
function opensearch_info(){ curl -s "http://${OPENSEARCH_HOST:-localhost:9200}/"; }
register 'opensearch' 'info' 'display OpenSearch version and build info' opensearch_info

# Function to display OpenSearch stats
function opensearch_stats(){
  curl -s "http://${OPENSEARCH_HOST:-localhost:9200}/${OPENSEARCH_INDEX:-pelias}/_search?request_cache=true&timeout=10s&pretty=true" \
    -H 'Content-Type: application/json' \
    -d '{
          "aggs": {
            "sources": {
              "terms": {
                "field": "source",
                "size": 100
              },
              "aggs": {
                "layers": {
                  "terms": {
                    "field": "layer",
                    "size": 100
                  }
                }
              }
            }
          },
          "size": 0
        }';
}
register 'opensearch' 'stats' 'display a summary of doc counts per source/layer' opensearch_stats
