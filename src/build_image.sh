#!/bin/bash

# Build the corresponding image
docker build . \
  --file ./src/Dockerfile \
  --tag ${DOCKERHUB_USERNAME}/centos-stream${CENTOS_VERSION}-python:${PYTHON_VERSION} \
  --build-arg PY_VERSION=${PYTHON_VERSION} \
  --build-arg CENTOS_VERSION=${CENTOS_VERSION} \
  --build-arg CREATION_COMMIT_SHA="${GITHUB_SHA}" \
  --build-arg QUICK_BUILD="${QUICK_BUILD}" \
  --build-arg OPENSSL_VERSION="${OPENSSL_VERSION}"
