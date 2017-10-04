#!/bin/bash

set -euo pipefail

sudo docker ps | grep geth | awk '{print $1}' | xargs sudo docker inspect -f '' | jq -r '.[0].LogPath' | xargs sudo tail -f | jq -r '.log | rtrimstr("\n")'
