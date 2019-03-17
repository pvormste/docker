#!/bin/bash

# Versions
GO_VERSION=1.12.1
ALPINE_VERSION=3.9
DOCKER_VERSION=18.09

# DIRECTORIES
DIRECTORY=${PWD}
OFFICIAL_IMAGES_DIRECTORY=${DIRECTORY}/official-images

# Build Image
IMAGE_NAME=pvormste/docker-go
GO_MINOR_VERSION=${GO_VERSION%.*}

cd ${DOCKER_VERSION}
docker build -t ${IMAGE_NAME}:${GO_VERSION} --build-arg GO_VERSION=${GO_VERSION} --build-arg ALPINE_VERSION=${ALPINE_VERSION} .
docker tag ${IMAGE_NAME}:${GO_VERSION} ${IMAGE_NAME}:${GO_MINOR_VERSION}

# Test image
if [ ! -d "${OFFICIAL_IMAGES_DIRECTORY}" ]; then
  git clone https://github.com/docker-library/official-images.git ${OFFICIAL_IMAGES_DIRECTORY}
fi

cd ${OFFICIAL_IMAGES_DIRECTORY}
git pull
./test/run.sh ${IMAGE_NAME}:${GO_VERSION}
./test/run.sh ${IMAGE_NAME}:${GO_MINOR_VERSION}
