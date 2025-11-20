#!/bin/bash
VERSION=$(cat ./VERSION | tr -d '\n')

IMAGE_NAME="slinred/strato-acme"

TARGET_PLATFORMS=${TARGET_PLATFORMS:-"linux/arm64 linux/amd64"}

for TARGET_PLATFORM in $TARGET_PLATFORMS; do
    echo "Building version: $VERSION for target platform $TARGET_PLATFORM"
    docker buildx build --no-cache -f ./docker/Dockerfile -t $IMAGE_NAME:${VERSION} -t ${IMAGE_NAME}:latest --platform $TARGET_PLATFORM $* .
    if [ $? -ne 0 ]; then
        echo "Failed to build image!"
        exit 1
    fi
done
