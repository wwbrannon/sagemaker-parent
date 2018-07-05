#!/bin/bash

##
## The name of our algorithm
##
algorithm_name="$1"
if [[ -z "$algorithm_name" ]];
    echo "Must provide algorithm name"
fi

##
## Set variables
##
account=$(aws sts get-caller-identity --query Account --output text)

region=$(aws configure get region)
region=${region:-us-east-1}

fullname="${account}.dkr.ecr.${region}.amazonaws.com/${algorithm_name}:latest"

##
## Ensure the repo exists
##
aws ecr describe-repositories --repository-names "${algorithm_name}" > /dev/null 2>&1

if [ $? -ne 0 ]
then
    aws ecr create-repository --repository-name "${algorithm_name}" > /dev/null
fi

##
## Build the docker image locally and push
## 
cd container
chmod +x application/train
chmod +x application/serve

$(aws ecr get-login --region "${region}" --no-include-email)

docker build  -t "${algorithm_name}" .
docker tag "${algorithm_name}" "${fullname}"

docker push "${fullname}"

