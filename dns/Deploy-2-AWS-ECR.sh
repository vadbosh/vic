#!/bin/bash

# AWS PART
AWS_REGION="us-east-1"
AWS_ID="381142409470"
ECR="${AWS_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
REPONAME_CORE="thoth-sandbox-test-metrics"
NEXT_BUILD_NUM="v7"

# BUILD IMAGE
aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR}/app || exit 1
docker build --tag ${REPONAME_CORE}:latest -f Dockerfile --progress plain --platform linux/amd64 . || exit 1
#docker build --tag ${REPONAME_CORE}:latest -f Dockerfile --no-cache --progress plain --platform linux/amd64 . || exit 1
docker tag ${REPONAME_CORE}:latest ${ECR}/${REPONAME_CORE}:${NEXT_BUILD_NUM} || exit 1
docker push ${ECR}/${REPONAME_CORE}:${NEXT_BUILD_NUM}
