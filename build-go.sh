#!/bin/bash

# Versions
GO_VERSION=1.11
ALPINE_VERSION=3.8

# DIRECTORIES
DIRECTORY=${PWD}
OFFICIAL_IMAGES_DIRECTORY=${DIRECTORY}/official-images

# Build Image
IMAGE_NAME=pvormste/docker-go:${GO_VERSION}
cd 18.09
docker build -t ${IMAGE_NAME} --build-arg GO_VERSION=${GO_VERSION} --build-arg ALPINE_VERSION=${ALPINE_VERSION} .

# Test image
if [ ! -d "${OFFICIAL_IMAGES_DIRECTORY}" ]; then
  git clone https://github.com/docker-library/official-images.git ${OFFICIAL_IMAGES_DIRECTORY}
fi

cd ${OFFICIAL_IMAGES_DIRECTORY}
git pull
./test/run.sh ${IMAGE_NAME}
