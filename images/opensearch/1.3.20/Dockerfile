# Use the official OpenSearch base image
FROM opensearchproject/opensearch:1.3.20

# Install the ICU analysis plugin
RUN opensearch-plugin install analysis-icu

# Copy custom opensearch.yml to the container
COPY opensearch.yml /usr/share/opensearch/config/opensearch.yml

# Expose OpenSearch ports (default 9200 and 9300 for monitoring and transport)
EXPOSE 9200 9300

# Run OpenSearch directly (without using the entrypoint script)
CMD ["/usr/share/opensearch/bin/opensearch"]
