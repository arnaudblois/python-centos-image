#!/bin/bash

docker create -t -i --name test-container ${DOCKERHUB_USERNAME}/centos-stream${CENTOS_VERSION}-python:${PYTHON_VERSION}
docker start test-container
docker exec -i test-container python3 < src/test_image.py
