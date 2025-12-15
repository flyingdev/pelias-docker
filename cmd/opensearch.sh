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

function opensearch_wait() {
  echo "Waiting for OpenSearch cluster to be ready…"
  retry_count=60

  for i in $(seq 1 $retry_count); do
    status=$(curl -s \
      --max-time 2 \
      http://opensearch:9200/_cluster/health?wait_for_status=yellow \
      | grep -o '"status":"[^"]*"' \
      | cut -d'"' -f4)

    if [[ "$status" == "yellow" || "$status" == "green" ]]; then
      echo "OpenSearch is ready (status=$status)"
      return 0
    fi

    printf "."
    sleep 1
  done

  echo
  echo "OpenSearch did not become ready in time"
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
