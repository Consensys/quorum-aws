#!/bin/bash

set -euo pipefail

eval `sudo aws ecr get-login | sed 's/^docker/sudo docker/'` >/dev/null

echo "fetching docker images"

IMAGES=(quorum constellation quorum-aws)

for image in ${IMAGES[@]}
do
  echo " fetching $image"
  repo=$(sudo aws ecr describe-repositories --repository-names "${image}" | jq -r '.repositories[0].repositoryUri')
  sudo docker pull "${repo}:latest" >/dev/null
  sudo docker tag "${repo}:latest" "${image}:latest"
done

echo "fetching complete"
