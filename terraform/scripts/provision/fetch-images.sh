#!/bin/bash

set -euo pipefail

IMAGES_REGION=us-east-1
IMAGES=(quorum constellation quorum-aws)

eval `sudo aws ecr get-login --region="${IMAGES_REGION}" | sed 's/^docker/sudo docker/'` >/dev/null

echo "fetching docker images"

for image in ${IMAGES[@]}
do
  echo " fetching $image"
  repo=$(sudo aws ecr describe-repositories --region="${IMAGES_REGION}" --repository-names "${image}" | jq -r '.repositories[0].repositoryUri')
  sudo docker pull "${repo}:latest" >/dev/null
  sudo docker tag "${repo}:latest" "${image}:latest"
done

echo "fetching complete"
