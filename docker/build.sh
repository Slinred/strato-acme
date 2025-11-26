#!/bin/bash

IMAGE_NAME="slinred/strato-acme"
TARGET_PLATFORMS=${TARGET_PLATFORMS:-"linux/arm64 linux/amd64"}

RELEASE_BUILD=${RELEASE_BUILD:-"false"}

if [ -n "$1" ]; then
    echo "Using version from CLI: $1"
    VERSION=$1
    shift
else
    VERSION=$(cat ./VERSION | tr -d '\n')
fi

if [ "$RELEASE_BUILD" = "true" ]; then
    echo "This is a release build."
    BUILD_TAGS=(-t $IMAGE_NAME:${VERSION} -t ${IMAGE_NAME}:latest)
else
    echo "This is NOT a release build."
    BUILD_TAGS=(-t $IMAGE_NAME:${VERSION})
fi

for TARGET_PLATFORM in $TARGET_PLATFORMS; do
    echo "Building version: $VERSION for target platform $TARGET_PLATFORM"
    set -x
    docker buildx build --no-cache -f ./docker/Dockerfile "${BUILD_TAGS[@]}" --platform $TARGET_PLATFORM $* .
    build_result=$?
    set +x
    if [ $build_result -ne 0 ]; then
        echo "Failed to build image!"
        exit 1
    fi
done
