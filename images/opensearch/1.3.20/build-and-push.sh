#!/bin/bash
set -e

IMAGE_NAME="flyingdev/opensearch"
VERSION="1.3.20"
REGISTRY="${REGISTRY:-docker.io}"  # Default to Docker Hub, can override with REGISTRY=ghcr.io

# Build the image
echo "Building ${IMAGE_NAME}:${VERSION}..."
docker build -t ${REGISTRY}/${IMAGE_NAME}:${VERSION} .

# Tag as latest
docker tag ${REGISTRY}/${IMAGE_NAME}:${VERSION} ${REGISTRY}/${IMAGE_NAME}:latest

# Push both tags
echo "Pushing ${REGISTRY}/${IMAGE_NAME}:${VERSION}..."
docker push ${REGISTRY}/${IMAGE_NAME}:${VERSION}

echo "Pushing ${REGISTRY}/${IMAGE_NAME}:latest..."
docker push ${REGISTRY}/${IMAGE_NAME}:latest

echo "Done!"