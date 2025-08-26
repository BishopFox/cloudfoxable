#!/bin/bash

build_folder=$1
aws_ecr_repository_url_with_tag=$2
REGION=$3

id=$(aws sts get-caller-identity --query Account --output text)

#aws --region $REGION ecr get-login-password | docker login --username AWS --password-stdin $id.dkr.ecr.$REGION.amazonaws.com

$(aws --region $REGION ecr get-login-password | docker login --username AWS --password-stdin $id.dkr.ecr.$REGION.amazonaws.com) #|| { echo 'ERROR: aws ecr login failed' ; exit 1; }

# Check that docker is installed and running
which docker > /dev/null && docker ps > /dev/null || { echo 'ERROR: docker is not running' ; exit 1; }

# Build image
docker build --no-cache -t $aws_ecr_repository_url_with_tag $build_folder

# Push image
docker push $aws_ecr_repository_url_with_tag